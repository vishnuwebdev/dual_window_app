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
///
/// In `pairedLockerMode`, this list still holds *every* physical door
/// across *every* slave board — nothing about a single entry says which
/// board it's on or whether it's a drop-off or collection door. Which
/// lockers are paired together (and which side of a pair is which) is a
/// separate, freely admin-chosen mapping — see
/// [ConfigService.lockerPairMappings]. [ConfigService.boardLockerCounts]
/// is unrelated to pairing now; it only drives the "Board N, Locker L"
/// display label shown to customers/admins (see
/// `MockKioskRepository.lockerDisplayLabel`).
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
  });

  /// The locker id a customer drops a parcel into — this is the id
  /// `MockKioskRepository.getDropoffCandidateLockers` offers as a pickable
  /// drop-off target.
  final int dropoffLockerId;

  /// The linked locker id that physically opens when that parcel is
  /// collected.
  final int collectionLockerId;

  Map<String, dynamic> toJson() => {
        'dropoffLockerId': dropoffLockerId,
        'collectionLockerId': collectionLockerId
      };

  static LockerPairMapping? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final dropoffLockerId = raw['dropoffLockerId'];
    final collectionLockerId = raw['collectionLockerId'];
    if (dropoffLockerId is! int || collectionLockerId is! int) return null;
    return LockerPairMapping(
      dropoffLockerId: dropoffLockerId,
      collectionLockerId: collectionLockerId,
    );
  }
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
  static const String _kBoardLockerCounts = 'board_locker_counts';
  static const String _kLockerPairMappings = 'locker_pair_mappings';

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
  /// board" physical topology described on [boardLockerCounts].
  static const bool _defaultPairedLockerMode = false;

  static const List<int> _defaultBoardLockerCounts = [];

  static const List<LockerPairMapping> _defaultLockerPairMappings = [];

  String _adminPin = _defaultAdminPin;
  String _dropOffPin = _defaultDropOffPin;
  String _smsTemplate = _defaultSmsTemplate;
  List<LockerMappingEntry> _lockerMapping = _defaultLockerMapping;
  String _lockerAddress = _defaultLockerAddress;
  String _lockerBackend = _defaultLockerBackend;
  bool _kioskMode = _defaultKioskMode;

  String _cvmainConfigDir = _defaultCvmainConfigDir;

  bool _pairedLockerMode = _defaultPairedLockerMode;
  List<int> _boardLockerCounts = _defaultBoardLockerCounts;
  List<LockerPairMapping> _lockerPairMappings = _defaultLockerPairMappings;

  StreamSubscription<FileSystemEvent>? _watchSubscription;

  /// How long to wait for the filesystem to go quiet before actually
  /// reloading `config.json` off a watch event — see [_startWatching].
  static const _reloadDebounce = Duration(seconds: 2, milliseconds: 500);
  Timer? _reloadDebounceTimer;

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
  ///
  /// Debounced (see [_reloadDebounce]) rather than reloading on every raw
  /// event: every setter's own [_persistConfig] write lands back on this
  /// same watch (a "self-echo"), and on Linux a single `writeAsString` can
  /// itself surface as more than one filesystem event. Without debouncing,
  /// a single Save with several fields changing (e.g. `ConfigurationPage`
  /// saving the mapping, board counts, and pairing back to back) could
  /// trigger a handful of redundant reloads — each one re-running every
  /// listener's own work (`MockKioskRepository` rebuilding its whole
  /// locker/pairing state, `LockerGrpcService` checking whether to
  /// reconnect) for data that hasn't actually changed again since the
  /// previous reload. Collapsing a burst of events into one reload after
  /// the file goes quiet keeps that work to once per real change, which
  /// matters more on slower storage (e.g. an SD card) than it would on a
  /// dev machine's SSD.
  void _startWatching() {
    try {
      _watchSubscription = _configFile.watch().listen((_) {
        _reloadDebounceTimer?.cancel();
        _reloadDebounceTimer =
            Timer(_reloadDebounce, _reloadFromDiskAndNotify);
      });
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
    _reloadDebounceTimer?.cancel();
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
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _adminPin = json[_kAdminPin] as String? ?? _defaultAdminPin;
        _dropOffPin = json[_kDropOffPin] as String? ?? _defaultDropOffPin;
        _smsTemplate = json[_kSmsTemplate] as String? ?? _defaultSmsTemplate;
        _lockerAddress =
            json[_kLockerAddress] as String? ?? _defaultLockerAddress;
        _cvmainConfigDir =
            json[_kCvmainConfigDir] as String? ?? _defaultCvmainConfigDir;

        var needsRewrite = json.length != 11 ||
            !json.containsKey(_kAdminPin) ||
            !json.containsKey(_kDropOffPin) ||
            !json.containsKey(_kSmsTemplate) ||
            !json.containsKey(_kLockerMapping) ||
            !json.containsKey(_kLockerAddress) ||
            !json.containsKey(_kLockerBackend) ||
            !json.containsKey(_kKioskMode) ||
            !json.containsKey(_kCvmainConfigDir) ||
            !json.containsKey(_kPairedLockerMode) ||
            !json.containsKey(_kBoardLockerCounts) ||
            !json.containsKey(_kLockerPairMappings);

        final rawPairedMode = json[_kPairedLockerMode];
        _pairedLockerMode =
            rawPairedMode is bool ? rawPairedMode : _defaultPairedLockerMode;
        if (rawPairedMode is! bool) needsRewrite = true;

        final rawBoardCounts = json[_kBoardLockerCounts];
        if (rawBoardCounts is List && rawBoardCounts.every((e) => e is int)) {
          _boardLockerCounts = rawBoardCounts.cast<int>();
        } else {
          _boardLockerCounts = _defaultBoardLockerCounts;
          if (rawBoardCounts != null) needsRewrite = true;
        }

        final rawPairMappings = json[_kLockerPairMappings];
        if (rawPairMappings is List) {
          if (rawPairMappings.isEmpty) {
            _lockerPairMappings = _defaultLockerPairMappings;
          } else {
            final parsedPairs =
                rawPairMappings.map(LockerPairMapping.tryFromJson).toList();
            if (parsedPairs.every((e) => e != null)) {
              _lockerPairMappings = parsedPairs.cast<LockerPairMapping>();
            } else {
              // Malformed entries — fall back to empty rather than risk
              // acting on a half-parsed pairing (unlocking the wrong
              // physical door).
              _lockerPairMappings = _defaultLockerPairMappings;
              needsRewrite = true;
            }
          }
        } else {
          _lockerPairMappings = _defaultLockerPairMappings;
          if (rawPairMappings != null) needsRewrite = true;
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
          final parsed =
              rawMapping.map(LockerMappingEntry.tryFromJson).toList();
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
      _kBoardLockerCounts: _boardLockerCounts,
      _kLockerPairMappings: _lockerPairMappings.map((e) => e.toJson()).toList(),
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
  ///
  /// In [pairedLockerMode], this is still the *complete* list of every
  /// physical door on every slave board, board by board, in physical wall
  /// order — e.g. for the 4-board layout (SB1↔SB2 paired, SB3↔SB4 paired)
  /// each with 4 doors, this is 16 entries: SB1's 4, then SB2's 4, then
  /// SB3's 4, then SB4's 4. [boardLockerCounts] is what tells
  /// `MockKioskRepository` where each board's chunk starts/ends within
  /// this single flat list, and which boards pair up.
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

  /// Validates a comma-separated "lockers per board" list (e.g. `"4,4,4,4"`
  /// for four 4-locker boards) against the *current* locker mapping's
  /// total door count — see [boardLockerCounts]. Optional: this is purely
  /// a *display* aid now (see [boardLockerCounts]'s doc comment) — leaving
  /// it blank is fine, the only rule is that if it's provided at all, it
  /// has to actually add up to every configured locker so labels don't
  /// silently go missing or wrong partway through the list.
  static String? validateBoardLockerCounts(String value, int totalLockers) {
    final stripped = stripWhitespace(value);
    if (stripped.isEmpty) return null;
    final tokens = stripped.split(',');
    final counts = <int>[];
    for (final t in tokens) {
      final n = int.tryParse(t);
      if (n == null || n <= 0) {
        return 'Each board size must be a positive whole number (found "$t").';
      }
      counts.add(n);
    }
    final sum = counts.fold<int>(0, (a, b) => a + b);
    if (sum != totalLockers) {
      return 'Board sizes add up to $sum locker(s) but the locker mapping '
          'above has $totalLockers — they must match exactly.';
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
  static String? validateLockerPairMappings(
      List<LockerPairMapping> pairs, int totalLockers) {
    if (totalLockers == 0) {
      return 'Add lockers to the locker mapping above first.';
    }

    final used = <int>{};
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

  /// How many consecutive entries of [lockerMapping] belong to each
  /// physical slave board, in board order — e.g. `[4, 4, 4, 4]` for four
  /// 4-locker boards. Optional, and — unlike an earlier version of this
  /// feature — has nothing to do with *pairing* anymore (see
  /// [lockerPairMappings] for that); this only drives the "Board N,
  /// Locker L" label `MockKioskRepository.lockerDisplayLabel` shows a
  /// customer/admin instead of the raw internal locker id, since that's
  /// what's actually printed on the physical door.
  List<int> get boardLockerCounts => List.unmodifiable(_boardLockerCounts);

  /// [boardLockerCounts] flattened to the comma-separated shorthand shown
  /// in `ConfigurationPage`'s "board sizes" field.
  String get boardLockerCountsText => _boardLockerCounts.join(',');

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

  /// Parses and persists [boardLockerCounts] from its comma-separated text
  /// form — see [validateBoardLockerCounts], which this delegates to
  /// (validated against the *current* [lockerMapping] length). A rejected
  /// value never reaches `config.json`. Purely a display/labeling concern
  /// now — see [boardLockerCounts]'s doc comment — so an empty value is
  /// always accepted (clears it back to "no board labels").
  Future<String?> setBoardLockerCounts(String value) async {
    final error = validateBoardLockerCounts(value, _lockerMapping.length);
    if (error != null) return error;
    final stripped = stripWhitespace(value);
    _boardLockerCounts =
        stripped.isEmpty ? [] : stripped.split(',').map(int.parse).toList();
    await _persistConfig();
    logger.i('Board locker counts updated to: $_boardLockerCounts');
    return null;
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
    _boardLockerCounts = _defaultBoardLockerCounts;
    _lockerPairMappings = _defaultLockerPairMappings;
    await _persistConfig();
    logger.i('ConfigService reset to defaults');
  }

  /// Check if ConfigService is initialized
  bool get isInitialized => _initialized;
}
