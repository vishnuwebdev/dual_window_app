import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The pill-shaped, bordered button used throughout the kiosk app: a fully
/// rounded (stadium-shaped) outer pill in [outerColor], with a slightly
/// darker inner pill in [innerColor] inset evenly on every side by
/// [borderWidth] — giving a uniform lighter-blue "rim" all the way around,
/// matching the reference button design.
class KioskButton extends StatelessWidget {
  const KioskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 270.0,
    this.height = 60.0,
    this.outerColor = AppColors.buttonOuter,
    this.innerColor = AppColors.buttonInner,
    this.borderWidth = 7.0,
    this.textStyle = AppTextStyles.buttonLabel,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color outerColor;
  final Color innerColor;

  /// Thickness of the visible outer rim on every side (top, bottom, left,
  /// right) of the pill.
  final double borderWidth;

  final TextStyle textStyle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final outer = enabled ? outerColor : AppColors.buttonDisabledOuter;
    final inner = enabled ? innerColor : AppColors.buttonDisabledInner;

    // Fully rounded "stadium" shape at every size: the radius is always
    // half the height, and the inner pill's radius shrinks to match its
    // own (smaller, inset) height so its curve stays concentric with the
    // outer one instead of looking squared-off.
    final outerRadius = height / 2;
    final innerRadius = (height - borderWidth * 2) / 2;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(outerRadius),
          onTap: enabled ? onPressed : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: outer,
                    borderRadius: BorderRadius.circular(outerRadius),
                  ),
                ),
              ),
              Positioned(
                top: borderWidth,
                left: borderWidth,
                right: borderWidth,
                bottom: borderWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: inner,
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                ),
              ),
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
