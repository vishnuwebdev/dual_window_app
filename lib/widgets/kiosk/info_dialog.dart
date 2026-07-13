import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Recreates `select_locker_dialog.xml`: a white, thick-navy-bordered
/// message box with a blue circular "X" close button pinned to its top
/// right corner, floating over a solid blue drop-shadow panel. Used for
/// every "toast-like" modal in the Android app (wrong PIN, no lockers of
/// that size, PIN/password reset confirmation, etc).
///
/// Call [show] instead of `showDialog` directly so every call site gets the
/// same look for free.
class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key, required this.message, this.onClose});

  final String message;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InfoDialog(
        message: message,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, right: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: AppColors.panelShadow),
              child: Transform.translate(
                offset: const Offset(-24, -24),
                child: Container(
                  width: 460,
                  constraints: const BoxConstraints(minHeight: 220),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.panelBorder, width: 6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.panelText,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -14,
              top: -14,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.of(context, rootNavigator: false).pop();
                    onClose?.call();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.dialogCloseCircle,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
