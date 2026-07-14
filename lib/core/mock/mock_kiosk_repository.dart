import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/config_service.dart';
import '../grpc/locker_grpc_service.dart';
import '../utilities/logging.dart';
import '../utilities/phone_utils.dart';
import 'models.dart';

/// Stand-in for everything the Android app persisted to SharedPreferences /
/// local files: `DbService` (parcel items, `db.json`) and `LockerService`
/// (locker inventory, `lockerConfig.json`). The drop-off PIN, admin PIN, and
/// SMS template live in `ConfigService`/`config.json` instead — see
/// `core/config/config_service.dart`.
///
/// The locker inventory itself is also sourced from `config.json` now (its
/// `locker_mapping` id/size list — see `ConfigService.lockerMapping`), kept
/// in sync live: this repository listens for `ConfigService` changes and
/// rebuilds `_lockers` whenever an admin edits the mapping in
/// `ConfigurationPage`, exactly like the Android app's
/// `LockerService.updateLockerConfig` regenerating `lockerConfig.json`.
///
/// Every parcel "ticket" (`_items`) is persisted to a local `db.json` next
/// to the app, in the same `{phone, pin, lockerId, creationDate}` shape as
/// the Android app's `db.json` (written by `DbService`) — so a drop-off
/// survives an app restart and can be inspected the same way as on the
/// physical kiosk. Loaded once at startup (see [initialize], called from
/// `main.dart`), then kept in memory and written straight through on every
/// change.
///
/// Each window (Admin/Customer) runs its own Flutter engine/isolate, so
/// this in-memory list isn't automatically shared between them — instead,
/// `initialize()` also starts a filesystem watch on `db.json` (see
/// `_startWatching`), so a parcel added or removed in one window's engine
/// is picked up and reflected in the other's within moments, without
/// needing a restart. `ConfigService` uses the same watch-and-reload
/// pattern for `config.json`.
///
/// This exists so the ported screens have real, working navigation and
/// validation logic (matching each Activity's behavior) whether or not a
/// physical unit is reachable. `ConfigService.lockerBackend` decides which
/// mode is active:
///
/// - `'mock'` (default): everything below is purely in-memory/`db.json`,
///   as described above — no network calls.
/// - `'grpc'`: every method that represents a physical action (unlocking a
///   locker on drop-off, collection, or an admin-override open/clear) also
///   fires a best-effort call to `LockerGrpcService`, which speaks the same
///   `cv_saas.CommsService` gRPC contract the Android app's `GrpcService`/
///   `DbService` use — see `core/grpc/locker_grpc_service.dart`. These
///   calls are fire-and-forget from the caller's perspective (the method
///   signatures below stay synchronous, matching every existing call
///   site), the same way Android's `DbService.addItem` dispatches
///   `openLocker()` on a coroutine without blocking on it.
///
/// Locker *inventory* (ids/sizes) always comes from `config.json`'s
/// `locker_mapping` regardless of backend — hardware has no concept of
/// "small/medium/large," that's assigned by software on both platforms
/// (see `LockerService.initializeLockerFromCv` defaulting every locker to
/// `MEDIUM` on the Android side).
class MockKioskRepository extends ChangeNotifier {
  MockKioskRepository._internal() {
    _syncLockersFromConfig();
    ConfigService().addListener(_syncLockersFromConfig);
  }

  static final MockKioskRepository instance = MockKioskRepository._internal();

  List<Locker> _lockers = const [];
  final List<LockerItem> _items = [];
  final _random = Random();
  bool _initialized = false;
  StreamSubscription<FileSystemEvent>? _watchSubscription;

  /// Flat/global locker id -> which paired-board pair (and local door
  /// number within that pair) it came from. Only populated when
  /// `ConfigService.pairedLockerMode` is true; empty otherwise. Rebuilt
  /// alongside `_lockers` in `_syncLockersFromConfig` — see
  /// `_grpcLockerNumber`, which is the only thing that reads this.
  final Map<int, ({int pairIndex, int localId})> _pairLocationByLockerId = {};

  /// Mirrors `sharedPreferences["isGlobal"]` — switches phone validation
  /// between South-Africa-only and any-country mode.
  bool isGlobal = false;

  /// Mirrors `sharedPreferences["dropoffPinEnabled"]`. The PIN itself, and
  /// the admin PIN and SMS template, now live in `ConfigService`/
  /// `config.json` — see `core/config/config_service.dart`.
  bool dropoffPinEnabled = false;

  File get _dbFile => File('${Directory.current.path}/db.json');

