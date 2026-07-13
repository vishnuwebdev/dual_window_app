import 'dart:async';

import 'package:grpc/grpc.dart';

import '../config/config_service.dart';
import '../utilities/logging.dart';
// Generated from protos/service.proto — see protos/CODEGEN.md for how to
// (re)produce these. `Empty` comes from protobuf's own bundled well-known
// type rather than a locally-generated copy — the protoc_plugin version
// this was generated with wires `service.pbgrpc.dart`'s own references to
// `google.protobuf.Empty` straight to this package, so constructing a
// different `Empty` class here would be a type mismatch.
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import '../../generated/service.pbgrpc.dart';

/// Talks to a physical locker unit's `cvmain` gRPC server — or a
/// `cv-simulator-rs` setup sitting behind the same contract — using the
/// exact `cv_saas.CommsService` proto the Android app's `GrpcService`
/// already speaks (see `protos/service.proto`, copied verbatim from
/// `cnc-dnp-android/app/src/main/proto/service.proto`).
///
/// Only used when `ConfigService().isGrpcBackend` is true — otherwise
/// `MockKioskRepository` handles everything in-memory/via `db.json`, no
/// network involved. See `ConfigService.lockerBackend`.
///
/// Every call here is best-effort: on any failure (unreachable host,
/// timeout, malformed response) it logs a warning and returns a failure
/// value rather than throwing, so a flaky/offline unit degrades to "the
/// action didn't confirm" instead of crashing the UI — mirroring how the
/// Android app wraps every gRPC call in `DbService`/`LockerService`/
/// `MainActivity` in try/catch.
class LockerGrpcService {
  LockerGrpcService._internal() {
    ConfigService().addListener(_onConfigChanged);
  }

  static final LockerGrpcService instance = LockerGrpcService._internal();

  ClientChannel? _channel;
  CommsServiceClient? _client;
  String? _channelAddress;

  /// How long to wait for a single RPC before giving up. The Android app
  /// uses a 100ms timeout for its health check, but that's tuned for a
  /// same-device native call (`libcvmain_rs.so` running in-process); this
  /// is a real network hop over Wi-Fi/LAN to physical hardware, so it gets
  /// more room.
  static const _callTimeout = Duration(seconds: 5);

  void _onConfigChanged() {
    final address = ConfigService().lockerAddress;
    if (address != _channelAddress) {
      // Address changed since we last connected (e.g. an admin repointed
      // it from the simulator to the real unit) — drop the old channel so
      // the next call reconnects instead of silently continuing to talk
      // to the previous address.
      unawaited(_channel?.shutdown());
      _channel = null;
      _client = null;
      _channelAddress = null;
    }
  }

  CommsServiceClient _clientFor(String address) {
    if (_client != null && _channelAddress == address) return _client!;

    final parts = address.split(':');
    final host = parts.isNotEmpty ? parts.first : address;
    final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 7777) : 7777;

    final channel = ClientChannel(
      host,
      port: port,
      // Plaintext, unauthenticated — matches the Android app's
      // `.usePlaintext()` and the unit's own gRPC server, which has no
      // TLS/auth layer in front of it.
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _channel = channel;
    _client = CommsServiceClient(
      channel,
      options: CallOptions(timeout: _callTimeout),
    );
    _channelAddress = address;
    return _client!;
  }

  /// Mirrors `MainActivity.handleGrpcCall` / `isCommunicationOn()`: a
  /// liveness check to run before starting a journey (drop-off, collect,
  /// help). Returns true only if the unit responds with
  /// `resp.success == true` — matching exactly what the Android app checks
  /// before letting a customer proceed.
  Future<bool> checkHealth() async {
    try {
      final client = _clientFor(ConfigService().lockerAddress);
      final response = await client.get_slave_firmware(Empty());
      return response.hasResp() && response.resp.success;
    } catch (e) {
      logger.w('LockerGrpcService.checkHealth failed: $e');
      return false;
    }
  }

