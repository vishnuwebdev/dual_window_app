import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A rounded, bordered panel grouping one settings section — the desktop
/// admin screens' counterpart to the kiosk kit's `InstructionPanel`, but
/// sized and colored for a dense settings form (multiple fields, buttons,
/// switches) rather than a full-screen touch prompt.
///
/// Shared by every admin settings screen (`ConfigurationPage`,
/// `UnitRegistrationPage`, ...) so they read as one consistent "admin
/// chrome" rather than each hand-rolling its own card style. See
/// `AppColors.adminCard`/`adminFieldFill` for the fill colors and
/// `AdminFieldDecoration`/admin button style helpers used alongside this.
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adminCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: child,
    );
  }
}

/// Text styles shared by the admin settings screens — Metropolis at sizes
/// tuned for a dense form (much smaller than the kiosk kit's
/// `AppTextStyles`, which is sized for full-screen touch prompts).
class AdminTextStyles {
  AdminTextStyles._();

  static const _family = 'Metropolis';

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.4,
    color: Colors.white70,
  );

  static const fieldInput = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    color: Colors.white,
  );
}

/// Field/button chrome shared by the admin settings screens — a dark
/// filled `InputDecoration` with a teal focus ring, and `FilledButton`/
/// `OutlinedButton` styles using the app's primary-blue and teal accents.
/// See [AdminSectionCard] for the panel these sit inside.
class AdminInputStyle {
  AdminInputStyle._();

  static InputDecoration fieldDecoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.adminFieldFill,
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Metropolis', color: Colors.white38),
      errorText: errorText,
      errorStyle: TextStyle(fontFamily: 'Metropolis', color: Colors.red[300]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
    );
  }

  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: AppColors.buttonOuter,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: AppColors.teal),
        textStyle: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
}
