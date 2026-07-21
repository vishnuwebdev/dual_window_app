import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/config_service.dart';
import '../mock/mock_kiosk_repository.dart';
import '../utilities/logging.dart';

/// Result of a [SettingsSyncService] pull/push — kept as a tiny value type
/// (matching `LockerResult`/`LockerResponse` elsewhere in this codebase)
/// rather than a bare `String?`, since a *successful* sync still has
/// several independent notes worth surfacing to the admin (which fields
/// actually changed, which were skipped and why).
class SettingsSyncResult {
  const SettingsSyncResult({required this.success, required this.message});

  final bool success;
  final String message;
}

/// Syncs this unit's settings (SMS template, locker sizes) and parcel
/// database with VaultGroup's cloud — mirrors the Android app's
/// `SettingsService.readSettingsFromServer` / `readDbFromServer` /
/// `putSettingsToTheServer` (GET/PUT `https://saas.vaultgroup-cloud.com/settings/unit`,
/// JWT bearer auth — see `cnc-dnp-android`'s `util/SettingsService.kt`).
///
/// Auth: reuses the JWT `UnitRegistrationService.refreshJwt` already wrote
/// to `mq.json`'s `password` field — the exact same file/field the Android
/// app's `SettingsService` reads from (there, `mq.json` lives inside
/// cvmain's own sandboxed directory; here it's next to `config.json`/
/// `db.json` — see `UnitRegistrationService`'s class doc comment for why).
///
/// SCOPE NOTE — `config`/`cvmaster_config`: Android's version also
/// round-trips cvmain's own native `config.json`/`cvmaster_config` (files
/// inside cvmain's *own* directory, not anything the app itself manages)
/// under those two keys. This app's own `config.json` (admin PIN, locker
/// mapping, etc. — see `ConfigService`) is a completely different file
/// with a different schema, so it is never confused with the `config` key
/// here. Instead:
///  - On [pullFromServer], the server's `config` blob (cvmain's native
///    config) is written straight to `<cvmainConfigDir>/config.json` — see
///    `ConfigService.cvmainConfigDir`, the same directory
///    `UnitRegistrationService.mirrorToCvmainConfig` already writes
///    `auth.json`/`mq.json` into. Skipped, with a note, if that directory
///    is blank. `cvmaster_config`'s real on-disk path was never confirmed
///    for this deployment (unlike cvmain's, which was verified over SSH —
///    see `ConfigService.cvmainConfigDir`'s doc comment), so it's
///    intentionally left unwritten rather than guessed at.
///  - On [pushToServer], `config` is read back from that same
///    `<cvmainConfigDir>/config.json` if present (`{}` otherwise), and
///    `cvmaster_config` is always sent as `{}` for the same reason.
///  - Exactly like `UnitRegistrationService.mirrorToCvmainConfig`, writing
///    a fresh `config.json` here does **not** restart cvmain — it still
///    needs a manual restart (`sudo pkill -f cvmain_rs`) to actually pick
///    it up.
class SettingsSyncService {
  SettingsSyncService._();

  static final SettingsSyncService instance = SettingsSyncService._();

  static const _baseUrl = 'https://saas.vaultgroup-cloud.com';
  static const _timeout = Duration(seconds: 20);

  File get _mqFile => File('${Directory.current.path}/mq.json');

  File _cvmainNativeConfigFile() {
    final dir = ConfigService().cvmainConfigDir;
    return File('$dir/config.json');
  }

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

