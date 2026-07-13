import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/config_service.dart';
import '../grpc/locker_grpc_service.dart';
import '../utilities/logging.dart';
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

  /// Rebuilds `_lockers` from `ConfigService.lockerMapping` — called once
  /// at construction and again every time an admin saves a new mapping in
  /// `ConfigurationPage`. Any in-flight parcel `Item`s whose locker no
  /// longer exists after the change are dropped, so the app never shows a
  /// phantom "occupied" locker that isn't part of the current mapping.
  void _syncLockersFromConfig() {
    _lockers = ConfigService()
        .lockerMapping
        .map((entry) => Locker(id: entry.id, size: _parseSize(entry.size)))
        .toList();

    final validIds = _lockers.map((l) => l.id).toSet();
    _items.removeWhere((item) => !validIds.contains(item.lockerId));

    notifyListeners();
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

  List<LockerItem> itemsForPhone(String phone) {
    return _items.where((i) => i.phone == phone).toList();
  }

  LockerItem addItem({required String phone, required int lockerId}) {
    // Mirrors DeliverPlaceParcelActivity: if this phone already has a
    // parcel, reuse the same PIN rather than issuing a new one.
    final existing = _items.firstWhereOrNull((i) => i.phone == phone);
    final item = LockerItem(
      phone: phone,
      pin: existing?.pin ?? _generateRandomPin(),
      lockerId: lockerId,
      creationDate: DateTime.now(),
    );
    _items.add(item);
    _persistItems();
    // Mirrors `DbService.addItem` -> `openLocker(item.lockerId)`: physically
    // unlock the assigned locker so the customer can place their parcel.
    _unlockPhysicalLocker(lockerId);
    notifyListeners();
    return item;
  }

  void removeItems(List<LockerItem> items) {
    _items.removeWhere((i) => items.contains(i));
    _persistItems();
    // Mirrors `DbService.removeItem` -> `openLocker(item.lockerId)`: open
    // every collected item's locker so the customer can take their parcel.
    for (final item in items) {
      _unlockPhysicalLocker(item.lockerId);
    }
    notifyListeners();
  }

  /// Mirrors `HelpActivity`'s "resend PIN via SMS" — succeeds only if the
  /// phone number has at least one parcel waiting.
  bool resendSms(String phone) {
    return _items.any((i) => i.phone == phone);
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
  void openLockerOnly(int lockerId) {
    _unlockPhysicalLocker(lockerId);
  }

  /// Force-clears a locker's contents without a customer PIN — mirrors
  /// Admin Override's "Clear" action.
  void clearLocker(int lockerId) {
    _items.removeWhere((i) => i.lockerId == lockerId);
    _persistItems();
    // Mirrors `openLockerWithAdminLogs`: admin override forces the door
    // open regardless of whether a parcel record existed for it.
    _unlockPhysicalLocker(lockerId);
    notifyListeners();
  }

  void clearAllLockers() {
    final lockerIds = _lockers.map((l) => l.id).toList();
    _items.clear();
    _persistItems();
    // Mirrors `openLockersSequentially`: opens every configured locker.
    for (final lockerId in lockerIds) {
      _unlockPhysicalLocker(lockerId);
    }
    notifyListeners();
  }

  /// Fire-and-forget physical unlock, only when the real gRPC backend is
  /// selected (see `ConfigService.lockerBackend`). In `'mock'` mode this is
  /// a no-op — nothing to unlock, there's no hardware involved.
  void _unlockPhysicalLocker(int lockerId) {
    if (!ConfigService().isGrpcBackend) return;
    unawaited(LockerGrpcService.instance.unlockLocker(lockerId));
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

  /// Ported from `UtilService.validatePhoneNumber`: either a local
  /// 10-digit `0XXXXXXXXX` number, or an international `+`-prefixed
  /// number (max 12 digits normally, 15 when [isGlobal] is on).
  static bool validatePhoneNumber(String phoneNumber, bool isGlobal) {
    final local = RegExp(r'^0\d{9}$');
    final intl = RegExp(isGlobal ? r'^\+[0-9]{1,15}$' : r'^\+[0-9]{1,12}$');
    return local.hasMatch(phoneNumber) || intl.hasMatch(phoneNumber);
  }

  /// Normalizes a leading `0` into the `+27` South African country code,
  /// matching every Activity's `if (phone.startsWith("0")) phone = "+27" +
  /// phone.substring(1)` snippet.
  static String normalizeToSouthAfrica(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+27${phoneNumber.substring(1)}';
    }
    return phoneNumber;
  }
}

extension _FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