  /// Loads `db.json` (if present) into memory; creates it (empty) if it
  /// doesn't exist yet. Call once at startup, before any page reads or
  /// writes items — see `main.dart`. Safe to call more than once; only the
  /// first call does anything.
  Future<void> initialize() async {
    if (_initialized) return;

    // `_dbFile` resolves relative to `Directory.current.path` — log it once
    // so a silently-swallowed write failure (e.g. this path being outside
    // what the OS lets the app write to) is easy to spot in the console
    // instead of just missing from db.json.
    logger.i('MockKioskRepository: reading/writing ${_dbFile.path}');

    await _loadItemsFromDisk();
    _initialized = true;
    _startWatching();
    logger.i(
        'MockKioskRepository initialized (${_items.length} item(s) loaded from db.json)');

    // Best-effort, fire-and-forget: don't block app startup on a network
    // call to hardware that might not be powered on yet. If it fails, the
    // Configuration page's "Sync Lockers from Hardware" button covers
    // retrying later.
    unawaited(syncLockersFromHardware());
  }

  /// Asks the real unit how many lockers it has (`get_locker_states`) and
  /// reconciles `ConfigService.lockerMapping` to match — mirrors Android's
  /// `LockerService.initializeLockerFromCv`/`getLockersForConfiguration`.
  /// No-op in `'mock'` mode. Returns true if the hardware call itself
  /// succeeded (regardless of whether the mapping actually changed) so
  /// callers (e.g. the Configuration page) can show a clear result.
  Future<bool> syncLockersFromHardware() async {
    if (!ConfigService().isGrpcBackend) return false;
    final count = await LockerGrpcService.instance.getLockerCount();
    if (count == null) return false;
    await ConfigService().reconcileLockerMappingToHardwareCount(count);
    return true;
  }

  /// Watches `db.json` for changes made by *another* window's engine (each
  /// window runs its own Flutter engine/isolate, so a parcel dropped off in
  /// the Customer window otherwise wouldn't show up in the Admin window's
  /// override screen until restart). Reloads and notifies listeners
  /// shortly after any window writes to the file — including this one's
  /// own writes, which is a harmless no-op reload.
  void _startWatching() {
    try {
      _watchSubscription =
          _dbFile.watch().listen((_) => _reloadItemsFromDiskAndNotify());
    } catch (e) {
      logger.w('Could not watch db.json for external changes: $e');
    }
  }

