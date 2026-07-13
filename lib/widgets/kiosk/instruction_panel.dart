import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The bordered white instruction card used on Collection Complete, Deliver
/// Place Parcel, and Deliver Disclaimer ("Please collect your parcel from
/// locker X...", the disclaimer text, etc). Matches
/// `dialog_shadow_background.xml` (blue drop-shadow offset) layered behind
/// `edittext_black_square_border.xml` (white panel, thick navy border).
class InstructionPanel extends StatelessWidget {
  const InstructionPanel({
    super.key,
    required this.text,
    this.width = 640,
    this.height = 320,
    this.fontSize = 26,
  });

  final String text;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.panelShadow),
        child: Transform.translate(
          offset: const Offset(-14, -14),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.panelBorder, width: 6),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.panelText.copyWith(fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }
}
