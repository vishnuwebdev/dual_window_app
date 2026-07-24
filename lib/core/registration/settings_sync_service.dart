import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/config_service.dart';
import '../mock/mock_kiosk_repository.dart';
import '../utilities/logging.dart';

/// Result of a [SettingsSyncService] push — kept as a tiny value type
/// (matching `LockerResult`/`LockerResponse` elsewhere in this codebase)
/// rather than a bare `String?`, since callers (currently just logging —
/// see `AutoSyncService`/`MqttSyncService`) want both a success flag and a
/// human-readable reason.
class SettingsSyncResult {
  const SettingsSyncResult({required this.success, required this.message});

  final bool success;
  final String message;
}

/// Pushes this unit's current settings (SMS template, locker sizes, cvmain
/// and cvmaster's native config) and parcel database *up* to VaultGroup's
/// cloud — mirrors the device -> cloud half of the Android app's
/// `SettingsService.putSettingsToTheServer` (PUT
/// `https://saas.vaultgroup-cloud.com/settings/unit`, JWT bearer auth —
/// see `cnc-dnp-android`'s `util/SettingsService.kt`).
///
/// DELIBERATELY ONE-WAY: unlike Android (and an earlier version of this
/// class), there is **no** cloud -> device pull anymore. A pull applied
/// whatever the cloud happened to be holding straight onto
/// `ConfigService`/`MockKioskRepository` — which, the first time this was
/// tried against a real deployment, silently overwrote this unit's
/// carefully-configured real locker mapping/pairing with stale cloud data
/// and broke the Configuration page's "Sync Lockers from Hardware" flow.
/// The actual requirement is simpler and safer: VaultGroup should be able
/// to *read* this unit's state, not write to it — so this service only
/// ever sends data outward. If a real need for cloud -> device sync shows
/// up later, it should be a deliberate, explicitly-confirmed action (e.g.
/// an admin-triggered "Apply cloud settings" button with a diff preview),
/// not something that runs automatically the way [pushToServer] now does.
///
/// Auth: reuses the JWT `UnitRegistrationService.refreshJwt` already wrote
/// to `mq.json`'s `password` field — the exact same file/field the Android
/// app's `SettingsService` reads from (there, `mq.json` lives inside
/// cvmain's own sandboxed directory; here it's next to `config.json`/
/// `db.json` — see `UnitRegistrationService`'s class doc comment for why).
///
/// Called from two places, both driven without any admin having to press
/// anything (see `AutoSyncService` and `MqttSyncService`):
///  - [AutoSyncService] debounces and calls this automatically whenever
///    `ConfigService`, `MockKioskRepository`, or cvmain/cvmaster's own
///    config files change.
///  - [MqttSyncService] calls this immediately whenever VaultGroup's cloud
///    asks for a fresh copy over MQTT.
class SettingsSyncService {
  SettingsSyncService._();

  static final SettingsSyncService instance = SettingsSyncService._();

  static const _baseUrl = 'https://saas.vaultgroup-cloud.com';
  static const _timeout = Duration(seconds: 20);

  File get _mqFile => File('${Directory.current.path}/mq.json');

  Future<String?> _readJwt() async {
    try {
      if (!await _mqFile.exists()) return null;
      final json =
          jsonDecode(await _mqFile.readAsString()) as Map<String, dynamic>;
      final token = json['password'] as String?;
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      logger.w('SettingsSyncService: failed to read mq.json: $e');
      return null;
    }
  }

