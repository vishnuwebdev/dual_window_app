import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utilities/app_paths.dart';
import '../utilities/logging.dart';

/// One physical locker slot's id + size, as stored in `config.json`'s
/// `locker_mapping` array. Mirrors the Android app's `lockerConfig.json`
/// (`Locker(id, size)`, written by `LockerService.updateLockerConfig`) —
/// kept as a tiny standalone type here (rather than reusing
/// `core/mock/models.dart`'s `Locker`) so `ConfigService` doesn't depend on
/// the mock layer it's meant to outlive; `MockKioskRepository` converts
/// these into its own `Locker` objects when it syncs.
///
/// In `pairedLockerMode`, this list still holds *every* physical door
/// across *every* slave board — nothing about a single entry says which
/// board it's on or whether it's a drop-off or collection door. Which
/// lockers are paired together (and which side of a pair is which) is a
/// separate, freely admin-chosen mapping — see
/// [ConfigService.lockerPairMappings]. Every locker is identified purely
/// by its position (1-based) in this flat list — there is no board-level
/// grouping concept anymore (an earlier "board layout" feature that
/// derived per-board labels was removed; every screen just uses the plain
/// locker number now, whether it came from admin-entered config or a
/// hardware fetch).
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

/// One admin-chosen drop-off/collection locker pairing — see
/// `ConfigService.lockerPairMappings`. Unlike an earlier version of this
/// feature, pairing is *not* derived automatically from board layout
/// anymore: an admin freely picks any two not-yet-used lockers and links
/// them, in whatever combination matches the real wiring (which doesn't
/// have to follow "board N's door K pairs with board N+1's door K" — see
/// the confirmed example pairing 9↔3 and 8↔10, which cross boards at
/// different positions).
class LockerPairMapping {
  const LockerPairMapping({
    required this.dropoffLockerId,
    required this.collectionLockerId,
    this.customLockerId,
  });

  /// The locker id a customer drops a parcel into — this is the id
  /// `MockKioskRepository.getDropoffCandidateLockers` offers as a pickable
  /// drop-off target.
  final int dropoffLockerId;

  /// The linked locker id that physically opens when that parcel is
  /// collected.
  final int collectionLockerId;

  /// Optional display-only id an admin assigns to this *pair*, shown to the
  /// customer instead of [dropoffLockerId]/[collectionLockerId] on the
  /// Drop-off/Collection journey screens — see
  /// `MockKioskRepository.lockerDisplayLabel`. Purely cosmetic: every other
  /// piece of logic (which physical door actually unlocks, `db.json`,
  /// admin's Locker Management table, gRPC's own locker_num, audit logs)
  /// keeps using the real [dropoffLockerId]/[collectionLockerId] exactly as
  /// before — this field is never read anywhere except that one display
  /// lookup. `null` (the default) means "no custom id set," in which case
  /// the real locker id is still shown, unchanged from before this field
  /// existed.
  final int? customLockerId;

  Map<String, dynamic> toJson() => {
        'dropoffLockerId': dropoffLockerId,
        'collectionLockerId': collectionLockerId,
        if (customLockerId != null) 'customLockerId': customLockerId,
      };

  static LockerPairMapping? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final dropoffLockerId = raw['dropoffLockerId'];
    final collectionLockerId = raw['collectionLockerId'];
    if (dropoffLockerId is! int || collectionLockerId is! int) return null;
    // Missing from an older config.json (written before this field
    // existed) or not an int — both just mean "no custom id," not a
    // parse failure, so the whole pairing isn't rejected over it.
    final rawCustomLockerId = raw['customLockerId'];
    final customLockerId =
        rawCustomLockerId is int ? rawCustomLockerId : null;
    return LockerPairMapping(
      dropoffLockerId: dropoffLockerId,
      collectionLockerId: collectionLockerId,
      customLockerId: customLockerId,
    );
  }
}

