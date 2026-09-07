import 'dart:async';
import 'dart:convert';

import '../config/config_service.dart';
import '../grpc/locker_grpc_service.dart';
import '../utilities/app_paths.dart';
import '../utilities/logging.dart';
import 'audit_codes.dart';
import 'unit_registration_service.dart';

/// Keeps this unit's MQTT JWT (`mq.json`, written by
/// `UnitRegistrationService.refreshJwt`) from ever sitting expired for
/// long, without any admin having to remember to press "Refresh JWT" —
/// see the 2026-09 conversation that led to this class for the full
/// reasoning. Before this existed, `refreshJwt()` only ever ran right
/// after a fresh `registerWithCode` sign-up, or manually from the Unit
/// Registration admin page — nothing refreshed it again before its `exp`
/// passed, so a unit left running past the token's lifetime (12 hours on
/// the JWTs this platform issues, decoded from a real `mq.json` on
/// 2026-09-03) would silently stop authenticating to the MQTT broker
/// until someone noticed and clicked the button.
///
/// DELIBERATELY UNCONDITIONAL, NOT EXPIRY-CHECKED: this refreshes on a
/// flat timer ([_refreshInterval], 10 hours) rather than decoding the
/// current JWT's `exp` and only refreshing once it's actually
/// expired/close to it. 10 hours is comfortably inside the observed
/// 12-hour token lifetime, so by construction the token is never actually
/// expired at the moment this fires — see the conversation this was
/// designed in for why a "check every 10h, refresh if expired" version
/// was rejected (it leaves an ~8-hour gap every cycle where the token has
/// already died but nothing checks again until the next 10-hour mark).
/// If VaultGroup ever issues tokens with a shorter lifetime than this
/// class's [_refreshInterval], that gap reasoning would apply here too —
/// this class doesn't defend against that; [_refreshInterval] would need
/// shortening to match.
///
/// SINGLE OWNER — ADMIN WINDOW ONLY: call [start] exactly once, from
/// `main.dart`'s `_runAdminWindow()`, same as `MqttSyncService`/
/// `AutoSyncService`. This app runs one `main()` per *window* (see
/// `main.dart`'s class doc comment — `desktop_multi_window` gives every
/// window, admin and customer alike, its own fresh engine), so starting
/// this from shared startup code reachable by both windows would mean two
/// independent 10-hour timers both refreshing the same `mq.json` and both
/// mirroring to cvmain, racing each other. Never called from
/// `_runCustomerWindow()`.
///
/// EACH CYCLE — INCLUDING THE IMMEDIATE ONE [start] fires at startup, to
/// cover a token that's already stale/expired *before* this app even
/// launched (exactly the state discovered on 2026-09-03: a token that
/// expired 2026-07-13 with nothing having refreshed it since) rather than
/// leaving it stale for up to another 10 hours after boot:
///  1. [UnitRegistrationService.refreshJwt] — signs in again and rewrites
///     the local `mq.json` with a fresh token. Also reconnects
///     `MqttSyncService` itself, as it already does today.
///  2. On success only: [UnitRegistrationService.mirrorToCvmainConfig] —
///     copies the refreshed `auth.json`/`mq.json` into the physical
///     unit's real cvmain config directory, exactly the second step the
///     "Refresh JWT" button on the admin page already does (see
///     `unit_registration_page.dart`'s `_refreshJwt()`). Skipped on
///     failure — nothing new to mirror if the refresh itself didn't
///     produce one, and `mirrorToCvmainConfig` would just re-copy the
///     still-stale file otherwise.
///  3. Every outcome — success or failure — is logged locally via
///     [logger] unconditionally, and additionally escalated to
///     VaultGroup's Rapid7 platform via [LockerGrpcService.userAudit]
///     whenever [ConfigService.isGrpcBackend] is true (no-op in mock
///     mode — nothing to relay through, same reasoning
///     `_reportSlaveBoardDisabled` in `home_page.dart` already uses for
///     its own audit calls). [AuditCodes.authTokenRefreshSuccess]/
///     [AuditCodes.authTokenRefreshFailure] are new, UNCONFIRMED codes —
///     see that class's doc comment on those two values for why.
///
/// NO RETRY-WITH-BACKOFF ON FAILURE: a failed attempt (e.g. no network at
/// that moment) just waits for the next scheduled 10-hour tick rather
/// than retrying sooner on its own. `refreshJwt()`'s own doc comment
/// already notes the admin can always force one sooner via the "Refresh
/// JWT" button in the meantime. If a full 10-hour wait after a failed
/// attempt turns out to be too long in practice, tighten this with a
/// short one-off retry timer on failure rather than shortening
/// [_refreshInterval] itself (which would also shorten the normal,
/// successful cadence for no reason).
class TokenRefreshService {
  TokenRefreshService._();

