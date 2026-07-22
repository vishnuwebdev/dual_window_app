import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/config_service.dart';
import '../utilities/logging.dart';
import 'mqtt_sync_service.dart';

/// Registers this unit with VaultGroup's cloud platform, ported from
/// `AdminOverrideActivity.openUnitRegistration()` / `refreshJwt()` in the
/// Android app.
///
/// The flow, unchanged from Android: you create a unit + registration code
/// on the VaultGroup platform first, then enter that code here. This POSTs
/// to `/authentication/unit/sign-up`, which returns credentials — those get
/// saved locally (see [_authFile]), then immediately exchanged via
/// `/authentication/unit/sign-in` for a JWT, written alongside the MQTT
/// broker address (see [_mqFile]). That authenticated identity is what a
/// real cvmain relays audit events under, so they show up against this
/// unit's id on the platform's dashboard — see
/// `LockerGrpcService.userAudit`, which sends the actual audit RPCs.
///
/// Deliberate difference from Android: there, `auth.json`/`mq.json` live
/// under cvmain's own `/cv/config/` directory, because cvmain itself
/// (native code, not the Kotlin app) is what opens the MQTT session. This
/// desktop port keeps its own copies next to `config.json`/`db.json`
/// (`Directory.current.path`) instead — self-contained, and works whether
/// or not a real cvmain is even installed on the machine. If a real
/// physical unit's cvmain is already registered separately, register this
/// app with its *own* registration code from the platform rather than
/// reusing the same one, if both are meant to appear as distinct entries
/// on the dashboard.
class UnitRegistrationService extends ChangeNotifier {
  UnitRegistrationService._internal();

  static final UnitRegistrationService instance =
      UnitRegistrationService._internal();

  static const _baseUrl = 'https://saas.vaultgroup-cloud.com';

  File get _authFile => File('${Directory.current.path}/auth.json');
  File get _mqFile => File('${Directory.current.path}/mq.json');

  bool _isRegistered = false;
  String? _username;
  bool _busy = false;

  bool get isRegistered => _isRegistered;
  String? get username => _username;
  bool get isBusy => _busy;

  /// Loads any existing `auth.json` (from a previous registration) into
  /// memory. Call once at startup — see `main.dart`. Safe to call more
  /// than once.
  Future<void> initialize() async {
    try {
      if (await _authFile.exists()) {
        final json =
            jsonDecode(await _authFile.readAsString()) as Map<String, dynamic>;
        final username = json['username'];
        if (username is String && username.isNotEmpty) {
          _username = username;
          _isRegistered = true;
          logger.i('UnitRegistrationService: already registered as "$username".');
        }
      }
    } catch (e) {
      logger.w('Failed to load auth.json: $e');
    }
  }

  /// Mirrors `openUnitRegistration()`'s POST to
  /// `/authentication/unit/sign-up`. Returns an error message on failure,
  /// or null on success — at which point [isRegistered] is true and
  /// [refreshJwt] has already run once to populate `mq.json`.
  Future<String?> registerWithCode(String registrationCode) async {
    final code = registrationCode.trim();
    if (code.isEmpty) return 'Registration code is required.';

    _busy = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/authentication/unit/sign-up'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'registration_code': code}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        logger.w(
            'Unit registration failed: ${response.statusCode} ${response.body}');
        return 'Registration failed (HTTP ${response.statusCode}). '
            'Check the code and try again.';
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final username = body['username'];
      if (username is! String || username.isEmpty) {
        return 'Registration response did not include a username.';
      }

