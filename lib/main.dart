import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

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
}

Future<void> _runCustomerWindow() async {
  MessagingService.instance.startListeningAsCustomer();

  await WindowService.configureAndShow(AppWindowRole.customer);

  runApp(const CustomerWindowApp());
}
