import 'dart:async';
import 'dart:io';

import 'logging.dart';

/// UDP beacon discovery for a locker unit's bridge/`cvmain` host — direct
/// port of the Android app's `BroadCastListener`/`UdpPacketSender`
/// (`za.co.vaultgroup.click_n_collect.util` in `cnc-dnp-android`), which
/// listen for `VG.BRIDGE.BEACON` broadcasts on UDP port 2320 to find a
/// unit's IP without an admin having to type it in by hand, and can send a
/// `vg.cvmain.restart` packet to a discovered IP.
///
/// Not wired into any automatic startup flow — like the Android version,
/// this is admin-triggered (see `ConfigurationPage`'s "Scan for unit"
/// button next to the locker address field), since a kiosk normally
/// already has a saved `ConfigService.lockerAddress` and only needs
/// (re)discovery when that's unknown or the unit's IP changed (e.g. a DHCP
/// lease renewal).
class BeaconDiscoveryService {
  BeaconDiscoveryService._();

  static const _beaconPort = 2320;
  static const _beaconId = 'VG.BRIDGE.BEACON';
  static const _restartMessage = 'vg.cvmain.restart';

  /// Listens on UDP port 2320 and returns the IP of the first sender whose
  /// broadcast contains [_beaconId], or `null` if none arrives within
  /// [timeout]. Mirrors `BroadcastListener.startListening`.
  static Future<String?> scanForBeacon({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final results = await scanForAllBeacons(timeout: timeout, stopAfterFirst: true);
    return results.isEmpty ? null : results.first.$2;
  }

  /// Listens for every distinct `VG.BRIDGE.BEACON` broadcast seen within
  /// [timeout], returning `(message, ip)` pairs — mirrors
  /// `startListeningForUniqueBeaconsWithinTimeout`. Useful if more than one
  /// unit is reachable on the same LAN segment and the admin needs to pick
  /// which one to point [ConfigService.lockerAddress] at.
  ///
  /// Only one process can bind UDP port 2320 at a time — if it's already
  /// taken (e.g. a real `cvmain`/bridge process on this same machine also
  /// listens on it), this logs a warning and returns an empty list rather
  /// than throwing past the caller.
  static Future<List<(String, String)>> scanForAllBeacons({
    Duration timeout = const Duration(seconds: 10),
    bool stopAfterFirst = false,
  }) async {
    final found = <(String, String)>[];
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? sub;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _beaconPort);
      socket.broadcastEnabled = true;
      logger.i('BeaconDiscoveryService: listening on UDP port $_beaconPort...');

      final completer = Completer<void>();
      sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final packet = socket!.receive();
        if (packet == null) return;
        final message = String.fromCharCodes(packet.data);
        if (!message.contains(_beaconId)) return;
        final ip = packet.address.address;
        if (found.any((f) => f.$1 == message && f.$2 == ip)) return;
        logger.i('BeaconDiscoveryService: found beacon "$message" from $ip');
        found.add((message, ip));
        if (stopAfterFirst && !completer.isCompleted) completer.complete();
      });

      await Future.any([completer.future, Future.delayed(timeout)]);
    } catch (e) {
      logger.w('BeaconDiscoveryService: scan failed (is port $_beaconPort already in use?): $e');
    } finally {
      await sub?.cancel();
      socket?.close();
    }
    return found;
  }

  /// Sends a `vg.cvmain.restart` UDP packet to [destinationIp]:[destinationPort]
  /// once a second for [durationSeconds] — mirrors
  /// `UdpPacketSender.sendPacketsForDuration`. Fire-and-forget; intended for
  /// an explicit admin "restart unit" action, never called automatically.
  static Future<void> sendRestartSignal({
    required String destinationIp,
    required int destinationPort,
    int durationSeconds = 3,
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final address = InternetAddress(destinationIp);
      final data = _restartMessage.codeUnits;
      final end = DateTime.now().add(Duration(seconds: durationSeconds));
      while (DateTime.now().isBefore(end)) {
        socket.send(data, address, destinationPort);
        await Future.delayed(const Duration(seconds: 1));
      }
      logger.i(
        'BeaconDiscoveryService: sent restart signal to '
        '$destinationIp:$destinationPort for ${durationSeconds}s.',
      );
    } catch (e) {
      logger.w('BeaconDiscoveryService: sendRestartSignal failed: $e');
    } finally {
      socket?.close();
    }
  }
}