  /// Best-effort read of a native `config.json` sitting in [dir] — used
  /// for both cvmain's (confirmed path) and cvmaster's (guessed path — see
  /// `ConfigService.cvmasterConfigDir`) own config files. Returns `{}` if
  /// [dir] is blank, the file doesn't exist, or it fails to parse — a
  /// missing/bad native config file should never abort the rest of the
  /// push.
  Future<Map<String, dynamic>> _readNativeConfig(String dir, String label) async {
    if (dir.isEmpty) return const {};
    try {
      final file = File('$dir/config.json');
      if (!await file.exists()) return const {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      logger.w('SettingsSyncService: $label config.json at "$dir" was not a JSON object.');
      return const {};
    } catch (e) {
      logger.w('SettingsSyncService: could not read $label config.json at "$dir": $e');
      return const {};
    }
  }

  /// PUT `/settings/unit` — pushes the SMS template, locker sizes, cvmain's
  /// and cvmaster's native config (best-effort — see
  /// `ConfigService.cvmainConfigDir`/`cvmasterConfigDir`), the parcel
  /// database, and the admin PIN. Mirrors Android's
  /// `putSettingsToTheServer`, with two intentional format fixes found
  /// while integrating this against the real VaultGroup dashboard:
  ///  - Locker sizes are sent **uppercase** (`"SMALL"`, not `"small"`) —
  ///    Android sends `Locker.Size` Kotlin enum constants via `.toString()`,
  ///    which are uppercase; this app stores sizes lowercase internally
  ///    (`ConfigService.lockerMapping`) but must convert on the way out or
  ///    the dashboard doesn't recognize them.
  ///  - `db_entries` is sent in Android's exact `Item` shape
  ///    (`phone`/`pin`/`lockerId`/`creationDate` only) via
  ///    `MockKioskRepository.cloudDbEntriesJson()`, rather than this app's
  ///    richer local shape (which also carries `collectionLockerId` for
  ///    paired-locker mode) — an extra field the dashboard doesn't expect
  ///    risked it silently dropping the whole record. `creationDate` itself
  ///    is also now formatted to match Android's `DateSerializer` exactly
  ///    (explicit numeric UTC offset) — see that method's doc comment.
  ///
  /// STILL UNCONFIRMED — `template` (SMS template) not appearing on the
  /// dashboard: the wire format here matches Android's `putSettingsToTheServer`
  /// byte-for-byte (a plain top-level string, same JSON key). Since this
  /// app has no way to inspect VaultGroup's actual dashboard/schema, two
  /// explanations remain open and can't be ruled out from here:
  ///  1. The dashboard's "SMS Template" view may not read the top-level
  ///     `template` field at all, and instead reads some key *inside* the
  ///     `config` blob (cvmain's own native config.json) — which would mean
  ///     the real fix is finding and setting that key there, not here.
  ///  2. It may simply be a dashboard-side gap (received and stored fine,
  ///     just not rendered anywhere).
  /// Worth checking directly against the real `<cvmainConfigDir>/config.json`
  /// content for an SMS-related key before assuming this needs an app-side
  /// change.
  ///
  /// `db_entries` type fix (2026-07-24): Android's own code is inconsistent
  /// between its push and pull of this field. `putSettingsToTheServer`
  /// (`SettingsService.kt:270`) sends `db_entries` as a **nested JSON
  /// array** (`JSONArray(dbJson)`) — which is what this file sent before
  /// this fix, and it didn't show up on the dashboard. But Android's own
  /// `readDbFromServer`/`readSettingsFromServer` (`SettingsService.kt:82`,
  /// `:166` reads `template` the same way) read the field back via
  /// `content.getString("db_entries")` — i.e. `org.json`'s `getString`,
  /// which throws unless the stored value is a literal JSON string, not an
  /// object/array. That only makes sense if VaultGroup's backend actually
  /// stores/returns `db_entries` as a **JSON-encoded string**, not a nested
  /// type — so this now sends it pre-encoded as a string
  /// (`jsonEncode(...)`) to match what the backend evidently expects, even
  /// though that contradicts Android's own push code. UNVERIFIED against a
  /// real unit — see the class doc comment; revert to the raw list if this
  /// doesn't fix it either.
  Future<SettingsSyncResult> pushToServer() async {
    final jwt = await _readJwt();
    if (jwt == null) {
      return const SettingsSyncResult(
        success: false,
        message:
            'No JWT available — register the unit and refresh its JWT first (Unit Registration page).',
      );
    }

    final cfg = ConfigService();
    final config = await _readNativeConfig(cfg.cvmainConfigDir, 'cvmain');
    final cvmasterConfig = await _readNativeConfig(cfg.cvmasterConfigDir, 'cvmaster');

    final body = jsonEncode({
      'config': config,
      'cvmaster_config': cvmasterConfig,
      'template': cfg.smsTemplate,
      'lockers_sizes': cfg.lockerMapping.map((e) => e.size.toUpperCase()).toList(),
      'db_entries': jsonEncode(MockKioskRepository.instance.cloudDbEntriesJson()),
      // Closest local analogue of Android's `admin.json`-backed admin
      // password — this app keeps that as `ConfigService.adminPin`.
      'admin_password': cfg.adminPin,
    });

    // Diagnostic only — this can't be verified against the real dashboard
    // from a dev machine, so log exactly what's about to go out. On the
    // real unit, if `template` here is empty/stale despite an admin having
    // set a real one in the Configuration page, that's an app-side bug
    // (ConfigService not loading/persisting it); if it's the correct text
    // and the dashboard still doesn't show it, that rules the app out
    // entirely and points at the dashboard/backend. Same reasoning for
    // `db_entries`'s length vs however many parcels are actually on-unit.
    logger.i('SettingsSyncService.push: template="${cfg.smsTemplate}" '
        '(${cfg.smsTemplate.length} chars), '
        'db_entries=${MockKioskRepository.instance.cloudDbEntriesJson().length} item(s)');

    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/settings/unit'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        logger.w(
            'SettingsSyncService.push failed: ${response.statusCode} ${response.body}');
        return SettingsSyncResult(
          success: false,
          message: 'Push failed (HTTP ${response.statusCode}).',
        );
      }

      logger.i('SettingsSyncService.push succeeded.');
      return const SettingsSyncResult(
        success: true,
        message: 'Settings and parcel database pushed to the cloud.',
      );
    } on TimeoutException {
      return const SettingsSyncResult(
        success: false,
        message: 'Timed out reaching VaultGroup — check network connectivity.',
      );
    } catch (e) {
      logger.w('SettingsSyncService.push failed: $e');
      return SettingsSyncResult(success: false, message: 'Could not reach VaultGroup: $e');
    }
  }
}