      await _authFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(body),
      );
      _username = username;
      _isRegistered = true;
      logger.i('Unit registered as "$username".');

      // Mirrors the Android flow: registration is immediately followed by
      // signing in to establish the MQTT identity.
      final jwtOk = await refreshJwt();
      if (!jwtOk) {
        return 'Registered as "$username", but signing in to get a JWT '
            'failed — try "Refresh JWT" again in a moment.';
      }
      return null;
    } on TimeoutException {
      return 'Timed out reaching VaultGroup — check your network connection.';
    } catch (e) {
      logger.w('Unit registration request failed: $e');
      return 'Could not reach VaultGroup — check your network connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Mirrors `refreshJwt()`: signs in with the credentials in `auth.json`
  /// and writes the resulting JWT into `mq.json`, alongside the MQTT
  /// broker address — this is what authenticates the unit's cloud MQTT
  /// session (on a real unit, cvmain does this itself; here it's this
  /// service). Returns true on success.
  Future<bool> refreshJwt() async {
    try {
      if (!await _authFile.exists()) {
        logger.w('refreshJwt: no auth.json — register the unit first.');
        return false;
      }
      final auth =
          jsonDecode(await _authFile.readAsString()) as Map<String, dynamic>;
      final username = auth['username'] as String?;
      final password = auth['password'] as String?;
      if (username == null || password == null) {
        logger.w('refreshJwt: auth.json is missing username/password.');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/authentication/unit/sign-in'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        logger.w('refreshJwt failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String? ?? '';

      await _mqFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'server_uri': 'tcp://ws-saas.vaultgroup-cloud.com:1883',
          'username': username,
          'password': token,
        }),
      );

      logger.i('JWT refreshed and mq.json updated.');

      // A fresh mq.json means a fresh MQTT identity — (re)connect right
      // away so the cloud push-trigger (see MqttSyncService) and the next
      // auto-push (see AutoSyncService) both use the new credentials
      // immediately, without needing any admin UI to kick this off.
      unawaited(MqttSyncService.instance.start());

      return true;
    } catch (e) {
      logger.w('refreshJwt request failed: $e');
      return false;
    }
  }

  /// Copies the just-written `auth.json`/`mq.json` into the *physical
  /// unit's* real cvmain config directory (`ConfigService.cvmainConfigDir`)
  /// so cvmain itself — not this app — actually has the new identity to
  /// use once it's restarted.
  ///
  /// Why this exists: on Android, `auth.json`/`mq.json` are written
  /// straight into cvmain's own sandboxed directory because cvmain (native
  /// code bundled in-process with the app) is what opens the MQTT session
  /// that VaultGroup's dashboard shows as "online". This desktop app is a
  /// *separate* process from cvmain, so writing to its own directory (see
  /// the class doc comment) has zero effect on cvmain's actual MQTT
  /// connection — the unit will never show online no matter how many
  /// times you register here, unless cvmain itself gets these files.
  ///
  /// This only copies the files — it does **not** restart cvmain. cvmain
  /// only re-reads its config on process start (confirmed from its
  /// `run_cvmain.sh` supervisor script), so after this call succeeds you
  /// still need to restart it yourself, e.g. over SSH:
  /// ```
  /// sudo pkill -f cvmain_rs
  /// ```
  /// Its supervisor loop relaunches it within a few seconds with the
  /// files just written here. Deliberately manual, not automated by this
  /// app — see the `ConfigService.cvmainConfigDir` doc comment.
  ///
  /// Returns a human-readable status string for display, or `null` if
  /// skipped because [ConfigService.cvmainConfigDir] isn't set.
  Future<String?> mirrorToCvmainConfig() async {
    final dir = ConfigService().cvmainConfigDir;
    if (dir.isEmpty) return null;

    try {
      if (!await _authFile.exists() || !await _mqFile.exists()) {
        return 'Register the unit first — no local auth.json/mq.json to mirror yet.';
      }

      final destAuth = File('$dir/auth.json');
      await destAuth.parent.create(recursive: true);
      await destAuth.writeAsString(await _authFile.readAsString());

      // Confirmed layout on a real unit: mq.json lives in an `mq`
      // subdirectory, not flat alongside auth.json — see
      // `ConfigService.cvmainConfigDir`'s doc comment.
      final destMq = File('$dir/mq/mq.json');
      await destMq.parent.create(recursive: true);
      await destMq.writeAsString(await _mqFile.readAsString());

      logger.i('Mirrored auth.json/mq.json to cvmain config dir: $dir');
      return 'Copied auth.json/mq.json to $dir. cvmain still needs a '
          'manual restart to pick them up (sudo pkill -f cvmain_rs over SSH).';
    } catch (e) {
      logger.w('Failed to mirror registration files to $dir: $e');
      return 'Could not write to "$dir" — check the path exists and this '
          'app has permission to write there. ($e)';
    }
  }

  /// Clears the local registration state. Does not deregister anything on
  /// the platform itself — VaultGroup exposes no such endpoint to the app;
  /// this only forgets the credentials stored locally in `auth.json`/
  /// `mq.json`.
  Future<void> forget() async {
    _isRegistered = false;
    _username = null;
    if (await _authFile.exists()) await _authFile.delete();
    if (await _mqFile.exists()) await _mqFile.delete();
    logger.i('Unit registration forgotten locally.');
    notifyListeners();
  }

  /// Resets both this app's local registration state *and* the physical
  /// unit's real `auth.json`/`mq.json` back to their factory-shipped
  /// defaults, using the `auth.json-reset`/`mq.json-reset` template files
  /// that already sit alongside the live ones in
  /// `ConfigService.cvmainConfigDir` on a real unit (confirmed via SSH:
  /// `<dir>/auth.json-reset` and `<dir>/mq/mq.json-reset`).
  ///
  /// Unlike [forget] (which only clears this app's own local copies — see
  /// its doc comment), this also overwrites the *physical unit's* actual
  /// `auth.json` and `mq/mq.json` with those reset templates, so cvmain
  /// itself reverts to an unregistered identity next time it restarts —
  /// not just this app. The local half always runs; the physical-unit
  /// half is skipped (with an explanatory message, same pattern as
  /// [mirrorToCvmainConfig]) if [ConfigService.cvmainConfigDir] is blank,
  /// or if either "-reset" template file isn't actually present there.
  ///
  /// Like [mirrorToCvmainConfig], this only writes files — it does **not**
  /// restart cvmain, which still needs a manual restart
  /// (`sudo pkill -f cvmain_rs` over SSH) to actually pick up the reset
  /// files.
  Future<String?> resetToFactoryDefaults() async {
    // Always clear this app's own local state first, regardless of
    // whether a cvmain directory is configured below — "Reset" should
    // never leave this app thinking it's still registered.
    await forget();

    final dir = ConfigService().cvmainConfigDir;
    if (dir.isEmpty) {
      return 'Local registration cleared. No cvmain config directory is '
          'set below, so the physical unit\'s auth.json/mq.json were left '
          'untouched.';
    }

    try {
      final authReset = File('$dir/auth.json-reset');
      final mqReset = File('$dir/mq/mq.json-reset');

      if (!await authReset.exists() || !await mqReset.exists()) {
        return 'Local registration cleared, but couldn\'t find '
            'auth.json-reset/mq.json-reset in "$dir" — the physical '
            'unit\'s files were left untouched.';
      }

      final destAuth = File('$dir/auth.json');
      await destAuth.parent.create(recursive: true);
      await destAuth.writeAsString(await authReset.readAsString());

      // Same `mq/` subdirectory layout as `mirrorToCvmainConfig`.
      final destMq = File('$dir/mq/mq.json');
      await destMq.parent.create(recursive: true);
      await destMq.writeAsString(await mqReset.readAsString());

      logger.i('Reset auth.json/mq.json to factory defaults in cvmain config dir: $dir');
      return 'Local registration cleared, and the unit\'s auth.json/mq.json '
          'were reset to their factory defaults in $dir. cvmain still '
          'needs a manual restart to pick this up (sudo pkill -f '
          'cvmain_rs over SSH).';
    } catch (e) {
      logger.w('Failed to reset auth.json/mq.json in $dir: $e');
      return 'Local registration cleared, but resetting the physical '
          'unit\'s files in "$dir" failed: $e';
    }
  }
}
