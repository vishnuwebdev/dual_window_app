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
/// Deliberately light-themed (white keys) regardless of which window/theme
/// it's shown in, matching `KioskTextField`'s white pill fields — see
/// `CustomKeyboard`'s doc comment for why the *other* on-screen keyboard
/// needed the same explicit fix (it used to inherit the ambient
/// `Theme.of(context).colorScheme`, which renders dark on the Customer
/// window).
///
/// Restyled 2026-07-25 to match a reference design directly: white
/// rounded-square keys sitting on a solid navy "shadow block" offset to
/// the bottom-right — see `_KeypadKey`'s doc comment for the technique —
/// rather than the circular keys with a soft blurred drop shadow this had
/// before.
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

  static const _keySpacing = SizedBox(width: 16, height: 16);

  // Reference design's "Enter" arrow is green — not one of `AppColors`'
  // existing named colors (that family is navy/teal/blue), so it's kept
  // local to this one accent rather than added there for a single use.
  static const _enterGreen = Color(0xFF3DC26B);

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
              icon: Icons.arrow_back,
              iconColor: AppColors.error,
              onTap: onBackspace,
            ),
            _keySpacing,
            _KeypadKey(label: '0', onTap: () => onDigit('0')),
            _keySpacing,
            _KeypadKey(
              icon: Icons.arrow_forward,
              iconColor: _enterGreen,
              onTap: onEnter,
            ),
          ],
        ),
      ],
    );
  }
}

/// One key: a plain digit (bold navy text) or a control key (backspace/
/// enter, a colored circle-outline arrow icon — red/green respectively).
/// Neither ever gets a solid color fill; the only color besides white/navy
/// is the thin icon-circle stroke, matching the reference design exactly.
///
/// The "shadow" is a solid navy block, not a blurred `BoxShadow` — same
/// layered-panel technique `InfoDialog` uses for its close-button frame
/// and `KioskTextField` uses for its input pills (see those widgets' doc
/// comments): a [DecoratedBox] the same size as the key sits behind,
/// offset down-and-right by [_shadowOffset], and the white key face sits
/// in front at the Stack's origin — so the navy peeks out only along the
/// bottom and right edges, reading as a simple extruded 3D block rather
/// than a soft ambient shadow.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    this.label,
    this.icon,
    this.iconColor,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  static const _size = 74.0;
  static const _shadowOffset = 6.0;
  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final content = icon != null
        ? _IconBadge(icon: icon!, color: iconColor ?? AppColors.navy)
        : Text(
            label!,
            style: AppTextStyles.panelText.copyWith(
              fontSize: 28,
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          );

    return BouncyTap(
      onTap: onTap,
      child: SizedBox(
        width: _size + _shadowOffset,
        height: _size + _shadowOffset,
        child: Stack(
          children: [
            Positioned(
              left: _shadowOffset,
              top: _shadowOffset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.fieldShadow,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: const SizedBox(width: _size, height: _size),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(child: content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The backspace/enter icon treatment: a thin circle outline (no fill) in
/// [color] around the arrow, rather than a filled circle or a plain bare
/// icon — matches the reference design's two control keys.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 18),
    );
  }
}
