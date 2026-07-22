import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import 'core/config/config_service.dart';
import 'core/mock/mock_kiosk_repository.dart';
import 'core/registration/auto_sync_service.dart';
import 'core/registration/mqtt_sync_service.dart';
import 'core/registration/unit_registration_service.dart';
import 'models/window_type.dart';
import 'services/messaging_service.dart';
import 'services/window_service.dart';
import 'windows/admin_window.dart';
import 'windows/customer_window.dart';

/// Single entrypoint for *every* window.
///
/// DESKTOP CONCEPT: with `desktop_multi_window`, there is only ever one
/// compiled app. Every window — the first one the OS launches, and every
/// one your own code creates afterwards — starts by running this exact
/// same `main()` in its own fresh Flutter engine. The only thing that
/// differs between them is the `arguments` string the engine was launched
/// with, which is why the very first thing we do is ask
/// `WindowController.fromCurrentEngine()` who we are, then branch.
///
/// This is a different mental model from mobile/web, where `main()` runs
/// exactly once per app launch. Here it's "once per *window*".
Future<void> main(List<String> args) async {
  // Required before calling any platform channel (which is what both
  // window_manager and desktop_multi_window use under the hood), in every
  // single engine — including sub-windows, not just the first one.
  WidgetsFlutterBinding.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();
  final role = WindowArgs.decode(windowController.arguments).role;

  // Every window's own engine needs `config.json` loaded before any page
  // reads the admin PIN, drop-off PIN, SMS template, or locker mapping.
  await ConfigService().initialize();

  // Likewise, load `db.json` (the drop-off/collection parcel records)
  // before any page reads or writes items — mirrors the Android app's
  // `DbService` reading `db.json` on startup. Must come after
  // `ConfigService().initialize()` since building `MockKioskRepository`
  // syncs its locker list from `ConfigService.lockerMapping`.
  await MockKioskRepository.instance.initialize();

  // Load any existing unit registration (auth.json) before any admin page
  // reads UnitRegistrationService.isRegistered/username — see
  // core/registration/unit_registration_service.dart. Cheap local file
  // read only (no network), so it's safe to await here like the two
  // services above.
  await UnitRegistrationService.instance.initialize();

  switch (role) {
    case AppWindowRole.admin:
      await _runAdminWindow();
    case AppWindowRole.customer:
      await _runCustomerWindow();
  }
}

Future<void> _runAdminWindow() async {
  // Register this engine as the handler for acknowledgements coming back
  // from the Customer window *before* building any UI that might read
  // MessagingService's status, so no early message is missed.
  MessagingService.instance.startListeningAsAdmin();

  await WindowService.configureAndShow(AppWindowRole.admin);

  runApp(const AdminWindowApp());

  // "Window 2 opens automatically after Window 1": fire-and-forget the
  // Customer window's creation right after Admin is up. We don't `await`
  // this inside the synchronous startup path because there's no reason to
  // delay showing the Admin window while the Customer window's own engine
  // spins up in parallel.
  unawaited(WindowService.openOrCreateCustomerWindow());

  // Cloud MQTT push-trigger sync (see MqttSyncService) is owned by the
  // Admin window's engine only — never the Customer window's — so there's
  // exactly one broker session per running app, not one per window (each
  // window is its own Flutter engine/isolate; see the class doc comment on
  // `MessagingService` for the same "each window is separate" caveat).
  // Fire-and-forget: a no-op if the unit isn't registered yet (no
  // mq.json), and every failure inside is caught and logged rather than
  // thrown past here.
  unawaited(MqttSyncService.instance.start());

  // Automatic device -> cloud push on every local config/db change — see
  // AutoSyncService's class doc comment. Same "one owner, Admin window
  // only" reasoning as MqttSyncService above. Synchronous (just registers
  // listeners), so no need for `unawaited`.
  AutoSyncService.instance.start();
}

Future<void> _runCustomerWindow() async {
  MessagingService.instance.startListeningAsCustomer();

  await WindowService.configureAndShow(AppWindowRole.customer);

  runApp(const CustomerWindowApp());
}
