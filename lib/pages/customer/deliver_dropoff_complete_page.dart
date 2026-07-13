import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ported from `DeliverDropoffCompleteActivity` /
/// `activity_deliver_dropoff_complete.xml`: a simple confirmation card,
/// auto-returning to Home after 9 seconds. See `deliver_place_parcel_page.dart`
/// for how this screen is now reachable in this port.
class DeliverDropoffCompletePage extends StatefulWidget {
  const DeliverDropoffCompletePage({super.key});

  @override
  State<DeliverDropoffCompletePage> createState() => _DeliverDropoffCompletePageState();
}

class _DeliverDropoffCompletePageState extends State<DeliverDropoffCompletePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 9), () {
      if (!mounted) return;
      // Pop back to the existing root `HomePage` route (each window's
      // `MaterialApp.home`) instead of pushing a fresh one — a fresh
      // `HomePage()` would use its default `dropOffEnabled`/
      // `collectEnabled` rather than this window's actual role, showing
      // the wrong buttons (e.g. "Collect" on the drop-off-only Admin
      // window).
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            border: Border.all(color: AppColors.tealBorder, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Drop off complete\n\n'
            'The recipient will receive a one-time-pin via SMS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Metropolis',
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
