import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../utilities/logging.dart';
import 'settings_sync_service.dart';

/// Subscribes to VaultGroup's cloud MQTT broker so a fresh push can be
/// triggered the moment the cloud asks for one — the read-only-for-cloud
/// counterpart to `ClickNCollectApp.onCreate`'s `MqttRunner.startProcess`
/// callback in the Android app (`cnc-dnp-android`), which reacts to
/// `upload-settings` / `get-settings` / `upload-db`.
///
/// DELIBERATELY PUSH-ONLY: every one of those three commands — regardless
/// of which one arrives — just calls [SettingsSyncService.pushToServer]
/// here, never a pull. See [SettingsSyncService]'s class doc comment for
/// why a cloud -> device pull was removed entirely (it silently overwrote
/// this unit's real locker mapping/pairing the first time it was tried).
/// In practice [AutoSyncService] already pushes automatically on every
/// local change, so this mostly exists so VaultGroup's dashboard doesn't
/// have to wait for the next local edit if it wants a fresh read right
/// now.
///
/// UNCONFIRMED PROTOCOL DETAILS: the Android app's actual MQTT topic
/// name(s)/subscription pattern live inside a closed-source vendor AAR
/// (`com.cellvault.libcvmqtt`/`MqttRunner` — see `MIGRATION_FEASIBILITY.md`
/// §2 in this repo), not anything with visible source here or in the
/// Android repo. This implementation's best-effort guess, to be corrected
/// against the real broker once verified:
///  - Subscribes to `<username>/#` — every topic under this unit's own
///    registered identity (see `UnitRegistrationService.username`), on the
///    assumption commands are scoped per-unit the same way audit events
///    are (see `LockerGrpcService.userAudit`).
///  - On every message, checks *both* the topic and the decoded payload
///    text for the substrings `"upload-settings"`, `"get-settings"`, and
///    `"upload-db"` — matching Android's own tolerant `.contains(...)`
///    check rather than assuming an exact topic match. All three now do
///    the exact same thing (push), so this is really just "did the cloud
///    say anything that looks like a sync request" — if that turns out to
///    be too broad (e.g. false-triggers on unrelated traffic), narrow
///    [_onMessage] once the real topic shape is confirmed.
class MqttSyncService extends ChangeNotifier {
  MqttSyncService._();

  static final MqttSyncService instance = MqttSyncService._();

  MqttServerClient? _client;
  bool _connecting = false;

  File get _mqFile => File('${Directory.current.path}/mq.json');

  String _status = 'Not started';
  String get status => _status;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  void _setStatus(String value) {
    _status = value;
    logger.i('MqttSyncService: $value');
    notifyListeners();
  }

  /// Connects using the broker URI/username/password
  /// `UnitRegistrationService.refreshJwt` wrote to `mq.json` — the same
  /// file [SettingsSyncService] reads its JWT from. No-op if `mq.json`
  /// doesn't exist yet (unit not registered) or a connection attempt is
  /// already in flight. Safe to call repeatedly (e.g. right after
  /// "Refresh JWT" on the Unit Registration page gets a new password) —
  /// disconnects any existing session and reconnects with the latest
  /// credentials.
  Future<void> start() async {
    if (_connecting) return;
    _connecting = true;
    try {
      if (!await _mqFile.exists()) {
        _setStatus('Not registered — no mq.json yet.');
        return;
      }

      final json =
          jsonDecode(await _mqFile.readAsString()) as Map<String, dynamic>;
      final serverUri = json['server_uri'] as String?;
      final username = json['username'] as String?;
      final password = json['password'] as String?;
      if (serverUri == null || username == null || password == null) {
        _setStatus('mq.json is missing server_uri/username/password.');
        return;
      }

      await _disconnectQuietly();

      Uri uri;
      try {
        uri = Uri.parse(serverUri);
      } catch (e) {
        _setStatus('Could not parse server_uri "$serverUri": $e');
        return;
      }
      final host = uri.host;
      final port = uri.hasPort ? uri.port : 1883;
      final secure = uri.scheme == 'ssl' || uri.scheme == 'tls';
      if (host.isEmpty) {
        _setStatus('server_uri "$serverUri" has no host.');
        return;
      }

      final clientId =
          'multi-window-app-$username-${DateTime.now().millisecondsSinceEpoch}';
      final client = MqttServerClient.withPort(host, clientId, port);
      client.secure = secure;
      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.autoReconnect = true;
      client.onDisconnected = () => _setStatus('Disconnected from $host:$port');
      client.onConnected = () => _setStatus('Connected to $host:$port as $username');
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean();

      _client = client;
      _setStatus('Connecting to $host:$port...');

      try {
        await client.connect();
      } catch (e) {
        _setStatus('Connection failed: $e');
        client.disconnect();
        return;
      }

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _setStatus('Connection refused: ${client.connectionStatus?.returnCode}');
        return;
      }

      final topicFilter = '$username/#';
      client.subscribe(topicFilter, MqttQos.atLeastOnce);
      client.updates!.listen(_onMessage);
      logger.i('MqttSyncService: subscribed to "$topicFilter".');
    } catch (e) {
      _setStatus('start() failed: $e');
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final publish = event.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(publish.payload.message);
      // See the class doc comment's UNCONFIRMED PROTOCOL DETAILS note —
      // checking both topic and payload text, tolerant `.contains`, same
      // as Android's own check.
      final haystack = '${event.topic} $payload';
      logger.d('MqttSyncService: message on "${event.topic}": $payload');

      final isSyncRequest = haystack.contains('upload-settings') ||
          haystack.contains('get-settings') ||
          haystack.contains('upload-db');
      if (isSyncRequest) {
        logger.i('MqttSyncService: sync command received on "${event.topic}" — pushing current state to cloud.');
        unawaited(SettingsSyncService.instance.pushToServer());
      }
    }
  }

  Future<void> _disconnectQuietly() async {
    try {
      _client?.disconnect();
    } catch (_) {
      // Best-effort — a client that never fully connected can throw here;
      // it's about to be discarded either way.
    }
    _client = null;
  }

  Future<void> stop() async {
    await _disconnectQuietly();
    _setStatus('Stopped');
  }
}
