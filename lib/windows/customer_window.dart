import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../pages/customer/home_page.dart';
import '../widgets/keyboard_host.dart';

/// The root widget for the Customer window's engine — its own `MaterialApp`
/// and `Navigator`, entirely separate from the Admin window's. See the
/// matching doc comment in `admin_window.dart` for why that separation
/// requires no extra plumbing on our part.
///
/// `home` is the ported Android kiosk customer flow (`HomePage` ->
/// Deliver/Collect/Help, and everything beneath them in `lib/pages/customer/`)
/// — replacing the earlier message-passing demo (`CustomerWelcomePage` /
/// `CustomerDetailsPage`) per the "replace demo pages" integration decision.
///
/// This window is the "Collect" station: `dropOffEnabled: false` hides that
/// half of `HomePage`'s functionality here, since drop-off lives on the
/// Admin window instead (see `admin_window.dart`). The Admin PIN gate is
/// still reachable from here too, via `HomePage`'s VG-badge 5-tap.
class CustomerWindowApp extends StatelessWidget {
  const CustomerWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Display',
      theme: ThemeData(
        colorSchemeSeed: AppColors.navy,
        scaffoldBackgroundColor: AppColors.navy,
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Metropolis',
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(dropOffEnabled: false),
      // Same reusable keyboard host as the Admin window — see its doc
      // comment in admin_window.dart. Every phone/PIN field in the ported
      // kiosk pages uses `KioskTextField` (built on `KeyboardTextField`),
      // so this on-screen keyboard now sees real use on this window too.
      builder: (context, child) => KeyboardHost(child: child ?? const SizedBox()),
    );
  }
}
