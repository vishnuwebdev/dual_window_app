import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../core/config/config_service.dart';
import '../models/window_type.dart';

/// Everything related to *creating* and *placing* native OS windows lives
/// here. `WindowService` doesn't know anything about admin/customer
/// business logic (that's `MessagingService`'s job) — it only knows how to
/// spawn a window for a given [AppWindowRole] and where that window belongs
/// on screen. Keeping this out of widgets means a widget's `onPressed`
/// never touches `window_manager` or `desktop_multi_window` directly.
class WindowService {
  WindowService._();

  /// Creates the Customer window if one doesn't already exist, or brings
  /// the existing one to the front. Used both for the automatic "open
  /// Customer window on startup" behavior and for the optional manual
  /// "Open Customer Window" button.
  static Future<void> openOrCreateCustomerWindow() async {
    final existingWindows = await WindowController.getAll();
    for (final controller in existingWindows) {
      final role = WindowArgs.decode(controller.arguments).role;
      if (role == AppWindowRole.customer) {
        await controller.show();
        return;
      }
    }

    // `hiddenAtLaunch: true` because the new window's own `main()` (see
    // lib/main.dart) will size, position, and reveal itself once it has
    // figured out where it should sit on screen. This avoids a visible
    // "flash" of a default-sized, wrongly-positioned window before our own
    // placement logic runs.
    await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: const WindowArgs(role: AppWindowRole.customer).encode(),
      ),
    );
  }

  /// Sizes, positions, and reveals *this* window (the one whose `main()`
  /// is currently running). `window_manager` always acts on "the current
  /// engine's own window" — there is no API to reposition a *different*
  /// window's engine from here, which is why this must be called from
  /// inside every window's own startup code (see lib/main.dart), never
  /// from the Admin window on the Customer window's behalf.
  static Future<void> configureAndShow(AppWindowRole role) async {
    await windowManager.ensureInitialized();

    final placement = await _resolvePlacement(role);

    final options = WindowOptions(
      size: placement.size,
      title: role == AppWindowRole.admin ? 'Admin Console' : 'Customer Display',
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setPosition(placement.position);

      // --- RASPBERRY PI KIOSK MODE ---------------------------------------
      // Each window fills its entire HDMI output with no title bar when
      // `ConfigService.kioskMode` is on (see the Configuration page's
      // "Kiosk mode" switch, or set `"kiosk_mode": true` directly in
      // config.json). Off by default so day-to-day development on
      // macOS/Windows/Linux desktop still gets normal window chrome you can
      // drag/resize freely. `ConfigService().initialize()` has already run
      // by the time this is called — see `main.dart`.
      if (ConfigService().kioskMode) {
        await windowManager.setAsFrameless();
        await windowManager.setFullScreen(true);
      }

      await windowManager.show();
      await windowManager.focus();
    });
  }

  static Future<_Placement> _resolvePlacement(AppWindowRole role) async {
    // screen_retriever reports every physical display attached to the
    // machine, in the OS's *virtual desktop* coordinate space (the same
    // space macOS/X11/Wayland use when you drag a window from one monitor
    // to another).
    final displays = await screenRetriever.getAllDisplays();

    if (displays.length >= 2) {
      // ---------------------------------------------------------------
      // THIS is the block that matters for the Raspberry Pi: with two
      // HDMI monitors connected, `displays` has two entries. We put the
      // Admin window on the first physical display and the Customer
      // window on the second. Swap the indices below if your two HDMI
      // ports are wired up in the opposite physical order.
      // ---------------------------------------------------------------
      final display = role == AppWindowRole.admin ? displays[0] : displays[1];
      final origin = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;
      return _Placement(position: origin, size: size);
    }

    // ---------------------------------------------------------------
    // Single-display development fallback (your Mac): there's no second
    // monitor to put the Customer window on, so instead we split the one
    // display into a left half (Admin) and right half (Customer). This
    // satisfies "position both windows so they do not overlap" during
    // day-to-day development.
    // ---------------------------------------------------------------
    final display = displays.first;
    final origin = display.visiblePosition ?? Offset.zero;
    final fullSize = display.visibleSize ?? display.size;
    final halfWidth = fullSize.width / 2;
    final size = Size(halfWidth - 80, fullSize.height * 0.75);

    final position = role == AppWindowRole.admin
        ? Offset(origin.dx + 40, origin.dy + 60)
        : Offset(origin.dx + halfWidth + 40, origin.dy + 60);

    return _Placement(position: position, size: size);
  }
}

class _Placement {
  const _Placement({required this.position, required this.size});
  final Offset position;
  final Size size;
}
