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
///
/// ## Paired slave boards (`ConfigService.pairedLockerMode`)
///
/// Real-world topology: two slave boards mounted on opposite faces of the
/// same wall, wired so a given door on one side shares a physical cavity
/// with a specific door on the other — one side used for drop-off, the
/// other for collection. `_lockers` always contains *every* physical door
/// as its own independent [Locker] (exactly like unpaired mode — nothing
/// is hidden or merged there); what paired mode adds is a partner map
/// (`_pairPartnerByLockerId`, built in `_applyExplicitPairMappings` from
/// `ConfigService.lockerPairMappings` — an admin freely picks which locker
/// links to which, not derived automatically from board position) saying
/// which drop-off-side door id is linked to which collection-side door id.
/// A drop-off freezes both ids onto the `LockerItem` it creates
/// (`LockerItem.lockerId`/`.collectionLockerId`), so from then on that
/// parcel's two doors are fixed regardless of any later config edits.
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

  /// Drop-off-side locker id -> its linked collection-side locker id, and
  /// vice versa (populated both directions) — read straight from the
  /// admin's freely-chosen `ConfigService.lockerPairMappings` in
  /// `_applyExplicitPairMappings`. Only populated in paired mode; empty
  /// otherwise.
  final Map<int, int> _pairPartnerByLockerId = {};

  /// The subset of `_pairPartnerByLockerId`'s keys that are collection-side
  /// doors — i.e. NOT valid drop-off targets. Used to filter the
  /// customer-facing drop-off picker (see [getDropoffCandidateLockers]) and
  /// to label Locker Management rows. Only populated in paired mode.
  final Set<int> _collectionRoleLockerIds = {};

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

    // Deliberately NOT calling `syncLockersFromHardware()` here. It used
    // to run automatically on every app start/relaunch, which could
    // silently overwrite an admin's saved locker mapping — and with it,
    // any pairing built on top of that mapping (see
    // `ConfigService.reconcileLockerMappingToHardwareCount`, which isn't
    // aware of `_lockerPairMappings` and doesn't re-validate/prune them)
    // — the moment the app restarted, even if the on-disk config was
    // exactly what the admin wanted. Fetching the locker count from
    // hardware is now purely opt-in, via the Configuration page's "Sync
    // Lockers from Hardware" button (see `_syncLockersFromHardware` in
    // `configuration_page.dart`), so a relaunch never touches the saved
    // configuration on its own.
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
        // Only present (non-null) for a parcel dropped off while paired
        // mode was on — see `LockerItem.collectionLockerId`'s doc comment
        // for why this is frozen here rather than recomputed on read.
        'collectionLockerId': item.collectionLockerId,
        'creationDate': item.creationDate.toIso8601String(),
      };

  static LockerItem? _itemFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final phone = raw['phone'];
    final pin = raw['pin'];
    final lockerId = raw['lockerId'];
    final collectionLockerId = raw['collectionLockerId'];
    final creationDateRaw = raw['creationDate'];
    if (phone is! String ||
        pin is! String ||
        lockerId is! int ||
        creationDateRaw is! String) {
      return null;
    }
    if (collectionLockerId != null && collectionLockerId is! int) return null;
    final creationDate = DateTime.tryParse(creationDateRaw);
    if (creationDate == null) return null;
    return LockerItem(
      phone: phone,
      pin: pin,
      lockerId: lockerId,
      collectionLockerId: collectionLockerId as int?,
      creationDate: creationDate,
    );
  }

  /// Rebuilds `_lockers` from `ConfigService.lockerMapping` — called once
  /// at construction and again every time an admin saves a new mapping in
  /// `ConfigurationPage`. `_lockers` always holds *every* physical door,
  /// whether or not paired mode is on — see [_applyExplicitPairMappings]
  /// for the paired-mode overlay this derives on top of that flat list.
  /// Any in-flight parcel `Item`s whose locker (or paired locker) no
  /// longer exists after the change are dropped, so the app never shows a
  /// phantom "occupied" locker that isn't part of the current mapping.
  void _syncLockersFromConfig() {
    final config = ConfigService();
    _pairPartnerByLockerId.clear();
    _collectionRoleLockerIds.clear();

    _lockers = config.lockerMapping
        .map((entry) => Locker(id: entry.id, size: _parseSize(entry.size)))
        .toList();

    if (config.pairedLockerMode) {
      _applyExplicitPairMappings(config.lockerPairMappings);
    }

    final validIds = _lockers.map((l) => l.id).toSet();
    _items.removeWhere((item) =>
        !validIds.contains(item.lockerId) ||
        (item.collectionLockerId != null &&
            !validIds.contains(item.collectionLockerId)));

    notifyListeners();
  }

  /// Populates `_pairPartnerByLockerId` (bidirectional) and
  /// `_collectionRoleLockerIds` straight from the admin's freely-chosen
  /// [pairs] (see `ConfigService.lockerPairMappings`) — no board-position
  /// assumption anymore (an earlier version of this feature auto-derived
  /// pairing from adjacent boards at matching positions; pairing is now
  /// entirely explicit, so any two lockers can be linked regardless of
  /// which boards they're physically on).
  ///
  /// `ConfigService.validateLockerPairMappings` already guarantees no
  /// locker appears in more than one pair before this is ever persisted,
  /// but this re-checks defensively (a stale/corrupted config.json could
  /// in principle skip that validation) rather than risk silently
  /// overwriting one pair's link with another's.
  void _applyExplicitPairMappings(List<LockerPairMapping> pairs) {
    final validIds = _lockers.map((l) => l.id).toSet();
    for (final pair in pairs) {
      final dropoffId = pair.dropoffLockerId;
      final collectionId = pair.collectionLockerId;
      if (!validIds.contains(dropoffId) || !validIds.contains(collectionId)) {
        logger.w(
          'MockKioskRepository: locker pair ($dropoffId, $collectionId) '
          'references a locker id outside the current mapping — skipping.',
        );
        continue;
      }
      if (_pairPartnerByLockerId.containsKey(dropoffId) ||
          _pairPartnerByLockerId.containsKey(collectionId)) {
        logger.w(
          'MockKioskRepository: locker pair ($dropoffId, $collectionId) '
          'reuses an id already claimed by another pair — skipping.',
        );
        continue;
      }
      _pairPartnerByLockerId[dropoffId] = collectionId;
      _pairPartnerByLockerId[collectionId] = dropoffId;
      _collectionRoleLockerIds.add(collectionId);
    }
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

  /// Every physical locker door, drop-off *and* collection sides alike —
  /// what Locker Management's table is built from (see [getAdminDoorRows]).
  /// For picking a locker to drop a parcel into, use
  /// [getDropoffCandidateLockers]/[getFreeLockers] instead, which exclude
  /// collection-side doors in paired mode.
  List<Locker> getAllLockers() => List.unmodifiable(_lockers);

  /// Lockers a customer is allowed to pick for a *drop-off*. Outside
  /// paired mode this is every locker (unchanged behavior). In paired
  /// mode:
  ///
  /// - Returns nothing at all until `ConfigService.isLockerPairingComplete`
  ///   — every locker has to actually be paired (or be the one allowed
  ///   leftover on an odd total) before drop-off opens up at all, since an
  ///   incomplete pairing means there's no known door to open on
  ///   collection for whatever a customer would drop off in the meantime.
  /// - Once complete, collection-side doors are still never offered — a
  ///   customer should never be offered "Locker 9" if 9 is actually the
  ///   collection-side door of some pair, since nothing would ever be
  ///   physically placed there directly.
  List<Locker> getDropoffCandidateLockers() {
    final config = ConfigService();
    if (config.pairedLockerMode && !config.isLockerPairingComplete) {
      return const [];
    }
    if (_collectionRoleLockerIds.isEmpty) return List.unmodifiable(_lockers);
    return _lockers
        .where((l) => !_collectionRoleLockerIds.contains(l.id))
        .toList();
  }

  /// Free (unoccupied) lockers a customer can drop a parcel into. A door
  /// counts as occupied if it's either the drop-off id *or* the linked
  /// collection id of any active item — so in paired mode, dropping off
  /// into locker 2 also removes locker 2's paired collection door (say,
  /// locker 6) from every free-locker listing, even though 6 was never
  /// itself offered as a pickable option.
  List<Locker> getFreeLockers() {
    final occupied = <int>{};
    for (final item in _items) {
      occupied.add(item.lockerId);
      if (item.collectionLockerId != null) {
        occupied.add(item.collectionLockerId!);
      }
    }
    return getDropoffCandidateLockers()
        .where((l) => !occupied.contains(l.id))
        .toList();
  }

  List<Locker> getFreeLockersOfSize(LockerSize size) {
    return getFreeLockers().where((l) => l.size == size).toList();
  }

  /// A locker counts as occupied if it's either side of an active paired
  /// parcel — checking both `lockerId` and `collectionLockerId` is what
  /// makes both physical doors of a pair show "Occupied" together in
  /// Locker Management, even though only one of them was ever actually
  /// opened for the drop-off.
  bool isLockerFree(int lockerId) {
    return !_items.any((item) =>
        item.lockerId == lockerId || item.collectionLockerId == lockerId);
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

  /// The current locker state, translated to the VaultGroup dashboard's
  /// expected `db_entries` shape — confirmed 2026-07-24 against a real
  /// working unit's stored payload (`change_date` "2026-07-24T11:38:56Z",
  /// `status: "SYNCED"`). Used exclusively by
  /// `SettingsSyncService.pushToServer` to build the `db_entries` field it
  /// PUTs to the cloud.
  ///
  /// Confirmed shape, in order of how it differs from what this sent
  /// before:
  ///
  ///  - It's **one entry per physical locker door**, positionally aligned
  ///    with `lockers_sizes` (same length, same order — index `i` here is
  ///    `lockers_sizes[i]`'s door), not one entry per occupied parcel. An
  ///    empty unit's `db_entries` is `lockers_sizes.length` entries of
  ///    `{"size": ..., "data": null}` — the working example had 6 lockers
  ///    and 6 `db_entries` entries, 2 occupied + 4 `data: null`. Iterating
  ///    [_items] directly (as this did before) produced a shorter list with
  ///    no positional meaning at all, which the dashboard couldn't line up
  ///    against `lockers_sizes` — almost certainly the real reason nothing
  ///    rendered even after the `data`-wrapper fix.
  ///  - Each entry also carries the door's own `"size"` (`"small"`/
  ///    `"medium"`/`"large"`, lowercase — see [ConfigService.lockerMapping]
  ///    casing note in `SettingsSyncService.pushToServer`'s doc comment).
  ///  - Occupied doors nest the parcel fields under `"data"`:
  ///    `{cell_number, pin, override_code, date_added}` — matches
  ///    `createLockerItem`'s `FormGroup` on the dashboard side. Empty doors
  ///    send `"data": null`, not an omitted/empty object.
  ///
  /// A door is "occupied" if an item's `lockerId` *or* `collectionLockerId`
  /// matches it — mirrors [isLockerFree]'s definition, so a paired parcel's
  /// linked drop-off/collection doors both report the same occupant. Only
  /// verified against unpaired units so far; paired mode is this class's
  /// best guess, not confirmed against a real paired unit's dashboard view.
  ///
  /// `date_added` is UTC with a literal `Z` suffix, **no milliseconds**
  /// (`yyyy-MM-ddTHH:mm:ssZ`) — the working example's timestamps had none;
  /// see [_utcDateString]'s doc comment.
  ///
  /// `override_code` is sent as [LockerItem.pin] for now, but the working
  /// example's `override_code` values are clearly *not* a copy of `pin`
  /// (e.g. `pin: "12345"` / `override_code: "6007426955"` — different
  /// lengths, different values) — this app has no separate
  /// admin-override-code concept on [LockerItem] to source a real value
  /// from. Flagged as an open question rather than guessed further; see
  /// conversation with the app's maintainer.
  List<Map<String, dynamic>> cloudDbEntriesJson() => _lockers.map((locker) {
        LockerItem? occupant;
        for (final item in _items) {
          if (item.lockerId == locker.id ||
              item.collectionLockerId == locker.id) {
            occupant = item;
            break;
          }
        }
        return {
          'size': locker.size.name,
          'data': occupant == null
              ? null
              : {
                  'pin': occupant.pin,
                  'cell_number': occupant.phone,
                  'override_code': occupant.pin,
                  'date_added': _utcDateString(occupant.creationDate),
                },
        };
      }).toList();

  /// Formats [date] in UTC as `yyyy-MM-ddTHH:mm:ssZ`, e.g.
  /// `"2026-07-22T12:30:00Z"` — converts a local [DateTime] (as
  /// produced by `DateTime.now()` in [addItem]) to UTC first, since Dart's
  /// own `toIso8601String()` only appends `Z` for `DateTime`s already in
  /// UTC. No milliseconds — a real working unit's `db_entries.data.date_added`
  /// values (confirmed 2026-07-24) had none (`"2026-07-21T13:03:35Z"`), so
  /// this drops the `.SSS` this used to include.
  static String _utcDateString(DateTime date) {
    String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
    final utc = date.toUtc();
    return '${pad(utc.year, 4)}-${pad(utc.month)}-${pad(utc.day)}'
        'T${pad(utc.hour)}:${pad(utc.minute)}:${pad(utc.second)}Z';
  }

  /// Normalizes [phone] before comparing — defensive, in case a caller
  /// somewhere forgot to normalize first. Safe to do unconditionally since
  /// [normalizeToSouthAfrica] is idempotent (never adds a second "+27").
  List<LockerItem> itemsForPhone(String phone) {
    final normalized = normalizeToSouthAfrica(phone);
    return _items.where((i) => i.phone == normalized).toList();
  }

  /// [lockerId] must be a *drop-off*-side locker — i.e. one returned by
  /// [getDropoffCandidateLockers]/[getFreeLockers]/[pickRandomFreeLocker],
  /// never a raw id typed in from elsewhere. If this locker is linked to a
  /// collection-side partner (paired mode), that partner id is looked up
  /// once here and frozen onto the created item as `collectionLockerId` —
  /// see the doc comment on `LockerItem.collectionLockerId` for why it's
  /// frozen rather than recomputed later.
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
      collectionLockerId: _pairPartnerByLockerId[lockerId],
      creationDate: DateTime.now(),
    );
    _items.add(item);
    _persistItems();
    // Mirrors `DbService.addItem` -> `openLocker(item.lockerId)`: physically
    // unlock the assigned locker so the customer can place their parcel.
    // Only the drop-off door itself opens here — its paired collection
    // door (if any) stays locked until someone actually collects (see
    // `removeItems`), even though both now count as occupied.
    _unlockPhysicalLocker(lockerId);
    notifyListeners();
    return item;
  }

  void removeItems(List<LockerItem> items) {
    _items.removeWhere((i) => items.contains(i));
    _persistItems();
    // Mirrors `DbService.removeItem` -> `openLocker(item.lockerId)`: open
    // every collected item's locker so the customer can take their parcel.
    // Uses the item's own frozen `collectionLockerId` when present (paired
    // mode) — the *physical* door the parcel is retrieved from — falling
    // back to `lockerId` itself outside paired mode (single door, same as
    // before this feature existed).
    for (final item in items) {
      _unlockPhysicalLocker(item.collectionLockerId ?? item.lockerId);
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

  /// Physically opens exactly the given locker door, without touching any
  /// item record — mirrors Locker Management's "Open" action, which is
  /// distinct from "Clear" (see [clearLocker]): "Open" just unlocks the
  /// door, "Clear" additionally removes the parcel record. [lockerId] is
  /// always a real, specific physical door id here (each Locker Management
  /// row now maps 1:1 to one [Locker] — see [getAdminDoorRows]), so there's
  /// no "which side" ambiguity to resolve.
  void openLockerOnly(int lockerId) {
    _unlockPhysicalLocker(lockerId);
  }

  /// Force-clears a locker's contents without a customer PIN — mirrors
  /// Locker Management's "Clear" action. [lockerId] may be *either* side of a
  /// paired parcel (the row the admin happened to check) — this looks up
  /// the matching item by checking both `lockerId` and `collectionLockerId`
  /// so clearing works the same regardless of which row was selected, and
  /// opens both physical doors of any item it clears (an admin clearing a
  /// stuck locker doesn't necessarily know which side still has the
  /// parcel). If nothing was actually occupying [lockerId], it still opens
  /// that one door directly — e.g. an admin popping a locker open just to
  /// check it.
  void clearLocker(int lockerId) {
    final matching = _items
        .where((i) => i.lockerId == lockerId || i.collectionLockerId == lockerId)
        .toList();
    _items.removeWhere(matching.contains);
    _persistItems();

    if (matching.isEmpty) {
      _unlockPhysicalLocker(lockerId);
    } else {
      for (final item in matching) {
        _unlockPhysicalLocker(item.lockerId);
        if (item.collectionLockerId != null) {
          _unlockPhysicalLocker(item.collectionLockerId!);
        }
      }
    }
    notifyListeners();
  }

  /// Opens and clears every locker. Since [_lockers] already lists every
  /// physical door individually (both sides of every pair, in paired
  /// mode), a plain loop over all of them opens every door exactly once —
  /// no special-casing needed here, unlike the mutating methods above.
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

  /// Physically unlocks every locker door without touching any parcel
  /// record — mirrors Locker Management's "Open All" button. Unlike
  /// [clearAllLockers], this never wipes `_items`/db.json: a locker that
  /// was occupied before this call is still occupied (and still shows
  /// "Occupied" in the Locker Management table) after it, exactly like
  /// [openLockerOnly] does for a single door. Use [clearLocker]/
  /// [clearAllLockers] instead when the intent is to also free the
  /// locker(s) up.
  void openAllLockers() {
    for (final locker in _lockers) {
      _unlockPhysicalLocker(locker.id);
    }
  }

  /// Rows for the Locker Management table (see `LockerManagementPage`) — exactly
  /// one row per physical [Locker] in [_lockers]. Outside paired mode this
  /// is unchanged from before pairing existed. In paired mode, a
  /// collection-side door's row is labeled with which drop-off door it's
  /// linked to (and vice versa), and both rows of a pair always show the
  /// same [AdminDoorRow.occupied] value (see [isLockerFree]).
  List<AdminDoorRow> getAdminDoorRows() {
    return [
      for (final locker in _lockers)
        AdminDoorRow(
          lockerId: locker.id,
          label: _doorLabel(locker.id),
          forCollectionSide: _collectionRoleLockerIds.contains(locker.id),
          occupied: !isLockerFree(locker.id),
        ),
    ];
  }

  /// Row label for the Locker Management / locker management table — plain
  /// locker id, plus which paired locker id it's linked to. An admin
  /// managing lockers wants the raw ids that match `db.json`,
  /// `config.json`'s pairing, and gRPC's own locker_num directly.
  String _doorLabel(int lockerId) {
    final partner = _pairPartnerByLockerId[lockerId];
    if (partner == null) return '$lockerId';
    final role = _collectionRoleLockerIds.contains(lockerId) ? 'Collection' : 'Drop-off';
    return 'Locker $lockerId ($role, paired with Locker $partner)';
  }

  /// Human-facing label for [lockerId] — what customer-facing drop-off/
  /// collection screens show instead of the raw flat id (see
  /// `DeliverPlaceParcelPage`/`CollectionCompletePage`).
  ///
  /// Previously showed a "Board N, Locker L" label derived from an admin-
  /// entered board layout (see [ConfigService.lockerMapping]'s doc comment
  /// for why that concept was removed) — every screen now just relies on
  /// the plain, total locker count (whether admin-configured or fetched
  /// from hardware via `syncLockersFromHardware`), so this is now always
  /// just the flat id itself. Kept as a named method (rather than inlining
  /// `'$lockerId'` at every call site) so a future display concept has one
  /// place to change.
  String lockerDisplayLabel(int lockerId) => '$lockerId';

  /// Fire-and-forget physical unlock, only when the real gRPC backend is
  /// selected (see `ConfigService.lockerBackend`). In `'mock'` mode this is
  /// a no-op — nothing to unlock, there's no hardware involved. [lockerId]
  /// is sent to gRPC exactly as given — every caller above is already
  /// responsible for passing the *specific* physical door id it means
  /// (drop-off or collection), so there's no translation/offset math here
  /// (unlike an earlier version of this feature — see the class doc
  /// comment on paired mode for why that translation layer was removed).
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
