import 'package:flutter/material.dart';

/// The two-row "divider line + logo" lockup shown at the top of nearly
/// every kiosk screen (`logo_5.png` on a white divider, `logo_6.png` on a
/// second, thinner divider directly beneath it). Ported from the repeated
/// `LinearLayout` block found at the top of most `res/layout/activity_*.xml`
/// files in the Android app.
class KioskHeader extends StatelessWidget {
  const KioskHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white, thickness: 2)),
              const SizedBox(width: 24),
              Image.asset('assets/images/logo_5.png', height: 48),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white, thickness: 1)),
              const SizedBox(width: 12),
              Image.asset('assets/images/logo_6.png', height: 18),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
