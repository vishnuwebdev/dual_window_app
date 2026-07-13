import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../pages/customer/home_page.dart';
import '../widgets/keyboard_host.dart';

/// The root widget for the Admin window's engine.
///
/// DESKTOP CONCEPT: this `MaterialApp` — and the `Navigator` it creates
/// internally — belongs *only* to this window's Flutter engine. The
/// Customer window (see `customer_window.dart`) builds a completely
/// separate `MaterialApp`/`Navigator` in a completely separate engine.
/// Pushing a route here has no way to affect, or even see, the Customer
/// window's navigation stack — they are as independent as two different
/// apps running on the same computer. That independence is "free" (you get
/// it just by each window running its own `main()`); you don't need to do
/// anything special to isolate them.
///
/// This window is the "Drop off" station: `home` is `HomePage` with
/// `collectEnabled: false`, hiding the Collect half of that shared screen
/// (Collect lives on the Customer window instead — see
/// `customer_window.dart`). The password-gated admin management flow
/// (Override/Reset/Configuration, in `lib/pages/admin/`) is reached from
/// here the same way as on the Customer window: `HomePage`'s VG-badge
/// 5-tap opens `AdminPinGatePage` -> `AdminMenuPage`.
class AdminWindowApp extends StatelessWidget {
  const AdminWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Console',
      theme: ThemeData(
        colorSchemeSeed: AppColors.navy,
        scaffoldBackgroundColor: AppColors.navy,
        useMaterial3: true,
        fontFamily: 'Metropolis',
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(collectEnabled: false),
      // Mounts the shared on-screen keyboard once, above every route this
      // window's Navigator ever pushes — see KeyboardHost's doc comment.
      builder: (context, child) => KeyboardHost(child: child ?? const SizedBox()),
    );
  }
}
