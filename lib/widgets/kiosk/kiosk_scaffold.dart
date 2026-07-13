import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Which corner the decorative "waves" image sits in. The Android app
/// always puts the VaultGroup logo badge in the *opposite* bottom corner
/// from the waves — see the per-screen mapping in cnc-dnp-android's
/// `res/layout/*.xml` (grepped while porting: waves.png -> bottom-left +
/// badge bottom-right, waves_reflected.png -> bottom-right + badge
/// bottom-left).
enum KioskWaves { left, right, none }

/// Full-screen navy kiosk background shared by (almost) every screen in
/// the Android app: solid `#1E2844`, a waves image tucked into one bottom
/// corner, and the small VaultGroup square badge in the other. Screens that
/// don't use this pattern (Privacy Statement, Drop-off Complete,
/// Configuration) build their own background instead of using this widget.
///
/// Home is the one screen with extra bottom-corner content (the Help
/// button, and a tap-to-open debug menu on the badge) — it passes
/// `showBadge: false` here and builds its own `Positioned` widgets in its
/// own `Stack` instead of routing through [badge], keeping this widget
/// simple for the other 15 screens that just want the plain badge.
class KioskScaffold extends StatelessWidget {
  const KioskScaffold({
    super.key,
    required this.child,
    this.waves = KioskWaves.left,
    this.showBadge = true,
    this.backgroundColor = AppColors.navy,
  });

  final Widget child;
  final KioskWaves waves;
  final bool showBadge;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final badgeOnRight = waves == KioskWaves.left;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          if (waves == KioskWaves.left)
            const Positioned(
              left: 0,
              bottom: 0,
              child: _WavesImage(asset: 'assets/images/waves.png'),
            ),
          if (waves == KioskWaves.right)
            const Positioned(
              right: 0,
              bottom: 0,
              child: _WavesImage(asset: 'assets/images/waves_reflected.png'),
            ),
          if (showBadge)
            Positioned(
              left: badgeOnRight ? null : 16,
              right: badgeOnRight ? 16 : null,
              bottom: 20,
              child: Image.asset(
                'assets/images/vg_square_blue.png',
                width: 56,
                height: 56,
              ),
            ),
          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

class _WavesImage extends StatelessWidget {
  const _WavesImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, width: 340, height: 230, fit: BoxFit.contain);
  }
}