  Future<void> _reloadItemsFromDiskAndNotify() async {
    await _loadItemsFromDisk();
    // A locker mapping change elsewhere may have landed between the last
    // sync and now; re-applying it keeps `_lockers` (and pruning of items
    // in now-nonexistent lockers) consistent with the freshly-reloaded
    // item list.
    _syncLockersFromConfig();
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadItemsFromDisk() async {
    try {
      final file = _dbFile;
      if (!await file.exists()) {
        await _writeItemsToDisk();
        return;
      }
      final raw = jsonDecode(await file.readAsString());
      if (raw is List) {
        final parsed = raw.map(_itemFromJson).whereType<LockerItem>().toList();
        _items
          ..clear()
          ..addAll(parsed);
      }
    } catch (e) {
      logger.w('Failed to load db.json, starting with an empty item list: $e');
    }
  }

  Future<void> _writeItemsToDisk() async {
    try {
      await _dbFile.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_items.map(_itemToJson).toList()),
      );
    } catch (e) {
      logger.w('Failed to write db.json: $e');
    }
  }

  /// Writes the current `_items` list to `db.json`, mirroring
  /// `DbService`'s write-through-on-every-change behavior. Fire-and-forget
  /// from every mutating method below so those methods can stay
  /// synchronous (every page already calls them without `await`).
  void _persistItems() {
    unawaited(_writeItemsToDisk());
  }

  static Map<String, dynamic> _itemToJson(LockerItem item) => {
        'phone': item.phone,
        'pin': item.pin,
        'lockerId': item.lockerId,
        'creationDate': item.creationDate.toIso8601String(),
      };

  static LockerItem? _itemFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final phone = raw['phone'];
    final pin = raw['pin'];
    final lockerId = raw['lockerId'];
    final creationDateRaw = raw['creationDate'];
    if (phone is! String ||
        pin is! String ||
        lockerId is! int ||
        creationDateRaw is! String) {
      return null;
    }
    final creationDate = DateTime.tryParse(creationDateRaw);
    if (creationDate == null) return null;
    return LockerItem(
      phone: phone,
      pin: pin,
      lockerId: lockerId,
      creationDate: creationDate,
    );
  }

  /// Rebuilds `_lockers` from `ConfigService.lockerMapping` (or
  /// `ConfigService.lockerPairs`, in paired mode — see
  /// `ConfigService.pairedLockerMode`) — called once at construction and
  /// again every time an admin saves a new mapping in `ConfigurationPage`.
  /// Any in-flight parcel `Item`s whose locker no longer exists after the
  /// change are dropped, so the app never shows a phantom "occupied"
  /// locker that isn't part of the current mapping.
  void _syncLockersFromConfig() {
    final config = ConfigService();
    _pairLocationByLockerId.clear();

    if (config.pairedLockerMode && config.lockerPairs.isNotEmpty) {
      // Flatten every pair's local doors into the same kind of sequential
      // flat id list `lockerMapping` would produce — this is what lets
      // every existing occupancy method (`getFreeLockers`, `isLockerFree`,
      // `addItem`, etc.) keep working completely unchanged: a "logical
      // locker" is still just one flat id, it just now also has a
      // drop-off-board door and a collection-board door behind it (see
      // `_grpcLockerNumber`). The *drop-off* side's size is used for the
      // flat `Locker.size` since that's the side customers actually pick
      // a size against.
      final lockers = <Locker>[];
      var flatId = 1;
      final pairs = config.lockerPairs;
      for (var pairIndex = 0; pairIndex < pairs.length; pairIndex++) {
        for (final entry in pairs[pairIndex].lockers) {
          lockers.add(Locker(id: flatId, size: _parseSize(entry.dropoffSize)));
          _pairLocationByLockerId[flatId] =
              (pairIndex: pairIndex, localId: entry.localId);
          flatId++;
        }
      }
      _lockers = lockers;
    } else {
      _lockers = config.lockerMapping
          .map((entry) => Locker(id: entry.id, size: _parseSize(entry.size)))
          .toList();
    }

    final validIds = _lockers.map((l) => l.id).toSet();
    _items.removeWhere((item) => !validIds.contains(item.lockerId));

    notifyListeners();
  }

  /// Computes the real gRPC `locker_num` for a flat/logical [lockerId] on
  /// a specific physical door, per `ConfigService.pairedLockerMode`'s
  /// topology: pair 0's drop-off/collection boards are gRPC's global
  /// boards 1/2, pair 1's are boards 3/4, and so on — each pair
  /// contributes exactly two boards, always in `[dropoff, collection]`
  /// order, to the single flat 1..num_lockers numbering the proto uses
  /// (see `protos/service.proto`'s `LockRequest.locker_num` comment: "The
  /// first locker is always 1," global across every slave board, not
  /// reset per board).
  ///
  /// Outside paired mode (or if [lockerId] isn't in the pair lookup for
  /// any reason), this is the identity function — [lockerId] itself is
  /// already the direct gRPC locker number, matching today's behavior.
  int _grpcLockerNumber(int lockerId, {required bool forCollectionSide}) {
    if (!ConfigService().isGrpcBackend) return lockerId;
    if (!ConfigService().pairedLockerMode) return lockerId;

    final location = _pairLocationByLockerId[lockerId];
    if (location == null) {
      // Shouldn't happen (every _lockers entry gets a location when
      // paired mode built it) — fall back to the flat id rather than
      // throwing, since guessing wrong here means unlocking a real door.
      logger.w(
        'MockKioskRepository: no pair location for locker $lockerId in '
        'paired mode — falling back to flat id as the gRPC locker_num.',
      );
      return lockerId;
    }

    final pairs = ConfigService().lockerPairs;
    var boardOffset = 0;
    for (var i = 0; i < location.pairIndex; i++) {
      // Each earlier pair contributes two boards (dropoff + collection),
      // both the same door count within that pair.
      boardOffset += 2 * pairs[i].lockers.length;
    }
    if (forCollectionSide) {
      // Skip past this pair's own drop-off board to land on its
      // collection board.
      boardOffset += pairs[location.pairIndex].lockers.length;
    }
    return boardOffset + location.localId;
  }

  static LockerSize _parseSize(String size) {
    switch (size) {
      case 'small':
        return LockerSize.small;
      case 'large':
        return LockerSize.large;
      case 'medium':
      default:
        return LockerSize.medium;
    }
  }

  // --- Lockers -------------------------------------------------------

  List<Locker> getAllLockers() => List.unmodifiable(_lockers);

  List<Locker> getFreeLockers() {
    final occupied = _items.map((i) => i.lockerId).toSet();
    return _lockers.where((l) => !occupied.contains(l.id)).toList();
  }

  List<Locker> getFreeLockersOfSize(LockerSize size) {
    return getFreeLockers().where((l) => l.size == size).toList();
  }

  bool isLockerFree(int lockerId) {
    return !_items.any((item) => item.lockerId == lockerId);
  }

  /// Picks a random free locker of the given size — mirrors
  /// `DeliverPlaceParcelActivity.getRandomLocker()`.
  Locker? pickRandomFreeLocker(LockerSize size) {
    final free = getFreeLockersOfSize(size);
    if (free.isEmpty) return null;
    return free[_random.nextInt(free.length)];
  }

  // --- Items (parcels) -------------------------------------------------

  List<LockerItem> getAllItems() => List.unmodifiable(_items);

  /// Normalizes [phone] before comparing — defensive, in case a caller
  /// somewhere forgot to normalize first. Safe to do unconditionally since
  /// [normalizeToSouthAfrica] is idempotent (never adds a second "+27").
  List<LockerItem> itemsForPhone(String phone) {
    final normalized = normalizeToSouthAfrica(phone);
    return _items.where((i) => i.phone == normalized).toList();
  }

  LockerItem addItem({required String phone, required int lockerId}) {
    // Same defensive normalization as `itemsForPhone` — every item this
    // repository ever stores has a canonical "+27..." phone, regardless
    // of what the caller passed in.
    final normalizedPhone = normalizeToSouthAfrica(phone);
    // Mirrors DeliverPlaceParcelActivity: if this phone already has a
    // parcel, reuse the same PIN rather than issuing a new one.
    final existing = _items.firstWhereOrNull((i) => i.phone == normalizedPhone);
    final item = LockerItem(
      phone: normalizedPhone,
      pin: existing?.pin ?? _generateRandomPin(),
      lockerId: lockerId,
      creationDate: DateTime.now(),
    );
    _items.add(item);
    _persistItems();
    // Mirrors `DbService.addItem` -> `openLocker(item.lockerId)`: physically
    // unlock the assigned locker so the customer can place their parcel.
    // In paired mode this is always the *drop-off*-side door — the
    // matching collection-side door stays locked until someone actually
    // collects (see `removeItems`), even though both doors now count as
    // occupied for the same logical locker.
    _unlockPhysicalLocker(lockerId);
    notifyListeners();
    return item;
  }

  void removeItems(List<LockerItem> items) {
    _items.removeWhere((i) => items.contains(i));
    _persistItems();
    // Mirrors `DbService.removeItem` -> `openLocker(item.lockerId)`: open
    // every collected item's locker so the customer can take their parcel.
    // In paired mode this opens the *collection*-side door — the parcel
    // was physically placed behind the drop-off board, but the paired
    // collection board covers the same cavity from the other side (see
    // the class doc comment on `ConfigService.lockerPairs`).
    for (final item in items) {
      _unlockPhysicalLocker(item.lockerId, forCollectionSide: true);
    }
    notifyListeners();
  }

  /// Mirrors `HelpActivity`'s "resend PIN via SMS" — succeeds only if the
  /// phone number has at least one parcel waiting.
  bool resendSms(String phone) {
    final normalized = normalizeToSouthAfrica(phone);
    return _items.any((i) => i.phone == normalized);
  }

  String _generateRandomPin() {
    return List.generate(4, (_) => _random.nextInt(10)).join();
  }

  // --- Admin override (open/clear compartments) -----------------------

  /// Physically opens a locker without touching its item record — mirrors
  /// Admin Override's "Open" action, which is distinct from "Clear" (see
  /// [clearLocker]): "Open" just unlocks the door, "Clear" additionally
  /// removes the parcel record. No-op in `'mock'` mode besides the log
  /// line, same as every other physical action here.
  ///
  /// [forCollectionSide] lets the Admin Override table's per-door rows
  /// (see [getAdminDoorRows]) open one specific physical door in paired
  /// mode; ignored outside paired mode.
  void openLockerOnly(int lockerId, {bool forCollectionSide = false}) {
    _unlockPhysicalLocker(lockerId, forCollectionSide: forCollectionSide);
  }

  /// Force-clears a locker's contents without a customer PIN — mirrors
  /// Admin Override's "Clear" action. In paired mode this opens *both*
  /// physical doors: an admin clearing a stuck locker doesn't necessarily
  /// know whether the parcel is still sitting behind the drop-off side or
  /// was already partially retrieved from the collection side, and
  /// "Clear" is meant to fully reset the pair either way.
  void clearLocker(int lockerId) {
    _items.removeWhere((i) => i.lockerId == lockerId);
    _persistItems();
    // Mirrors `openLockerWithAdminLogs`: admin override forces the door
    // open regardless of whether a parcel record existed for it.
    _unlockPhysicalLocker(lockerId);
    if (ConfigService().pairedLockerMode) {
      _unlockPhysicalLocker(lockerId, forCollectionSide: true);
    }
    notifyListeners();
  }

  void clearAllLockers() {
    final lockerIds = _lockers.map((l) => l.id).toList();
    final paired = ConfigService().pairedLockerMode;
    _items.clear();
    _persistItems();
    // Mirrors `openLockersSequentially`: opens every configured locker —
    // both physical doors of every pair when in paired mode (see
    // `clearLocker`'s doc comment for why).
    for (final lockerId in lockerIds) {
      _unlockPhysicalLocker(lockerId);
      if (paired) {
        _unlockPhysicalLocker(lockerId, forCollectionSide: true);
      }
    }
    notifyListeners();
  }

  /// Rows for the Admin Override table (see `AdminOverridePage`). Outside
  /// paired mode this is exactly [getAllLockers] — one row per locker.
  /// In paired mode, every logical locker produces *two* rows, one per
  /// physical door (drop-off side and collection side), per the confirmed
  /// requirement that admins see and control each physical door
  /// separately even though they share one occupancy state.
  List<AdminDoorRow> getAdminDoorRows() {
    final paired = ConfigService().pairedLockerMode;
    final rows = <AdminDoorRow>[];
    for (final locker in _lockers) {
      final occupied = !isLockerFree(locker.id);
      if (!paired) {
        rows.add(AdminDoorRow(
          lockerId: locker.id,
          label: '${locker.id}',
          forCollectionSide: false,
          occupied: occupied,
        ));
        continue;
      }
      final location = _pairLocationByLockerId[locker.id];
      final pairLabel =
          location == null ? 'Pair ? · Locker ${locker.id}' : 'Pair ${location.pairIndex + 1} · Locker ${location.localId}';
      rows.add(AdminDoorRow(
        lockerId: locker.id,
        label: '$pairLabel (Drop-off)',
        forCollectionSide: false,
        occupied: occupied,
      ));
      rows.add(AdminDoorRow(
        lockerId: locker.id,
        label: '$pairLabel (Collection)',
        forCollectionSide: true,
        occupied: occupied,
      ));
    }
    return rows;
  }

  /// Fire-and-forget physical unlock, only when the real gRPC backend is
  /// selected (see `ConfigService.lockerBackend`). In `'mock'` mode this is
  /// a no-op — nothing to unlock, there's no hardware involved.
  ///
  /// [forCollectionSide] picks which physical door to unlock in paired
  /// mode (see `ConfigService.pairedLockerMode`/`_grpcLockerNumber`):
  /// `false` (the default) targets the drop-off-side board, `true` targets
  /// the paired collection-side board covering the same physical cavity.
  /// Outside paired mode this parameter has no effect — there's only one
  /// door per logical locker, and [lockerId] is sent to gRPC as-is.
  void _unlockPhysicalLocker(int lockerId, {bool forCollectionSide = false}) {
    if (!ConfigService().isGrpcBackend) return;
    final grpcLockerNum =
        _grpcLockerNumber(lockerId, forCollectionSide: forCollectionSide);
    unawaited(LockerGrpcService.instance.unlockLocker(grpcLockerNum));
  }

  /// Liveness check against the configured backend — mirrors
  /// `MainActivity.handleGrpcCall`/`isCommunicationOn()`, which the Android
  /// app runs before letting a customer start Deliver/Collect/Help. In
  /// `'mock'` mode this always returns true (nothing to check). Not wired
  /// into any page automatically yet; call this from a page's button
  /// handler if you want the same "unit unreachable" gating Android has.
  Future<bool> checkBackendHealth() async {
    if (!ConfigService().isGrpcBackend) return true;
    return LockerGrpcService.instance.checkHealth();
  }

  // --- Validation ------------------------------------------------------
  //
  // Both just delegate to `PhoneUtils` — kept as static passthroughs here
  // (rather than updating every `MockKioskRepository.validatePhoneNumber`/
  // `normalizeToSouthAfrica` call site in `lib/pages/customer/` to call
  // `PhoneUtils` directly) purely so those call sites don't need to
  // change. `PhoneUtils` lives in `core/utilities/` rather than here so
  // `LockerGrpcService` (which this file already imports — putting the
  // logic there instead would make that a circular import) can use the
  // same normalization when actually sending an SMS.

  static bool validatePhoneNumber(String phoneNumber, bool isGlobal) =>
      PhoneUtils.validatePhoneNumber(phoneNumber, isGlobal);

  static String normalizeToSouthAfrica(String phoneNumber) =>
      PhoneUtils.normalizeToSouthAfrica(phoneNumber);
}

extension _FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