/// Single source of truth for every setting admins can change from the
/// Admin menu, backed by six local files instead of one monolithic
/// `config.json` (mirroring how the Android app kept `admin.json` /
/// `lockerConfig.json` on-device rather than bundled, just split further).
///
/// Admin PIN, drop-off PIN, and SMS template each live in their own plain
/// text file (just the raw value, nothing else — see [AppPaths.adminPwFile]
/// / [AppPaths.dropoffPinFile] / [AppPaths.smsTemplateFile]); locker sizes
/// and locker pair mapping each get their own JSON file
/// ([AppPaths.lockerSizesFile] / [AppPaths.lockerPairMappingFile]).
/// Everything else (locker address/backend, kiosk mode, cvmain/cvmaster
/// config dirs, paired locker mode) stays together in `config.json`, same
/// as before. The split is strict: those five settings are never read
/// from or written to `config.json`, even as a fallback — only their own
/// dedicated file is ever touched for them. A pre-split `config.json`
/// still holding one of those five keys just has it ignored; the key is
/// dropped the next time `config.json` itself gets rewritten (see
/// [_loadConfigFile]), but its value is never migrated in.
///
/// All six files are read once at startup (see [initialize], called from
/// `main.dart`), then kept in memory. Every setter below re-validates its
/// input against the same rule the UI enforces, and only writes the new
/// value back to disk — leaving a readable record of the current settings
/// — if it passes. A rejected value never reaches a file or the in-memory
/// state. [_persistConfig] always rewrites all six files together on any
/// change, the same "just rewrite everything" approach the single-file
/// version of this class already used — simpler and more predictable than
/// trying to track which one specific file actually needs updating.
///
/// Each window (Admin/Customer) runs its own Flutter engine/isolate, so a
/// setting changed in one window isn't automatically visible in the
/// other's in-memory copy. `initialize()` also starts a filesystem watch
/// on all six files (see [_startWatching]), sharing one debounce so a
/// burst of changes across several of them collapses into a single
/// reload — so a change saved in one window is picked up and reflected in
/// the other within moments, without needing a restart.
///
/// Extends `ChangeNotifier` so dependents (`MockKioskRepository`'s locker
/// inventory, and any widget listening directly) can react live both to
/// local changes and to changes reloaded from an external write.
class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();

  bool _initialized = false;

  // --- config.json keys and defaults ----------------------------------
  //
  // Only these six keys are ever read from or written to config.json.
  // admin_pin/drop_off_pin/sms_template/locker_mapping/
  // locker_pair_mappings are NOT read from or written to config.json
  // anymore, even as a fallback — each is exclusively backed by its own
  // file (see AppPaths). If an old config.json still has one of those
  // five keys sitting in it, it's simply ignored; it gets dropped the
  // next time config.json itself is rewritten (see [_loadConfigFile]'s
  // `configNeedsRewrite`), but its value is never read into memory.
  static const String _kLockerAddress = 'locker_address';
  static const String _kLockerBackend = 'locker_backend';
  static const String _kKioskMode = 'kiosk_mode';
  static const String _kCvmainConfigDir = 'cvmain_config_dir';
  static const String _kCvmasterConfigDir = 'cvmaster_config_dir';
  static const String _kPairedLockerMode = 'paired_locker_mode';

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
  static const String _defaultLockerAddress = '127.0.0.1:7777';

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
  /// cnc_dual_screen, no Android app involved). Still editable via the
  /// Unit Registration page if a different unit ever uses a different
  /// path.
  static const String _defaultCvmainConfigDir = '/home/pi/cv/cvmain/config';

  /// UNCONFIRMED — cvmaster's real on-disk path was never verified over
  /// SSH the way [_defaultCvmainConfigDir] was (see that field's doc
  /// comment). This is a guess based on [_defaultCvmainConfigDir]'s own
  /// shape (`cv/cvmain/config` -> `cv/cvmaster/config`), used only as a
  /// starting point in the "Physical unit sync" admin UI — correct it
  /// there (Unit Registration page) once the real path is confirmed on
  /// this deployment's Pi, the same way [_defaultCvmainConfigDir] already
  /// was. See `SettingsSyncService`'s class doc comment for what this
  /// feeds into.
  static const String _defaultCvmasterConfigDir = '/home/pi/cv/cvmaster/config';

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
  /// board" physical topology described on [lockerPairMappings].
  static const bool _defaultPairedLockerMode = false;

  static const List<LockerPairMapping> _defaultLockerPairMappings = [];

  String _adminPin = _defaultAdminPin;
  String _dropOffPin = _defaultDropOffPin;
  String _smsTemplate = _defaultSmsTemplate;
  List<LockerMappingEntry> _lockerMapping = _defaultLockerMapping;
  String _lockerAddress = _defaultLockerAddress;
  String _lockerBackend = _defaultLockerBackend;
  bool _kioskMode = _defaultKioskMode;

  String _cvmainConfigDir = _defaultCvmainConfigDir;
  String _cvmasterConfigDir = _defaultCvmasterConfigDir;

  bool _pairedLockerMode = _defaultPairedLockerMode;
  List<LockerPairMapping> _lockerPairMappings = _defaultLockerPairMappings;

  final List<StreamSubscription<FileSystemEvent>> _watchSubscriptions = [];

  /// How long to wait for the filesystem to go quiet before actually
  /// reloading off a watch event — see [_startWatching].
  static const _reloadDebounce = Duration(seconds: 2, milliseconds: 500);
  Timer? _reloadDebounceTimer;

  ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  File get _configFile => AppPaths.configFile;

  /// Initialize ConfigService (call this in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    // `_configFile` resolves via `AppPaths` — log it once so a
    // silently-swallowed write failure (e.g. this path being outside what
    // the OS lets the app write to) is easy to spot in the console instead
    // of just missing from config.json.
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
  ///
  /// Debounced (see [_reloadDebounce]) rather than reloading on every raw
  /// event: every setter's own [_persistConfig] write lands back on this
  /// same watch (a "self-echo"), and on Linux a single `writeAsString` can
  /// itself surface as more than one filesystem event. Without debouncing,
  /// a single Save with several fields changing (e.g. `ConfigurationPage`
  /// saving the mapping and pairing back to back) could
  /// trigger a handful of redundant reloads — each one re-running every
  /// listener's own work (`MockKioskRepository` rebuilding its whole
  /// locker/pairing state, `LockerGrpcService` checking whether to
  /// reconnect) for data that hasn't actually changed again since the
  /// previous reload. Collapsing a burst of events into one reload after
  /// the file goes quiet keeps that work to once per real change, which
  /// matters more on slower storage (e.g. an SD card) than it would on a
  /// dev machine's SSD.
  void _startWatching() {
    final filesToWatch = <File>[
      _configFile,
      AppPaths.adminPwFile,
      AppPaths.dropoffPinFile,
      AppPaths.smsTemplateFile,
      AppPaths.lockerSizesFile,
      AppPaths.lockerPairMappingFile,
    ];
    for (final file in filesToWatch) {
      try {
        _watchSubscriptions.add(file.watch().listen((_) {
          _reloadDebounceTimer?.cancel();
          _reloadDebounceTimer =
              Timer(_reloadDebounce, _reloadFromDiskAndNotify);
        }));
      } catch (e) {
        logger.w('Could not watch ${file.path} for external changes: $e');
      }
    }
  }

  Future<void> _reloadFromDiskAndNotify() async {
    await _loadConfigFile();
    notifyListeners();
  }

  @override
  void dispose() {
    _reloadDebounceTimer?.cancel();
    for (final sub in _watchSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Loads every setting from its own file — `config.json` for the six
  /// that stayed there, and the five dedicated files (see `AppPaths`) for
  /// the rest — creating any that don't exist yet with defaults. Strictly
  /// separated: `config.json` is only ever read for its six keys, and the
  /// five split-out settings are only ever read from their own dedicated
  /// file — never from `config.json`, not even as a fallback. A value
  /// still sitting under an old key in `config.json` (e.g. `admin_pin`
  /// from before this split) is simply never looked at.
  ///
  /// Deliberately more fault-isolated than the old single-file version:
  /// each of the five split-out settings is read independently (see
  /// [_loadPlainTextSetting]/[_loadLockerMapping]/
  /// [_loadLockerPairMappings]), so a corrupted `locker_sizes.json`, say,
  /// falls back to defaults and gets rewritten on its own without
  /// affecting `admin_pw`/`sms_template`/anything else.
  Future<void> _loadConfigFile() async {
    try {
      var configNeedsRewrite = false;

      final file = _configFile;
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _lockerAddress =
            json[_kLockerAddress] as String? ?? _defaultLockerAddress;
        _cvmainConfigDir =
            json[_kCvmainConfigDir] as String? ?? _defaultCvmainConfigDir;
        _cvmasterConfigDir =
            json[_kCvmasterConfigDir] as String? ?? _defaultCvmasterConfigDir;

        // Only these 6 keys belong in config.json now. Any other key
        // present (e.g. a pre-split config.json's admin_pin/drop_off_pin/
        // sms_template/locker_mapping/locker_pair_mappings) is never read
        // — its value is ignored — but its presence does mean config.json
        // needs rewriting to drop it down to just these 6 keys.
        configNeedsRewrite = json.length != 6 ||
            !json.containsKey(_kLockerAddress) ||
            !json.containsKey(_kLockerBackend) ||
            !json.containsKey(_kKioskMode) ||
            !json.containsKey(_kCvmainConfigDir) ||
            !json.containsKey(_kCvmasterConfigDir) ||
            !json.containsKey(_kPairedLockerMode);

        final rawPairedMode = json[_kPairedLockerMode];
        _pairedLockerMode =
            rawPairedMode is bool ? rawPairedMode : _defaultPairedLockerMode;
        if (rawPairedMode is! bool) configNeedsRewrite = true;

        final rawKioskMode = json[_kKioskMode];
        _kioskMode = rawKioskMode is bool ? rawKioskMode : _defaultKioskMode;
        if (rawKioskMode is! bool) configNeedsRewrite = true;

        final rawBackend = json[_kLockerBackend];
        if (rawBackend is String && _validLockerBackends.contains(rawBackend)) {
          _lockerBackend = rawBackend;
        } else {
          // Missing (older config.json) or invalid — fall back to 'mock'
          // rather than silently trying to reach hardware nobody configured.
          _lockerBackend = _defaultLockerBackend;
          configNeedsRewrite = true;
        }
      } else {
        configNeedsRewrite = true;
      }

      final adminPinResult = await _loadPlainTextSetting(
        AppPaths.adminPwFile,
        fallback: _defaultAdminPin,
      );
      _adminPin = adminPinResult.value;
      var filesNeedRewrite = adminPinResult.needsRewrite;

      final dropOffPinResult = await _loadPlainTextSetting(
        AppPaths.dropoffPinFile,
        fallback: _defaultDropOffPin,
      );
      _dropOffPin = dropOffPinResult.value;
      if (dropOffPinResult.needsRewrite) filesNeedRewrite = true;

      final smsTemplateResult = await _loadPlainTextSetting(
        AppPaths.smsTemplateFile,
        fallback: _defaultSmsTemplate,
      );
      _smsTemplate = smsTemplateResult.value;
      if (smsTemplateResult.needsRewrite) filesNeedRewrite = true;

      final lockerMappingResult = await _loadLockerMapping();
      _lockerMapping = lockerMappingResult.value;
      if (lockerMappingResult.needsRewrite) filesNeedRewrite = true;

      final pairMappingResult = await _loadLockerPairMappings();
      _lockerPairMappings = pairMappingResult.value;
      if (pairMappingResult.needsRewrite) filesNeedRewrite = true;

      if (configNeedsRewrite || filesNeedRewrite) {
        await _persistConfig();
      }
    } catch (e) {
      logger.w('Failed to load config, falling back to defaults: $e');
    }
  }

  /// Reads a plain-text setting — just [file]'s raw content, trimmed — for
  /// `admin_pw`/`dropoff_pin`/`sms_template`. [file] is the *only* source
  /// read here — no fallback to `config.json` — so if [file] doesn't
  /// exist or is empty, this returns [fallback] straight away.
  /// `needsRewrite` is true whenever the returned value didn't come from
  /// [file] itself — i.e. [file] needs to be (re)written so it actually
  /// holds this value going forward.
  Future<({String value, bool needsRewrite})> _loadPlainTextSetting(
    File file, {
    required String fallback,
  }) async {
    try {
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) {
          return (value: content, needsRewrite: false);
        }
      }
    } catch (e) {
      logger.w('Failed to read ${file.path}: $e');
    }
    return (value: fallback, needsRewrite: true);
  }

  /// Same idea as [_loadPlainTextSetting], for `locker_sizes.json` — reads
  /// the JSON array directly from [AppPaths.lockerSizesFile] (a top-level
  /// array, not nested under a `locker_mapping` key the way it was inside
  /// `config.json`). That file is the only source read here — no fallback
  /// to `config.json` — so a missing/empty/malformed file just falls back
  /// straight to [_defaultLockerMapping].
  Future<({List<LockerMappingEntry> value, bool needsRewrite})>
      _loadLockerMapping() async {
    dynamic raw;
    try {
      final file = AppPaths.lockerSizesFile;
      if (await file.exists()) {
        raw = jsonDecode(await file.readAsString());
      }
    } catch (e) {
      logger.w('Failed to read ${AppPaths.lockerSizesFile.path}: $e');
    }

    if (raw == null) {
      return (value: _defaultLockerMapping, needsRewrite: true);
    }

    if (raw is List) {
      final parsed = raw.map(LockerMappingEntry.tryFromJson).toList();
      if (parsed.isNotEmpty && parsed.every((e) => e != null)) {
        return (
          value: parsed.cast<LockerMappingEntry>(),
          needsRewrite: false,
        );
      }
      // Malformed entries (bad id/size) — fall back to the default shape
      // and rewrite the file so it's valid going forward.
      return (value: _defaultLockerMapping, needsRewrite: true);
    }

    // Old bare count/string format (e.g. "6") — not something this file
    // should ever hold; fall back and rewrite it to the structured shape.
    logger.w(
      'locker_sizes.json had an unexpected shape ($raw) — falling back to '
      'defaults.',
    );
    return (value: _defaultLockerMapping, needsRewrite: true);
  }

  /// Same idea as [_loadLockerMapping], for `locker_pair_mapping.json` —
  /// that file is the only source read here, no fallback to `config.json`.
  Future<({List<LockerPairMapping> value, bool needsRewrite})>
      _loadLockerPairMappings() async {
    dynamic raw;
    try {
      final file = AppPaths.lockerPairMappingFile;
      if (await file.exists()) {
        raw = jsonDecode(await file.readAsString());
      }
    } catch (e) {
      logger.w('Failed to read ${AppPaths.lockerPairMappingFile.path}: $e');
    }

    if (raw == null) {
      return (value: _defaultLockerPairMappings, needsRewrite: true);
    }

    if (raw is List) {
      if (raw.isEmpty) {
        return (value: _defaultLockerPairMappings, needsRewrite: false);
      }
      final parsed = raw.map(LockerPairMapping.tryFromJson).toList();
      if (parsed.every((e) => e != null)) {
        return (
          value: parsed.cast<LockerPairMapping>(),
          needsRewrite: false,
        );
      }
      // Malformed entries — fall back to empty rather than risk acting on
      // a half-parsed pairing (unlocking the wrong physical door).
      logger.w(
        'locker_pair_mapping.json has malformed entries — falling back to '
        'empty.',
      );
    }
    return (value: _defaultLockerPairMappings, needsRewrite: true);
  }

  /// Rewrites all six files this class owns — `config.json` (the six
  /// settings that stayed there) plus the five dedicated files — every
  /// time any setting changes, the same "just rewrite everything" approach
  /// the single-file version of this class already used for `config.json`
  /// alone. Simpler and more predictable than tracking exactly which one
  /// file a given setter actually needs to touch.
  Future<void> _persistConfig() async {
    await AppPaths.ensureDirectoryExists();

    await _configFile.writeAsString(const JsonEncoder.withIndent('  ').convert({
      _kLockerAddress: _lockerAddress,
      _kLockerBackend: _lockerBackend,
      _kKioskMode: _kioskMode,
      _kCvmainConfigDir: _cvmainConfigDir,
      _kCvmasterConfigDir: _cvmasterConfigDir,
      _kPairedLockerMode: _pairedLockerMode,
    }));

    await AppPaths.adminPwFile.writeAsString(_adminPin);
    await AppPaths.dropoffPinFile.writeAsString(_dropOffPin);
    await AppPaths.smsTemplateFile.writeAsString(_smsTemplate);
    await AppPaths.lockerSizesFile.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(_lockerMapping.map((e) => e.toJson()).toList()),
    );
    await AppPaths.lockerPairMappingFile.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(_lockerPairMappings.map((e) => e.toJson()).toList()),
    );

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
  ///
  /// In [pairedLockerMode], this is still the *complete* list of every
  /// physical door across every slave board — just a flat, ordered list of
  /// sizes with no board-grouping concept. Which doors are linked to which
  /// (drop-off side <-> collection side) is entirely up to
  /// [lockerPairMappings]'s freely admin-chosen pairing; nothing here
  /// tracks which physical board a given position belongs to.
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

  /// Validates a proposed set of drop-off/collection locker pairings (see
  /// [LockerPairMapping]) against the *current* locker mapping's total
  /// door count — the rules an admin's freely-chosen pairing must satisfy
  /// before `MockKioskRepository` will act on it:
  ///
  /// - Every id referenced must actually exist in [lockerMapping].
  /// - A locker can never be paired with itself.
  /// - A locker can appear in at most one pair, in either role — a
  ///   duplicate would make it ambiguous which pairing actually applies
  ///   when a customer drops something off there.
  /// - Every locker must end up paired, with exactly one exception: if
  ///   [totalLockers] is odd, one locker is allowed to stay unpaired
  ///   (there's no way to pair an odd number of lockers up completely).
  ///   Any *more* than that one leftover is rejected.
  /// - A [LockerPairMapping.customLockerId], if set, must be unique across
  ///   pairs — two different physical pairs showing the same custom label
  ///   to customers would be ambiguous (which one does "Locker 5" mean?).
  static String? validateLockerPairMappings(
      List<LockerPairMapping> pairs, int totalLockers) {
    if (totalLockers == 0) {
      return 'Add lockers to the locker mapping above first.';
    }

    final used = <int>{};
    final usedCustomIds = <int>{};
    for (final pair in pairs) {
      if (pair.dropoffLockerId < 1 || pair.dropoffLockerId > totalLockers) {
        return 'Locker ${pair.dropoffLockerId} does not exist (only '
            '$totalLockers locker(s) configured).';
      }
      if (pair.collectionLockerId < 1 ||
          pair.collectionLockerId > totalLockers) {
        return 'Locker ${pair.collectionLockerId} does not exist (only '
            '$totalLockers locker(s) configured).';
      }
      if (pair.dropoffLockerId == pair.collectionLockerId) {
        return 'Locker ${pair.dropoffLockerId} cannot be paired with itself.';
      }
      if (!used.add(pair.dropoffLockerId)) {
        return 'Locker ${pair.dropoffLockerId} is used in more than one pair.';
      }
      if (!used.add(pair.collectionLockerId)) {
        return 'Locker ${pair.collectionLockerId} is used in more than one pair.';
      }
      final customLockerId = pair.customLockerId;
      if (customLockerId != null && !usedCustomIds.add(customLockerId)) {
        return 'Custom locker id $customLockerId is used by more than one '
            'pair.';
      }
    }

    final maxUnmapped = totalLockers.isOdd ? 1 : 0;
    final unmapped = totalLockers - used.length;
    if (unmapped > maxUnmapped) {
      return totalLockers.isOdd
          ? 'All lockers must be paired except one (odd total of '
              '$totalLockers) — currently ${used.length} of $totalLockers '
              'are paired.'
          : 'All $totalLockers lockers must be paired — currently '
              '${used.length} are paired.';
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
  /// `MockKioskRepository` syncs its locker list from. In paired mode this
  /// is every physical door on every board (see [validateLockerMapping]'s
  /// doc comment), not just the drop-off side.
  List<LockerMappingEntry> get lockerMapping =>
      List.unmodifiable(_lockerMapping);

  /// The same data as [lockerMapping], flattened to the editable
  /// comma-separated shorthand (`"small,small,medium,..."`) for display in
  /// `ConfigurationPage`'s text field.
  String get lockerMappingText => _lockerMapping.map((e) => e.size).join(',');

  /// Whether "paired slave board" mode is on: every locker has a matching
  /// linked locker (see [lockerPairMappings]) that opens on collection
  /// instead of the one that opened on drop-off, and both count as
  /// occupied together. When true, `MockKioskRepository`:
  ///
  /// - Only offers [lockerPairMappings]'s drop-off-role lockers as
  ///   drop-off targets (never the collection-role side).
  /// - Won't allow *any* drop-off at all until [isLockerPairingComplete] —
  ///   an incomplete pairing means there's no known door to open on
  ///   collection for whatever a customer just dropped off.
  /// - Freezes both linked ids onto the parcel record at drop-off time
  ///   (`LockerItem.lockerId`/`.collectionLockerId`).
  bool get pairedLockerMode => _pairedLockerMode;

  /// The admin-chosen drop-off/collection locker pairing — freely editable
  /// (any not-yet-used locker can be linked to any other), not derived
  /// from board layout. See [LockerPairMapping] and
  /// `MockKioskRepository._applyExplicitPairMappings`, which is the only
  /// thing that reads this. Only meaningful when [pairedLockerMode] is
  /// true; empty otherwise.
  List<LockerPairMapping> get lockerPairMappings =>
      List.unmodifiable(_lockerPairMappings);

  /// True when every configured locker is either paired, or is the single
  /// allowed leftover if [lockerMapping] has an odd total — i.e.
  /// [lockerPairMappings] passes [validateLockerPairMappings] as-is right
  /// now. Always true outside [pairedLockerMode] (nothing to gate).
  /// `MockKioskRepository.getDropoffCandidateLockers` refuses to offer
  /// *any* locker for drop-off while this is false, per the confirmed
  /// requirement that drop-off only opens up once pairing is fully done.
  bool get isLockerPairingComplete {
    if (!_pairedLockerMode) return true;
    return validateLockerPairMappings(
            _lockerPairMappings, _lockerMapping.length) ==
        null;
  }

  Future<void> setPairedLockerMode(bool value) async {
    _pairedLockerMode = value;
    await _persistConfig();
    logger.i('Paired locker mode updated to: $value');
  }

  /// Validates and persists a freely admin-chosen locker pairing (see
  /// [validateLockerPairMappings]) — every pair is checked before *any*
  /// of them are written, so a partially-valid list never reaches
  /// `config.json` and, transitively, never reaches
  /// `MockKioskRepository`'s unlock logic.
  Future<String?> setLockerPairMappings(List<LockerPairMapping> pairs) async {
    final error = validateLockerPairMappings(pairs, _lockerMapping.length);
    if (error != null) return error;
    _lockerPairMappings = List.unmodifiable(pairs);
    await _persistConfig();
    logger.i(
        'Locker pair mappings updated: ${_lockerPairMappings.length} pair(s).');
    return null;
  }

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

    // A shorter mapping can leave `_lockerPairMappings` pointing at ids
    // that no longer exist — drop any pair referencing one rather than
    // risk `MockKioskRepository` acting on a stale pairing.
    final maxId = _lockerMapping.length;
    final validPairs = _lockerPairMappings
        .where(
            (p) => p.dropoffLockerId <= maxId && p.collectionLockerId <= maxId)
        .toList();
    if (validPairs.length != _lockerPairMappings.length) {
      logger.i(
        'Pruned ${_lockerPairMappings.length - validPairs.length} locker '
        'pair mapping(s) that referenced ids beyond the new locker count '
        '($maxId).',
      );
      _lockerPairMappings = validPairs;
    }

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
                (i) => reconciled[i].size == _lockerMapping[i].size)
            .every((e) => e);
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
  /// VaultGroup — see the Unit Registration page). This app only ever
  /// copies `auth.json`/`mq.json` into this directory
  /// (`UnitRegistrationService.mirrorToCvmainConfig`); a separate process
  /// on the unit watches it and restarts cvmain so it picks up the new
  /// files — this app doesn't do that itself.
  String get cvmainConfigDir => _cvmainConfigDir;

  Future<void> setCvmainConfigDir(String value) async {
    _cvmainConfigDir = value.trim();
    await _persistConfig();
    logger.i('cvmain config directory updated to: "$_cvmainConfigDir"');
  }

  /// The real, on-disk directory the *physical unit's* `cvmaster` process
  /// keeps its own `config.json` in — the local counterpart to
  /// [cvmainConfigDir], used by `SettingsSyncService` to fill the
  /// `cvmaster_config` field it pushes to the cloud. UNCONFIRMED — see
  /// [_defaultCvmasterConfigDir]'s doc comment; correct this on the Unit
  /// Registration page once the real path is verified on this deployment.
  String get cvmasterConfigDir => _cvmasterConfigDir;

  Future<void> setCvmasterConfigDir(String value) async {
    _cvmasterConfigDir = value.trim();
    await _persistConfig();
    logger.i('cvmaster config directory updated to: "$_cvmasterConfigDir"');
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
    _cvmasterConfigDir = _defaultCvmasterConfigDir;
    _pairedLockerMode = _defaultPairedLockerMode;
    _lockerPairMappings = _defaultLockerPairMappings;
    await _persistConfig();
    logger.i('ConfigService reset to defaults');
  }

  /// Check if ConfigService is initialized
  bool get isInitialized => _initialized;
}
