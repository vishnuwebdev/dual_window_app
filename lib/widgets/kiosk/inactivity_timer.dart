import 'dart:async';

import 'package:flutter/material.dart';

/// Idle timeout used by every screen under `lib/pages/admin/` (once
/// authenticated past the PIN gate) — longer than the 30s kiosk-wide
/// default (see [InactivityTimerMixin.inactivityTimeout]) because admin
/// screens involve reading, typing, and deliberating (editing a locker
/// mapping, composing an SMS template, confirming a factory reset), not
/// the quick tap-and-go interactions the 30s default is tuned for.
/// `AdminPinGatePage` deliberately does *not* use this — it's a PIN entry
/// screen sitting exposed on the public customer kiosk before any
/// authentication has happened, so it keeps the stricter 30s default
/// rather than leaving an unlocked-looking prompt open for 5 minutes.
const kAdminInactivityTimeout = Duration(minutes: 1);

/// Recreates the inactivity-timeout pattern found on almost every Android
/// activity in the kiosk app: a `Handler.postDelayed` timer that fires
/// after ~30 seconds of no touch input and navigates back to the Home
/// screen, reset on every `onUserInteraction()`.
///
/// Usage: mix into a `State`, call [startInactivityTimer] once (typically
/// from `initState`), and wrap the page's root widget with
/// [wrapWithActivityDetector] so any tap/drag resets the clock.
mixin InactivityTimerMixin<T extends StatefulWidget> on State<T> {
  Timer? _inactivityTimer;

  /// Matches `UtilService.INACTIVITY_TIMEOUT_HALF_MINUTE` (30s) used by
  /// most Android activities. Override per-page where the original used a
  /// different value (e.g. Collection Complete adds +10s).
  Duration get inactivityTimeout => const Duration(seconds: 30);

  /// Called when the user has been idle for [inactivityTimeout]. Pages
  /// override this to navigate back to Home, matching each Activity's
  /// `navigateToMainActivity()`.
  void onInactivityTimeout();

  void startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, onInactivityTimeout);
  }

  void resetInactivityTimer() {
    if (!mounted) return;
    startInactivityTimer();
  }

  void stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Wrap the page's root widget with this so any pointer activity
  /// anywhere on screen resets the idle clock — equivalent to overriding
  /// `onUserInteraction()` on the Android `Activity`.
  Widget wrapWithActivityDetector(Widget child) {
    return Listener(
      onPointerDown: (_) => resetInactivityTimer(),
      onPointerMove: (_) => resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
