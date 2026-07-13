import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles matching the Android kiosk app, which uses the "Metropolis"
/// font family in three weights (regular, bold, extra-bold). See
/// `pubspec.yaml` for the font registration and `assets/fonts/` for the
/// actual `.otf` files (copied from cnc-dnp-android `res/font/`).
class AppTextStyles {
  AppTextStyles._();

  static const _family = 'Metropolis';

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.bold,
    fontSize: 22,
    color: AppColors.white,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: _family,
    fontStyle: FontStyle.italic,
    fontSize: 18,
    color: AppColors.white,
  );

  static const TextStyle fieldInput = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    color: AppColors.navy,
  );

  static const TextStyle error = TextStyle(
    fontFamily: _family,
    fontStyle: FontStyle.italic,
    fontSize: 18,
    color: AppColors.error,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 26,
    color: AppColors.white,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    color: AppColors.white,
  );

  static const TextStyle panelText = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.bold,
    fontSize: 26,
    color: AppColors.navy,
  );

  static const TextStyle boxLabel = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    color: AppColors.black,
  );

  static const TextStyle boxCount = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    color: AppColors.black,
  );
}
