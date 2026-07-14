import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utilities/logging.dart';

/// One physical locker slot's id + size, as stored in `config.json`'s
/// `locker_mapping` array. Mirrors the Android app's `lockerConfig.json`
/// (`Locker(id, size)`, written by `LockerService.updateLockerConfig`) —
/// kept as a tiny standalone type here (rather than reusing
/// `core/mock/models.dart`'s `Locker`) so `ConfigService` doesn't depend on
/// the mock layer it's meant to outlive; `MockKioskRepository` converts
/// these into its own `Locker` objects when it syncs.
class LockerMappingEntry {
  const LockerMappingEntry({required this.id, required this.size});

  final int id;

  /// `'small'`, `'medium'`, or `'large'` — always lowercase.
  final String size;

  Map<String, dynamic> toJson() => {'id': id, 'size': size};

  static LockerMappingEntry? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final size = raw['size'];
    if (id is! int || size is! String) return null;
    final normalized = size.toLowerCase();
    if (!_validSizes.contains(normalized)) return null;
    return LockerMappingEntry(id: id, size: normalized);
  }
}

const _validSizes = {'small', 'medium', 'large'};

/// One physical locker door within a paired-slave-board pair — see
/// `ConfigService.lockerPairs` for the full "paired slave board" topology
/// this models (real-world: two slave boards mounted back-to-back on a
/// wall, one side used for drop-off, the other for collection, with
/// matching door positions on each side wired to the same physical
/// cavity). `localId` is 1-based and local to the pair — distinct from the
/// flat/global id `MockKioskRepository` assigns each pair for its existing
/// occupancy-tracking logic.
class LockerPairEntry {
  const LockerPairEntry({
    required this.localId,
    required this.dropoffSize,
    required this.collectionSize,
  });

  final int localId;

  /// Size shown to a customer picking a locker to drop off into — this is
  /// the side that actually drives free-locker-by-size lookups (see
  /// `MockKioskRepository._syncLockersFromConfig`).
  final String dropoffSize;

  /// Size of the matching door on the collection-side board. Tracked for
  /// admin visibility/honesty only — nothing looks this up to *pick* a
  /// locker, since collection always targets a specific existing parcel's
  /// locker rather than "any free locker of size X".
  final String collectionSize;

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'dropoffSize': dropoffSize,
        'collectionSize': collectionSize,
      };

  static LockerPairEntry? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final localId = raw['localId'];
    final dropoffSize = raw['dropoffSize'];
    final collectionSize = raw['collectionSize'];
    if (localId is! int ||
        dropoffSize is! String ||
        collectionSize is! String) {
      return null;
    }
    final d = dropoffSize.toLowerCase();
    final c = collectionSize.toLowerCase();
    if (!_validSizes.contains(d) || !_validSizes.contains(c)) return null;
    return LockerPairEntry(localId: localId, dropoffSize: d, collectionSize: c);
  }
}

/// One physical slave-board pair: a drop-off-side board and a
/// collection-side board sharing the same physical cavities, door for
/// door. `lockers` is ordered by `localId` (1..N) and always has the same
/// length as every other pair's hardware door count *within that pair*
/// (drop-off and collection sides of one pair always match), though the
/// count can differ pair-to-pair. See `ConfigService.lockerPairs`.
class LockerPair {
  const LockerPair({required this.lockers});

  final List<LockerPairEntry> lockers;

  Map<String, dynamic> toJson() =>
      {'lockers': lockers.map((e) => e.toJson()).toList()};

  static LockerPair? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final rawLockers = raw['lockers'];
    if (rawLockers is! List || rawLockers.isEmpty) return null;
    final parsed = rawLockers.map(LockerPairEntry.tryFromJson).toList();
    if (parsed.any((e) => e == null)) return null;
    return LockerPair(lockers: parsed.cast<LockerPairEntry>());
  }
}

