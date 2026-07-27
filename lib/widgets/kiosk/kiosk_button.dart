import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'bouncy_tap.dart';

/// The pill-shaped, bordered button used throughout the kiosk app: a fully
/// rounded (stadium-shaped) outer pill in [outerColor], with a slightly
/// darker inner pill in [innerColor] inset evenly on every side by
/// [borderWidth] — giving a uniform lighter-blue "rim" all the way around,
/// matching the reference button design.
///
/// Press feedback is [BouncyTap]'s spring-bounce (2026-07-25, replacing
/// `Material`/`InkWell`'s ripple) — the same widget `NumericKeypad` and the
/// admin menu's grid tiles use, so every tappable control in the app now
/// shares one consistent press feel instead of this being the one place
/// still using a plain Material ripple. Unlike `CustomKeyboard`'s ~30
/// simultaneously-tappable keys (deliberately *not* animated — see its doc
/// comment on the Raspberry Pi kiosk hardware's weak GPU), a screen only
/// ever shows 2-3 `KioskButton`s at once, so the same budget concern
/// doesn't apply here.
class KioskButton extends StatelessWidget {
  const KioskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 270.0,
    this.height = 90.0,
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
    // Disabled either explicitly (`enabled: false`) or implicitly (no
    // `onPressed` handler given) — mirrors the old `InkWell(onTap: enabled
    // ? onPressed : null)` check, just evaluated up front since `BouncyTap`
    // (unlike `InkWell`) has no built-in "disabled" state of its own: a
    // disabled button skips it entirely rather than passing a null tap
    // handler.
    final isEnabled = enabled && onPressed != null;
    final outer = isEnabled ? outerColor : AppColors.buttonDisabledOuter;
    final inner = isEnabled ? innerColor : AppColors.buttonDisabledInner;

    // Fully rounded "stadium" shape at every size: the radius is always
    // half the height, and the inner pill's radius shrinks to match its
    // own (smaller, inset) height so its curve stays concentric with the
    // outer one instead of looking squared-off.
    final outerRadius = height / 2;
    final innerRadius = (height - borderWidth * 2) / 2;

    final pill = Stack(
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
    );

    return SizedBox(
      width: width,
      height: height,
      child: isEnabled
          ? BouncyTap(onTap: onPressed!, child: pill)
          : pill,
    );
  }
}