  /// Mirrors `LockerService.initializeLockerFromCv` /
  /// `getLockersForConfiguration`: returns how many lockers the unit
  /// reports, or null if the call failed. Informational only — sizes are a
  /// software/business concept the hardware doesn't know about (see
  /// `ConfigService.lockerMapping`), so this does not automatically drive
  /// the locker inventory; it's there for an admin to sanity-check the
  /// configured `locker_mapping` length against what the unit reports.
  Future<int?> getLockerCount() async {
    try {
      final client = _clientFor(ConfigService().lockerAddress);
      final response = await client.get_locker_states(Empty());
      return response.lockerMap.length;
    } catch (e) {
      logger.w('LockerGrpcService.getLockerCount failed: $e');
      return null;
    }
  }

  /// Mirrors `DbService.openLocker`: physically unlocks the given locker.
  /// Returns true only on a confirmed success response — callers (see
  /// `MockKioskRepository`) should treat a false return the same way the
  /// Android app treats an unlock failure: log it and don't pretend the
  /// action definitely happened.
  Future<bool> unlockLocker(int lockerId) async {
    try {
      final client = _clientFor(ConfigService().lockerAddress);
      final response = await client.unlock_locker(
        LockRequest(lockerNum: lockerId),
      );
      final success = response.hasResp() && response.resp.success;
      if (success) {
        logger.i('LockerGrpcService: unlocked locker $lockerId');
      } else {
        logger.w(
          'LockerGrpcService: unlock_locker($lockerId) returned failure: '
          '${response.hasResp() ? response.resp.errMsg : "no resp"}',
        );
      }
      return success;
    } catch (e) {
      logger.w('LockerGrpcService.unlockLocker($lockerId) failed: $e');
      return false;
    }
  }

  /// Mirrors `DbService.sendSms` — submits an SMS via the unit's own
  /// `send_sms` RPC (transmitted by VaultGroup's backend) rather than just
  /// logging it locally the way the mock backend does.
  Future<bool> sendSms(String cellNum, String message) async {
    try {
      final client = _clientFor(ConfigService().lockerAddress);
      final response = await client.send_sms(
        SendSmsRequest(cellNum: cellNum, msg: message),
      );
      return response.hasResp() && response.resp.success;
    } catch (e) {
      logger.w('LockerGrpcService.sendSms failed: $e');
      return false;
    }
  }

  /// Mirrors `GrpcService.sendAuditLog` — submits an audit event via
  /// cvmain's `user_audit` RPC. On a real unit, cvmain is what actually
  /// relays this up to VaultGroup's cloud over its own MQTT session (see
  /// `UnitRegistrationService` for how *this app's* independent
  /// registration works) — this call itself is fire-and-forget from the
  /// caller's side, same as every audit call site in the Android app. See
  /// `core/registration/audit_codes.dart` for the `code`/`priority`/
  /// `level` values to pass.
  Future<bool> userAudit({
    required int code,
    required String priority,
    required String description,
    required String level,
    String parametersJson = '',
    String app = 'multi_window_app',
  }) async {
    try {
      final client = _clientFor(ConfigService().lockerAddress);
      final response = await client.user_audit(
        UserAuditLogRequest(
          version: 2,
          code: code,
          level: level,
          description: description,
          priority: priority,
          app: app,
          parametersJson: parametersJson,
        ),
      );
      return response.hasResp() && response.resp.success;
    } catch (e) {
      logger.w('LockerGrpcService.userAudit(code: $code) failed: $e');
      return false;
    }
  }

  /// Closes the current channel, if any. Not strictly required (the OS
  /// reclaims the socket on process exit), but good hygiene if this is
  /// ever used somewhere with an explicit shutdown path.
  Future<void> disposeChannel() async {
    await _channel?.shutdown();
    _channel = null;
    _client = null;
    _channelAddress = null;
  }
}
