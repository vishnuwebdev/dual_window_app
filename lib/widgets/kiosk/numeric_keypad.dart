import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'bouncy_tap.dart';

/// The on-screen 3x4 numeric keypad used by every PIN-entry screen (Admin
/// PIN gate, Verify PIN, PIN Reset, Admin Reset, Admin Dropoff PIN) instead
/// of popping up the full QWERTY `CustomKeyboard` — those fields are
/// numeric-only, so a dedicated pad reads simpler and lets the "Enter" key
/// mean something field-specific (advance to the next PIN field, or submit
/// on the last one) rather than the QWERTY keyboard's generic "Done".
/// Reports every key through the three callbacks below; the caller owns the
/// actual text/PIN state — same shared-nothing pattern as `CustomKeyboard`.
///
/// Deliberately light-themed (white circular keys on a soft shadow)
/// regardless of which window/theme it's shown in, matching
/// `KioskTextField`'s white pill fields — see `CustomKeyboard`'s doc
/// comment for why the *other* on-screen keyboard needed the same explicit
/// fix (it used to inherit the ambient `Theme.of(context).colorScheme`,
/// which renders dark on the Customer window).
///
/// Press feedback is a real spring animation ([BouncyTap]), not the
/// instant color-swap `CustomKeyboard` uses — see that widget's doc
/// comment for why that trade-off is fine here but not on the full QWERTY
/// keyboard.
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

  static const _keySpacing = SizedBox(width: 14, height: 14);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final digit in row) ...[
                _KeypadKey(label: digit, onTap: () => onDigit(digit)),
                _keySpacing,
              ],
            ]..removeLast(),
          ),
          _keySpacing,
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeypadKey(
              icon: Icons.backspace_outlined,
              iconColor: AppColors.error,
              onTap: onBackspace,
            ),
            _keySpacing,
            _KeypadKey(label: '0', onTap: () => onDigit('0')),
            _keySpacing,
            _KeypadKey(
              icon: Icons.arrow_forward_rounded,
              filled: true,
              onTap: onEnter,
            ),
          ],
        ),
      ],
    );
  }
}

/// One key: a plain digit (light, navy text), or an accented control key
/// (backspace/enter). [filled] gives it the same solid-teal treatment as
/// `KioskButton`'s primary action, so "Enter" reads as the one key that
/// actually *does* something rather than just inserting a character.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    this.label,
    this.icon,
    this.iconColor,
    this.filled = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final bool filled;
  final VoidCallback onTap;

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.teal : Colors.white;
    final content = icon != null
        ? Icon(icon, color: filled ? Colors.white : (iconColor ?? AppColors.navy), size: 26)
        : Text(
            label!,
            style: AppTextStyles.panelText.copyWith(
              fontSize: 26,
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          );

    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (filled ? AppColors.teal : Colors.black)
                  .withOpacity(filled ? 0.35 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

