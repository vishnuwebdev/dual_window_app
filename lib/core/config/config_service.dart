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

  String _adminPin = _defaultAdminPin;
  String _dropOffPin = _defaultDropOffPin;
  String _smsTemplate = _defaultSmsTemplate;
  List<LockerMappingEntry> _lockerMapping = _defaultLockerMapping;
  String _lockerAddress = _defaultLockerAddress;
  String _lockerBackend = _defaultLockerBackend;
  bool _kioskMode = _defaultKioskMode;

  String _cvmainConfigDir = _defaultCvmainConfigDir;

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

        var needsRewrite = json.length != 8 ||
            !json.containsKey(_kAdminPin) ||
            !json.containsKey(_kDropOffPin) ||
            !json.containsKey(_kSmsTemplate) ||
            !json.containsKey(_kLockerMapping) ||
            !json.containsKey(_kLockerAddress) ||
            !json.containsKey(_kLockerBackend) ||
            !json.containsKey(_kKioskMode) ||
            !json.containsKey(_kCvmainConfigDir);

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
    await _persistConfig();
    logger.i('ConfigService reset to defaults');
  }

  /// Check if ConfigService is initialized
  bool get isInitialized => _initialized;
}
