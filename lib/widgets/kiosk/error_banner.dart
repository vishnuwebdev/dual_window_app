import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The red circular "X" + italic red message shown under form fields when
/// validation fails, matching `red_circle_background.xml` +
/// `ErrorTextAppearance` in the Android app.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.visible = true});

  final String message;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'X',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Text(message, style: AppTextStyles.error),
          ),
        ],
      ),
    );
  }
}