  static final TokenRefreshService instance = TokenRefreshService._();

  // TEST-ONLY: temporarily shortened from `Duration(hours: 10)` to 1 minute to force fast refresh cycles while debugging the JWT auto-refresh/MQTT bad_username_or_password issue. REVERT to `Duration(hours: 10)` before shipping.
  static const _refreshInterval = Duration(minutes: 1);

  bool _started = false;
  Timer? _timer;

  /// Call once at startup — see the class doc comment for the "admin
  /// window only" rule. Safe to call more than once; only the first call
  /// does anything. Fires one refresh immediately (fire-and-forget — see
  /// [_runRefreshCycle]) and schedules the recurring 10-hourly one after
  /// it.
  void start() {
    if (_started) return;
    _started = true;

    logger.i('TokenRefreshService: started — refreshing now, then every '
        '${_refreshInterval.inMinutes}m.');
    unawaited(_runRefreshCycle(trigger: 'startup'));
    _timer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(_runRefreshCycle(trigger: 'scheduled')),
    );
  }

  /// Cancels the recurring timer. Not currently called anywhere (this app
  /// has no clean-shutdown path for a window's engine), but provided for
  /// symmetry with `MqttSyncService.stop`/`AutoSyncService.stop`.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> _runRefreshCycle({required String trigger}) async {
    final ok = await UnitRegistrationService.instance.refreshJwt();

    if (!ok) {
      const message = 'TokenRefreshService: JWT refresh failed — will '
          'retry on the next scheduled cycle.';
      logger.w('$message (trigger: $trigger)');
      await _reportToRapid7(
        code: AuditCodes.authTokenRefreshFailure,
        level: AuditLogLevel.warning,
        description: 'MQTT JWT auto-refresh failed (trigger: $trigger).',
      );
      return;
    }

    final expiry = await _currentTokenExpiry();
    final expiryText = expiry == null
        ? 'unknown expiry (could not decode refreshed token)'
        : 'expires ${expiry.toIso8601String()}';
    logger.i('TokenRefreshService: JWT refreshed ($expiryText, '
        'trigger: $trigger) — mirroring to cvmain.');

    final mirrorResult =
        await UnitRegistrationService.instance.mirrorToCvmainConfig();
    if (mirrorResult != null) {
      logger.i('TokenRefreshService: $mirrorResult');
    }

    await _reportToRapid7(
      code: AuditCodes.authTokenRefreshSuccess,
      level: AuditLogLevel.info,
      description: 'MQTT JWT auto-refreshed ($expiryText, '
          'trigger: $trigger).${mirrorResult == null ? '' : ' $mirrorResult'}',
    );
  }

  /// Sends one `userAudit` event to Rapid7 — see the class doc comment
  /// for why this is gated behind `isGrpcBackend` and why the two
  /// `AuditCodes` values it's called with are unconfirmed. Best-effort:
  /// `LockerGrpcService.userAudit` already catches and logs its own
  /// failures, so nothing further to do here on top of that.
  Future<void> _reportToRapid7({
    required int code,
    required String level,
    required String description,
  }) async {
    if (!ConfigService().isGrpcBackend) return;
    await LockerGrpcService.instance.userAudit(
      code: code,
      priority: AuditLogPriority.normal,
      level: level,
      description: description,
    );
  }

  /// Decodes the `exp` claim out of whatever JWT is currently sitting in
  /// `mq.json`, purely for the human-readable log line above — a plain
  /// base64 decode of the JWT payload segment, not a signature check,
  /// same reasoning/approach as `MqttSyncService._subscribeTopicFromJwt`.
  /// Returns `null` if `mq.json` is missing, isn't valid JSON, or the
  /// token can't be decoded — callers treat that as "log without an
  /// expiry time," never as a reason to skip logging altogether.
  Future<DateTime?> _currentTokenExpiry() async {
    try {
      final file = AppPaths.mqFile;
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final jwt = json['password'] as String?;
      if (jwt == null) return null;

      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = claims['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (e) {
      logger
          .w('TokenRefreshService: could not decode refreshed JWT expiry: $e');
      return null;
    }
  }
}