/// Comma-separated drop-off/collection size lists for one pair, as edited
/// in `ConfigurationPage`'s paired-mode editor — the free-text input
/// `ConfigService.setLockerPairs` parses and validates. Kept separate from
/// `LockerPair`/`LockerPairEntry` (the parsed, persisted shape) the same
/// way `setLockerMapping`'s comma-string input is separate from
/// `LockerMappingEntry`.
class LockerPairSizesInput {
  const LockerPairSizesInput({
    required this.dropoffSizesCsv,
    required this.collectionSizesCsv,
  });

  final String dropoffSizesCsv;
  final String collectionSizesCsv;
}

/// Single source of truth for every setting admins can change from the
/// Admin menu, backed by a local `config.json` next to the app (mirroring
/// how the Android app kept `admin.json` / `lockerConfig.json` on-device
/// rather than bundled).
///
/// `config.json` is read once at startup (see [initialize], called from
/// `main.dart`), then kept in memory. Every setter below re-validates its
/// input against the same rule the UI enforces, and only writes the new
/// value back to `config.json` — leaving a readable record of the current
/// settings on disk — if it passes. A rejected value never reaches the
/// file or the in-memory state.
///
/// Each window (Admin/Customer) runs its own Flutter engine/isolate, so a
/// setting changed in one window isn't automatically visible in the
/// other's in-memory copy. `initialize()` also starts a filesystem watch
/// on `config.json` (see [_startWatching]), so a change saved in one
/// window is picked up and reflected in the other within moments, without
/// needing a restart.
///
/// Extends `ChangeNotifier` so dependents (`MockKioskRepository`'s locker
/// inventory, and any widget listening directly) can react live both to
/// local changes and to changes reloaded from an external write.
class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();

  bool _initialized = false;

  // --- config.json keys and defaults ----------------------------------
  static const String _kAdminPin = 'admin_pin';
  static const String _kDropOffPin = 'drop_off_pin';
  static const String _kSmsTemplate = 'sms_template';
  static const String _kLockerMapping = 'locker_mapping';
  static const String _kLockerAddress = 'locker_address';
  static const String _kLockerBackend = 'locker_backend';
  static const String _kKioskMode = 'kiosk_mode';
  static const String _kCvmainConfigDir = 'cvmain_config_dir';
  static const String _kPairedLockerMode = 'paired_locker_mode';
  static const String _kLockerPairs = 'locker_pairs';

  static const String _defaultAdminPin = '12345';
  static const String _defaultDropOffPin = '12345';
  static const String _defaultSmsTemplate =
      'Your PackVault collection PIN is {pin}. Thank you for using PackVault.';

  /// A generic placeholder — deliberately not any specific unit's real IP,
  /// since this is what `reset()` falls back to. Port 7777 does matter
  /// though: it matches `cvmain`'s real default `local_server.bind_addr`
  /// (`0.0.0.0:7777`, confirmed from a physical unit's
  /// `/cv/config/config.json` and `libcvmain_rs.so`), not an arbitrary
  /// placeholder. Set the real unit's address via the Configuration page
  /// (or directly in config.json) — see `_kLockerAddress`.
  static const String _defaultLockerAddress = '192.168.1.100:7777';

  /// `'mock'` — the in-memory/db.json-backed `MockKioskRepository` behavior
  /// used for UI dev and demos. `'grpc'` — real `unlock_locker` calls are
  /// sent to `lockerAddress` via `LockerGrpcService`, speaking the same
  /// `cv_saas.CommsService` proto the Android app and the physical unit's
  /// `cvmain` both use. See `core/grpc/locker_grpc_service.dart`.
  static const String _defaultLockerBackend = 'mock';
  static const Set<String> _validLockerBackends = {'mock', 'grpc'};

  /// The real cvmain config directory, confirmed by SSHing into this
  /// deployment's physical unit and running `find / -iname "auth.json"`
  /// (see `UnitRegistrationService.mirrorToCvmainConfig`'s doc comment).
  /// Used as the actual default now — not just a placeholder — since this
  /// app only targets this one known Pi deployment (cvmain +
  /// multi-window-app, no Android app involved). Still editable via the
  /// Unit Registration page if a different unit ever uses a different
  /// path.
  static const String _defaultCvmainConfigDir = '/home/pi/cv/cvmain/config';

  /// Off by default so a developer running on macOS/Windows/Linux desktop
  /// still gets normal window chrome and can drag/resize windows freely.
  /// Flip this on for a Raspberry Pi (or any) deployment where each window
  /// should fill its entire display with no title bar — see
  /// `WindowService.configureAndShow`.
  static const bool _defaultKioskMode = false;

  /// 2 small + 2 medium + 2 large = 6 lockers, ids 1-6 — a sensible default
  /// shape now that `locker_mapping` is a structured id/size list rather
  /// than a bare count.
  static const List<LockerMappingEntry> _defaultLockerMapping = [
    LockerMappingEntry(id: 1, size: 'small'),
    LockerMappingEntry(id: 2, size: 'small'),
    LockerMappingEntry(id: 3, size: 'medium'),
    LockerMappingEntry(id: 4, size: 'medium'),
    LockerMappingEntry(id: 5, size: 'large'),
    LockerMappingEntry(id: 6, size: 'large'),
  ];

  /// Off by default — opt-in, so existing single-board (or unpaired
  /// multi-board) deployments keep behaving exactly as before. Turn on
  /// only for the "drop-off board mounted opposite a matching collection
  /// board" physical topology described on `lockerPairs`.
  static const bool _defaultPairedLockerMode = false;

  static const List<LockerPair> _defaultLockerPairs = [];

  String _adminPin = _defaultAdminPin;
  String _dropOffPin = _defaultDropOffPin;
  String _smsTemplate = _defaultSmsTemplate;
  List<LockerMappingEntry> _lockerMapping = _defaultLockerMapping;
  String _lockerAddress = _defaultLockerAddress;
  String _lockerBackend = _defaultLockerBackend;
  bool _kioskMode = _defaultKioskMode;

  String _cvmainConfigDir = _defaultCvmainConfigDir;

  bool _pairedLockerMode = _defaultPairedLockerMode;
  List<LockerPair> _lockerPairs = _defaultLockerPairs;

  StreamSubscription<FileSystemEvent>? _watchSubscription;

  ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  File get _configFile => File('${Directory.current.path}/config.json');

  /// Initialize ConfigService (call this in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    // `_configFile` resolves relative to `Directory.current.path` — log it
    // once so a silently-swallowed write failure (e.g. this path being
    // outside what the OS lets the app write to) is easy to spot in the
    // console instead of just missing from config.json.
    logger.i('ConfigService: reading/writing ${_configFile.path}');

    await _loadConfigFile();
    _initialized = true;
    _startWatching();
    logger.i('ConfigService initialized');
  }

  /// Watches `config.json` for changes made by *another* window's engine.
  /// Each window (Admin/Customer) runs its own Flutter engine/isolate, so
  /// in-memory state here isn't automatically shared between them — this
  /// is what makes a setting changed in one window show up in the other
  /// shortly after, instead of only on next app restart.
  void _startWatching() {
    try {
      _watchSubscription =
          _configFile.watch().listen((_) => _reloadFromDiskAndNotify());
    } catch (e) {
      logger.w('Could not watch config.json for external changes: $e');
    }
  }

  Future<void> _reloadFromDiskAndNotify() async {
    await _loadConfigFile();
    notifyListeners();
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  /// Loads settings from `config.json`, creating the file with defaults if
  /// it doesn't exist yet, and back-filling any keys missing from an older
  /// copy of the file so it's always self-consistent.
  Future<void> _loadConfigFile() async {
    try {
      final file = _configFile;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _adminPin = json[_kAdminPin] as String? ?? _defaultAdminPin;
        _dropOffPin = json[_kDropOffPin] as String? ?? _defaultDropOffPin;
        _smsTemplate = json[_kSmsTemplate] as String? ?? _defaultSmsTemplate;
        _lockerAddress = json[_kLockerAddress] as String? ?? _defaultLockerAddress;
        _cvmainConfigDir = json[_kCvmainConfigDir] as String? ?? _defaultCvmainConfigDir;

        var needsRewrite = json.length != 10 ||
            !json.containsKey(_kAdminPin) ||
            !json.containsKey(_kDropOffPin) ||
            !json.containsKey(_kSmsTemplate) ||
            !json.containsKey(_kLockerMapping) ||
            !json.containsKey(_kLockerAddress) ||
            !json.containsKey(_kLockerBackend) ||
            !json.containsKey(_kKioskMode) ||
            !json.containsKey(_kCvmainConfigDir) ||
            !json.containsKey(_kPairedLockerMode) ||
            !json.containsKey(_kLockerPairs);

        final rawPairedMode = json[_kPairedLockerMode];
        _pairedLockerMode =
            rawPairedMode is bool ? rawPairedMode : _defaultPairedLockerMode;
        if (rawPairedMode is! bool) needsRewrite = true;

        final rawPairs = json[_kLockerPairs];
        if (rawPairs is List) {
          if (rawPairs.isEmpty) {
            _lockerPairs = _defaultLockerPairs;
          } else {
            final parsedPairs = rawPairs.map(LockerPair.tryFromJson).toList();
            if (parsedPairs.every((e) => e != null)) {
              _lockerPairs = parsedPairs.cast<LockerPair>();
            } else {
              // Malformed pair entries — fall back to empty (paired mode
              // effectively disabled until an admin re-enters the mapping)
              // rather than risk unlocking the wrong physical door with a
              // half-parsed pair list.
              _lockerPairs = _defaultLockerPairs;
              _pairedLockerMode = false;
              needsRewrite = true;
            }
          }
        } else {
          _lockerPairs = _defaultLockerPairs;
          needsRewrite = true;
        }

        final rawKioskMode = json[_kKioskMode];
        _kioskMode = rawKioskMode is bool ? rawKioskMode : _defaultKioskMode;
        if (rawKioskMode is! bool) needsRewrite = true;

        final rawBackend = json[_kLockerBackend];
        if (rawBackend is String && _validLockerBackends.contains(rawBackend)) {
          _lockerBackend = rawBackend;
        } else {
          // Missing (older config.json) or invalid — fall back to 'mock'
          // rather than silently trying to reach hardware nobody configured.
          _lockerBackend = _defaultLockerBackend;
          needsRewrite = true;
        }

        final rawMapping = json[_kLockerMapping];
        if (rawMapping is List) {
          final parsed = rawMapping.map(LockerMappingEntry.tryFromJson).toList();
          if (parsed.isNotEmpty && parsed.every((e) => e != null)) {
            _lockerMapping = parsed.cast<LockerMappingEntry>();
          } else {
            // Malformed entries (bad id/size) — fall back to the default
            // shape and rewrite the file so it's valid going forward.
            _lockerMapping = _defaultLockerMapping;
            needsRewrite = true;
          }
        } else {
          // Old format (a bare count/string like "6", or missing entirely)
          // — migrate to the structured id/size list.
          _lockerMapping = _defaultLockerMapping;
          needsRewrite = true;
          if (rawMapping != null) {
            logger.i(
              'Migrating locker_mapping from old format ($rawMapping) to '
              'structured id/size list.',
            );
          }
        }

        if (needsRewrite) {
          await _persistConfig();
        }
      } else {
        await _persistConfig();
      }
    } catch (e) {
      logger.w('Failed to load config.json, falling back to defaults: $e');
    }
  }

  Future<void> _persistConfig() async {
    await _configFile.writeAsString(const JsonEncoder.withIndent('  ').convert({
      _kAdminPin: _adminPin,
      _kDropOffPin: _dropOffPin,
      _kSmsTemplate: _smsTemplate,
      _kLockerMapping: _lockerMapping.map((e) => e.toJson()).toList(),
      _kLockerAddress: _lockerAddress,
      _kLockerBackend: _lockerBackend,
      _kKioskMode: _kioskMode,
      _kCvmainConfigDir: _cvmainConfigDir,
      _kPairedLockerMode: _pairedLockerMode,
      _kLockerPairs: _lockerPairs.map((e) => e.toJson()).toList(),
    }));
    notifyListeners();
  }

  // --- Validation --------------------------------------------------------
  //
  // Shared by the setters below (the source of truth) and by the admin UI
  // (for live input filtering / inline error messages), so a value can
  // never be persisted without passing the same rule the field displays.

  /// Admin PIN: numeric only, max length 10.
  static String? validateAdminPin(String value) {
    if (value.isEmpty) return 'Admin PIN is required.';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Admin PIN must contain numbers only.';
    }
    if (value.length > 10) return 'Admin PIN must be at most 10 digits.';
    return null;
  }

  /// Drop off PIN: numeric only, max length 6.
  static String? validateDropOffPin(String value) {
    if (value.isEmpty) return 'Drop off PIN is required.';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Drop off PIN must contain numbers only.';
    }
    if (value.length > 6) return 'Drop off PIN must be at most 6 digits.';
    return null;
  }

  /// SMS template: alphanumeric (plus common punctuation/whitespace, since
  /// the template text itself needs spaces and a `{pin}` placeholder),
  /// between 40 and 160 characters.
  static String? validateSmsTemplate(String value) {
    if (value.length < 40) {
      return 'SMS template must be at least 40 characters.';
    }
    if (value.length > 160) {
      return 'SMS template must be at most 160 characters.';
    }
    if (!RegExp(r"^[a-zA-Z0-9\s{}.,!?'-]+$").hasMatch(value)) {
      return 'SMS template contains unsupported characters.';
    }
    return null;
  }

  /// Locker mapping: a comma-separated list of sizes, one per physical
  /// locker, in order — e.g. `"small,small,medium,large"` for 4 lockers.
  /// Ids are assigned automatically by position (1-based), mirroring the
  /// Android app's `SettingsService.parseStringArrayToLockerList`.
  static String? validateLockerMapping(String value) {
    final stripped = stripWhitespace(value);
    if (stripped.isEmpty) return 'Locker mapping is required.';
    final tokens = stripped.split(',');
    if (tokens.any((t) => t.isEmpty)) {
      return 'Locker mapping has an empty entry — check for stray commas.';
    }
    final invalid = tokens.where((t) => !_validSizes.contains(t.toLowerCase()));
    if (invalid.isNotEmpty) {
      return 'Each entry must be small, medium, or large (found "${invalid.first}").';
    }
    return null;
  }

  /// Validates one paired-slave-board pair's drop-off/collection size
  /// lists: each list must independently pass [validateLockerMapping], and
  /// — since a drop-off door and its paired collection door always share
  /// the same physical door count (see `LockerPair`) — both lists must
  /// have the same number of entries.
  static String? validateLockerPairSizes(
      String dropoffSizesCsv, String collectionSizesCsv) {
    final dropoffError = validateLockerMapping(dropoffSizesCsv);
    if (dropoffError != null) return 'Drop-off side: $dropoffError';
    final collectionError = validateLockerMapping(collectionSizesCsv);
    if (collectionError != null) return 'Collection side: $collectionError';

    final dropoffCount = stripWhitespace(dropoffSizesCsv).split(',').length;
    final collectionCount =
        stripWhitespace(collectionSizesCsv).split(',').length;
    if (dropoffCount != collectionCount) {
      return 'Drop-off side has $dropoffCount locker(s) but collection side '
          'has $collectionCount — a paired board\'s two sides must match.';
    }
    return null;
  }

  /// Strips every character out of [value] that isn't a digit — used to
  /// filter keystrokes live in numeric-only fields.
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String stripWhitespace(String value) =>
      value.replaceAll(RegExp(r'\s'), '');

  // --- Getters -------------------------------------------------------

  /// The admin PIN checked by the "tap the VG badge 5 times" gate on the
  /// Customer window's Home page. Mirrors `admin.json` in the Android app.
  String get adminPin => _adminPin;

  /// The customer-facing drop-off PIN checked before starting a drop-off
  /// when it's enabled.
  String get dropOffPin => _dropOffPin;

  /// The SMS body sent on drop-off/collection notifications — `{pin}` is
  /// substituted with the actual OTP before it's "sent" (logged) by
  /// `HelpPage` and `DeliverPlaceParcelPage`.
  String get smsTemplate => _smsTemplate;

  /// The current locker inventory as structured id/size entries — what
  /// `MockKioskRepository` syncs its locker list from.
  List<LockerMappingEntry> get lockerMapping => List.unmodifiable(_lockerMapping);

  /// The same data as [lockerMapping], flattened to the editable
  /// comma-separated shorthand (`"small,small,medium,..."`) for display in
  /// `ConfigurationPage`'s text field.
  String get lockerMappingText => _lockerMapping.map((e) => e.size).join(',');

  /// Whether "paired slave board" mode is on — see [lockerPairs] for the
  /// physical topology this models. When true, `MockKioskRepository`
  /// ignores [lockerMapping] and builds its locker inventory from
  /// [lockerPairs] instead, and every physical unlock computes a
  /// drop-off-board or collection-board gRPC `locker_num` depending on
  /// which action is happening rather than using the flat locker id
  /// directly.
  bool get pairedLockerMode => _pairedLockerMode;

  /// The paired slave-board topology: each entry is one physical board
  /// pair — a drop-off-side board and a collection-side board mounted on
  /// opposite faces of the same wall cavity, so a locker used for
  /// drop-off on board N is the *same physical compartment* as the
  /// matching locker on board N's paired collection board. Pairs are
  /// always sequential in gRPC's global locker numbering (pair 0 = boards
  /// 1↔2, pair 1 = boards 3↔4, ...) — see
  /// `MockKioskRepository._grpcLockerNumber` for the offset math this
  /// getter feeds.
  ///
  /// Only meaningful when [pairedLockerMode] is true; empty otherwise.
  List<LockerPair> get lockerPairs => List.unmodifiable(_lockerPairs);

  Future<void> setPairedLockerMode(bool value) async {
    _pairedLockerMode = value;
    await _persistConfig();
    logger.i('Paired locker mode updated to: $value');
  }

  /// Parses one comma-separated drop-off/collection size list per pair
  /// (see [validateLockerPairSizes]) into structured [LockerPair]s and
  /// persists them. `localId`s within each pair are assigned by position
  /// (1-based), mirroring [setLockerMapping]'s id-by-position convention.
  ///
  /// Validates every pair before writing any of them — a partially valid
  /// list is never persisted, since a truncated/mismatched pair list here
  /// could make `MockKioskRepository` compute a wrong physical door for
  /// an existing drop-off.
  Future<String?> setLockerPairs(List<LockerPairSizesInput> pairs) async {
    if (pairs.isEmpty) return 'At least one board pair is required.';

    for (var i = 0; i < pairs.length; i++) {
      final error = validateLockerPairSizes(
          pairs[i].dropoffSizesCsv, pairs[i].collectionSizesCsv);
      if (error != null) return 'Pair ${i + 1}: $error';
    }

    _lockerPairs = [
      for (final pair in pairs)
        LockerPair(
          lockers: [
            for (var i = 0;
                i < stripWhitespace(pair.dropoffSizesCsv).split(',').length;
                i++)
              LockerPairEntry(
                localId: i + 1,
                dropoffSize: stripWhitespace(pair.dropoffSizesCsv)
                    .split(',')[i]
                    .toLowerCase(),
                collectionSize: stripWhitespace(pair.collectionSizesCsv)
                    .split(',')[i]
                    .toLowerCase(),
              ),
          ],
        ),
    ];
    await _persistConfig();
    logger.i('Locker pairs updated: ${_lockerPairs.length} pair(s).');
    return null;
  }

  /// Flattens [lockerPairs] into the same comma-separated shorthand
  /// [lockerMappingText] uses, for display in the paired-mode editor —
  /// one line per pair, drop-off sizes then collection sizes.
  List<LockerPairSizesInput> get lockerPairsAsText => [
        for (final pair in _lockerPairs)
          LockerPairSizesInput(
            dropoffSizesCsv: pair.lockers.map((e) => e.dropoffSize).join(','),
            collectionSizesCsv:
                pair.lockers.map((e) => e.collectionSize).join(','),
          ),
      ];

  // --- Setters ---------------------------------------------------------
  //
  // Each validates against the same rule as its `validate*` counterpart
  // above, returning the error message on failure (leaving the previous
  // value and file untouched) or `null` on success, once the new value has
  // been written to `config.json` and taken effect in memory.

  Future<String?> setAdminPin(String value) async {
    final error = validateAdminPin(value);
    if (error != null) return error;
    _adminPin = value;
    await _persistConfig();
    logger.i('Admin PIN updated.');
    return null;
  }

  Future<String?> setDropOffPin(String value) async {
    final error = validateDropOffPin(value);
    if (error != null) return error;
    _dropOffPin = value;
    await _persistConfig();
    logger.i('Drop off PIN updated.');
    return null;
  }

  Future<String?> setSmsTemplate(String value) async {
    final error = validateSmsTemplate(value);
    if (error != null) return error;
    _smsTemplate = value;
    await _persistConfig();
    logger.i('SMS template updated.');
    return null;
  }

  /// Parses a comma-separated size list (see [validateLockerMapping]) into
  /// structured id/size entries and persists it. This is what
  /// `MockKioskRepository` rebuilds its locker inventory from — see
  /// `MockKioskRepository._syncLockersFromConfig`.
  Future<String?> setLockerMapping(String value) async {
    final stripped = stripWhitespace(value);
    final error = validateLockerMapping(stripped);
    if (error != null) return error;

    final sizes = stripped.split(',');
    _lockerMapping = [
      for (var i = 0; i < sizes.length; i++)
        LockerMappingEntry(id: i + 1, size: sizes[i].toLowerCase()),
    ];
    await _persistConfig();
    logger.i('Locker mapping updated to: $_lockerMapping');
    return null;
  }

  /// The gRPC locker backend address (IP:PORT) — e.g. a physical unit's
  /// `cvmain` gRPC server, or a `cv-simulator-rs` setup fronted by the same
  /// contract. Only actually used when [lockerBackend] is `'grpc'`.
  String get lockerAddress => _lockerAddress;

  /// Set the gRPC locker address
  Future<void> setLockerAddress(String address) async {
    _lockerAddress = address;
    await _persistConfig();
    logger.i('Locker address updated to: $address');
  }

  /// `'mock'` (default) or `'grpc'` — which backend `MockKioskRepository`
  /// sends physical unlock actions to. See `_defaultLockerBackend` above
  /// and `core/grpc/locker_grpc_service.dart`.
  String get lockerBackend => _lockerBackend;

  bool get isGrpcBackend => _lockerBackend == 'grpc';

  static String? validateLockerBackend(String value) {
    if (!_validLockerBackends.contains(value)) {
      return 'Locker backend must be "mock" or "grpc".';
    }
    return null;
  }

  /// Switches between the in-memory mock backend and real hardware over
  /// gRPC. Does not itself check that [lockerAddress] is reachable — that
  /// happens lazily, the next time `LockerGrpcService` is actually used
  /// (e.g. on the next drop-off/collection/admin-override unlock).
  Future<String?> setLockerBackend(String value) async {
    final error = validateLockerBackend(value);
    if (error != null) return error;
    _lockerBackend = value;
    await _persistConfig();
    logger.i('Locker backend updated to: $value');
    return null;
  }

  /// Reconciles the locker mapping to a hardware-reported locker count —
  /// called by `MockKioskRepository.syncLockersFromHardware` after asking
  /// the unit `get_locker_states` (mirrors Android's
  /// `LockerService.initializeLockerFromCv`/`getLockersForConfiguration`).
  ///
  /// Sizes are preserved by position for lockers that already existed;
  /// hardware has no concept of small/medium/large, so it never overrides
  /// a size an admin already assigned. Any *new* lockers the hardware
  /// reports (count increased) default to `'medium'`. If the hardware
  /// reports fewer lockers than configured, the trailing entries are
  /// dropped. A no-op if the count already matches.
  ///
  /// Unlike [setLockerMapping], this takes a count straight from hardware
  /// rather than free-text admin input, so there's no comma-string
  /// validation step — a non-positive count is simply ignored rather than
  /// wiping out the existing configuration.
  Future<void> reconcileLockerMappingToHardwareCount(int hardwareCount) async {
    if (hardwareCount <= 0) return;

    final reconciled = <LockerMappingEntry>[
      for (var i = 0; i < hardwareCount; i++)
        LockerMappingEntry(
          id: i + 1,
          size: i < _lockerMapping.length ? _lockerMapping[i].size : 'medium',
        ),
    ];

    final unchanged = reconciled.length == _lockerMapping.length &&
        List.generate(reconciled.length,
            (i) => reconciled[i].size == _lockerMapping[i].size).every((e) => e);
    if (unchanged) return;

    _lockerMapping = reconciled;
    await _persistConfig();
    logger.i(
      'Locker mapping reconciled to hardware-reported count '
      '($hardwareCount locker(s)).',
    );
  }

  /// `true` puts every window in kiosk mode (frameless, fullscreen) — see
  /// `WindowService.configureAndShow`. Takes effect the next time a
  /// window is (re)created, not retroactively on an already-open window.
  bool get kioskMode => _kioskMode;

  Future<void> setKioskMode(bool value) async {
    _kioskMode = value;
    await _persistConfig();
    logger.i('Kiosk mode updated to: $value');
  }

  /// The real, on-disk directory the *physical unit's* `cvmain` process
  /// reads `auth.json`/`mq.json` from (with `mq.json` in an `mq`
  /// subdirectory: `<dir>/mq/mq.json`). Defaults to
  /// [_defaultCvmainConfigDir] (`/home/pi/cv/cvmain/config`) — confirmed
  /// by SSHing into this deployment's actual unit, not a guess, since this
  /// app only targets that one known Pi. Still editable on the Unit
  /// Registration page (clear the field to blank to skip mirroring
  /// entirely) in case a future unit uses a different path.
  ///
  /// This is a different concept from [lockerAddress]: that's where the
  /// *gRPC* server is (already required for any locker control); this is
  /// where cvmain's *own config files* live on that same machine's
  /// filesystem (only needed for the unit to show "online" in
  /// VaultGroup — see the Unit Registration page). Restarting cvmain so
  /// it actually picks up a freshly-mirrored file is a manual step done
  /// over SSH (`sudo pkill -f cvmain_rs` — its supervisor script relaunches
  /// it within a few seconds) — deliberately not automated by this app.
  String get cvmainConfigDir => _cvmainConfigDir;

  Future<void> setCvmainConfigDir(String value) async {
    _cvmainConfigDir = value.trim();
    await _persistConfig();
    logger.i('cvmain config directory updated to: "$_cvmainConfigDir"');
  }

  /// Reset all configuration to defaults
  Future<void> reset() async {
    _adminPin = _defaultAdminPin;
    _dropOffPin = _defaultDropOffPin;
    _smsTemplate = _defaultSmsTemplate;
    _lockerMapping = _defaultLockerMapping;
    _lockerAddress = _defaultLockerAddress;
    _lockerBackend = _defaultLockerBackend;
    _kioskMode = _defaultKioskMode;
    _cvmainConfigDir = _defaultCvmainConfigDir;
    _pairedLockerMode = _defaultPairedLockerMode;
    _lockerPairs = _defaultLockerPairs;
    await _persistConfig();
    logger.i('ConfigService reset to defaults');
  }

  /// Check if ConfigService is initialized
  bool get isInitialized => _initialized;
}
