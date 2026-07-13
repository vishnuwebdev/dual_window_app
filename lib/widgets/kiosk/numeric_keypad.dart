import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The on-screen 3x4 numeric keypad used by PIN-entry gates that don't
/// want the full QWERTY `CustomKeyboard` — e.g. the "tap the VG badge 5
/// times" Admin PIN gate. Reports every key through the three callbacks
/// below; the caller owns the actual text/PIN state.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onEnter,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final digit in row) ...[
                  _KeypadKey(label: digit, onTap: () => onDigit(digit)),
                  const SizedBox(width: 12),
                ],
              ]..removeLast(),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeypadKey(
              icon: Icons.arrow_back,
              color: AppColors.error,
              onTap: onBackspace,
            ),
            const SizedBox(width: 12),
            _KeypadKey(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: 12),
            _KeypadKey(
              icon: Icons.arrow_forward,
              color: AppColors.teal,
              onTap: onEnter,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({this.label, this.icon, this.color, required this.onTap});

  final String? label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Center(
            child: icon != null
                ? Icon(icon, color: color ?? AppColors.navy, size: 28)
                : Text(
                    label!,
                    style: AppTextStyles.panelText.copyWith(fontSize: 26),
                  ),
          ),
        ),
      ),
    );
  }
}
