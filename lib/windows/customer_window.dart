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
        // Stock Material buttons (Elevated/Outlined/Text/Icon/Filled) each
        // supply their own hover cursor by default, which wins over the
        // root MouseRegion below since cursor resolution picks the deepest
        // region that sets one. Forcing it to `none` here at the theme
        // level covers every button on this window without touching each
        // call site individually — see also the explicit `mouseCursor`
        // added to the few raw `InkWell`s, which aren't covered by these
        // button themes.
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.none),
          ),
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.none),
          ),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.none),
          ),
        ),
        filledButtonTheme: const FilledButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.none),
          ),
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.none),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(dropOffEnabled: false),
      // Same reusable keyboard host as the Admin window — see its doc
      // comment in admin_window.dart. Every phone/PIN field in the ported
      // kiosk pages uses `KioskTextField` (built on `KeyboardTextField`),
      // so this on-screen keyboard now sees real use on this window too.
      // Wrapped in a cursor-less MouseRegion since this is a touch-only
      // kiosk: there's no mouse, so the OS pointer should never be drawn.
      builder: (context, child) => MouseRegion(
        cursor: SystemMouseCursors.none,
        child: KeyboardHost(child: child ?? const SizedBox()),
      ),
    );
  }
}
