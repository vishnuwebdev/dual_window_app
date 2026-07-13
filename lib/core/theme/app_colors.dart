import 'package:flutter/material.dart';

/// Colors lifted directly from the Android kiosk app
/// (cnc-dnp-android `res/values/colors.xml` + drawable XMLs), so the Flutter
/// desktop screens read as "the same app" rather than a reskin.
class AppColors {
  AppColors._();

  /// Primary kiosk background — used on every full-screen page.
  static const navy = Color(0xFF1E2844);

  /// Darker navy used behind the "drop-off complete" / admin override
  /// frame, and as the base for [borderedPanel].
  static const deepNavy = Color(0xFF021E38);

  /// Divider lines either side of the header logo, dialog text color, etc.
  static const white = Colors.white;
  static const black = Colors.black;

  /// Teal/cyan accents (help confirm button, table headers, borders).
  static const teal = Color(0xFF00B2A9);
  static const tealBorder = Color(0xFF01A69C);
  static const tealAlt = Color(0xFF01B2A8);
  static const tealButtonShadow = Color(0xFF1D9BAB);

  /// Primary action button (Cancel/Continue/Deliver/Collect/Override).
  static const buttonOuter = Color(0xFF3F7AC7);
  static const buttonInner = Color(0xFF3764A0);

  /// Disabled variant of the primary button (e.g. Deliver when no lockers
  /// are free).
  static const buttonDisabledOuter = Color(0xFFABABAA);
  static const buttonDisabledInner = Color(0xFF898999);

  /// Text-field surrounding "shadow" frame.
  static const fieldShadow = Color(0xFF315489);
  static const fieldHint = Color(0xFF808080);

  /// Error red used for validation banners.
  static const error = Color(0xFFFE0100);

  /// Locker-size selection boxes (Deliver -> Locker Select).
  static const boxDefaultOuter = Color(0xFF01B2A8);
  static const boxDefaultInner = Colors.white;
  static const boxSelectedOuter = Color(0xFF417EC9);
  static const boxSelectedInner = Color(0xFF01B2A8);
  static const boxInactiveOuter = Color(0xFF969699);
  static const boxInactiveInner = Color(0xFFA6A9AA);
  static const boxDivider = Color(0xFF1F2B45);

  /// Locker-count bubble + dialog close "X" circle.
  static const countBubble = Color(0xFF417EC9);
  static const dialogCloseCircle = Color(0xFF407EC9);

  /// Confirmation/instruction panel (collect/place-parcel, dialog boxes).
  static const panelBorder = Color(0xFF1F2B45);
  static const panelShadow = Color(0xFF417EC9);

  /// Section-card fill and text-field fill used by the admin settings
  /// screens (`ConfigurationPage`, `UnitRegistrationPage`) — a lighter
  /// tint of [navy] so panels/fields read as distinct surfaces against the
  /// full-screen navy background, and a darker tint for recessed fields.
  /// Not from the Android app (those screens didn't exist there); kept in
  /// the same navy/teal family so they still read as "the same app".
  static const adminCard = Color(0xFF262F58);
  static const adminFieldFill = Color(0xFF1A2340);
}