  /// GET `/settings/unit` — pulls the SMS template, locker sizes, cvmain's
  /// native config (best-effort — see the class doc comment's SCOPE NOTE),
  /// and the parcel database, applying each to local state. Mirrors
  /// Android's `readSettingsFromServer`/`readDbFromServer` combined into
  /// one call, since both hit the same endpoint and this app has no
  /// separate reason to split them.
  ///
  /// A rejected/malformed individual field (e.g. a template that fails
  /// `ConfigService.validateSmsTemplate`) is noted in the result message
  /// and skipped — it never aborts the other fields' sync, mirroring how
  /// every setter in `ConfigService` already refuses bad input without
  /// touching what was there before.
  Future<SettingsSyncResult> pullFromServer() async {
    final jwt = await _readJwt();
    if (jwt == null) {
      return const SettingsSyncResult(
        success: false,
        message:
            'No JWT available — register the unit and refresh its JWT first (Unit Registration page).',
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/settings/unit'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        logger.w(
            'SettingsSyncService.pull failed: ${response.statusCode} ${response.body}');
        return SettingsSyncResult(
          success: false,
          message: 'Pull failed (HTTP ${response.statusCode}).',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['content'] as Map<String, dynamic>?;
      if (content == null) {
        return const SettingsSyncResult(
          success: false,
          message: 'Server response had no "content" field.',
        );
      }

      final notes = <String>[];

      final sizesRaw = content['lockers_sizes'];
      if (sizesRaw is List && sizesRaw.isNotEmpty) {
        final csv = sizesRaw.map((s) => s.toString().toLowerCase()).join(',');
        final error = await ConfigService().setLockerMapping(csv);
        notes.add(error != null
            ? 'Locker sizes from cloud were rejected: $error'
            : 'Locker mapping updated (${sizesRaw.length} locker(s)).');
      }

      final template = content['template'];
      if (template is String && template.isNotEmpty) {
        final error = await ConfigService().setSmsTemplate(template);
        notes.add(error != null
            ? 'SMS template from cloud was rejected: $error'
            : 'SMS template updated.');
      }

      final config = content['config'];
      if (config is Map) {
        final dir = ConfigService().cvmainConfigDir;
        if (dir.isEmpty) {
          notes.add(
            'cvmain config directory is blank — cvmain\'s native config '
            'from the cloud was not written anywhere (set it on the Unit '
            'Registration page).',
          );
        } else {
          try {
            final file = _cvmainNativeConfigFile();
            await file.parent.create(recursive: true);
            await file.writeAsString(
                const JsonEncoder.withIndent('  ').convert(config));
            notes.add(
                'cvmain\'s native config.json written to $dir — restart cvmain to apply.');
          } catch (e) {
            notes.add('Failed to write cvmain\'s native config.json: $e');
          }
        }
      }

      final dbEntries = content['db_entries'];
      List<dynamic>? items;
      if (dbEntries is String && dbEntries.isNotEmpty) {
        try {
          final decoded = jsonDecode(dbEntries);
          if (decoded is List) items = decoded;
        } catch (e) {
          notes.add('Could not parse "db_entries" as JSON: $e');
        }
      } else if (dbEntries is List) {
        items = dbEntries;
      }
      if (items != null) {
        MockKioskRepository.instance.replaceItemsFromServer(items);
        notes.add(
            'Parcel database replaced with ${items.length} record(s) from cloud.');
      }

      final message =
          notes.isEmpty ? 'Nothing to sync — server returned no recognized fields.' : notes.join(' ');
      logger.i('SettingsSyncService.pull succeeded: $message');
      return SettingsSyncResult(success: true, message: message);
    } on TimeoutException {
      return const SettingsSyncResult(
        success: false,
        message: 'Timed out reaching VaultGroup — check network connectivity.',
      );
    } catch (e) {
      logger.w('SettingsSyncService.pull failed: $e');
      return SettingsSyncResult(success: false, message: 'Could not reach VaultGroup: $e');
    }
  }

  /// PUT `/settings/unit` — pushes the SMS template, locker sizes, parcel
  /// database, and admin PIN back to the cloud, mirroring Android's
  /// `putSettingsToTheServer`. `config`/`cvmaster_config` are populated
  /// best-effort — see the class doc comment's SCOPE NOTE.
  Future<SettingsSyncResult> pushToServer() async {
    final jwt = await _readJwt();
    if (jwt == null) {
      return const SettingsSyncResult(
        success: false,
        message:
            'No JWT available — register the unit and refresh its JWT first (Unit Registration page).',
      );
    }

    Map<String, dynamic> config = {};
    final cvmainDir = ConfigService().cvmainConfigDir;
    if (cvmainDir.isNotEmpty) {
      try {
        final file = _cvmainNativeConfigFile();
        if (await file.exists()) {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is Map<String, dynamic>) config = decoded;
        }
      } catch (e) {
        logger.w(
            'SettingsSyncService.push: could not read cvmain native config.json: $e');
      }
    }

    final cfg = ConfigService();
    final body = jsonEncode({
      'config': config,
      // cvmaster_config's real on-disk path was never confirmed for this
      // deployment — see the class doc comment's SCOPE NOTE — so this is
      // always sent empty rather than guessed at.
      'cvmaster_config': const <String, dynamic>{},
      'template': cfg.smsTemplate,
      'lockers_sizes': cfg.lockerMapping.map((e) => e.size).toList(),
      'db_entries': MockKioskRepository.instance.itemsAsJson(),
      // Closest local analogue of Android's `admin.json`-backed admin
      // password — this app keeps that as `ConfigService.adminPin`.
      'admin_password': cfg.adminPin,
    });

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
