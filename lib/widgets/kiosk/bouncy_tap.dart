import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Wraps [child] with a real spring-physics press animation: a quick
/// shrink on touch-down, then a `SpringSimulation` release that overshoots
/// past its resting scale before settling — reads as "bouncy" rather than
/// a plain `Curves.elasticOut`-style canned curve.
///
/// Extracted from `NumericKeypad`'s original private `_BouncyKey` (kept
/// there deliberately unlike the full QWERTY `CustomKeyboard`, which uses
/// a plain instant color swap with no animation at all — see that
/// widget's doc comment on why up to ~30 simultaneously-animating keys is
/// too much for the Raspberry Pi kiosk hardware's weak GPU). A handful of
/// `BouncyTap`s on screen at once (a numeric keypad, an admin menu grid)
/// is cheap; reach for the plain instant-feedback pattern instead if a
/// screen ever needs many more than that on screen simultaneously.
class BouncyTap extends StatefulWidget {
  const BouncyTap({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  // Slightly underdamped so the release overshoots past 1.0 before
  // settling — that overshoot is what reads as "bouncy" rather than just
  // a smoothed-out resize.
  static const _spring = SpringDescription(mass: 0.5, stiffness: 500, damping: 16);

  late final _controller = AnimationController(vsync: this, value: 1)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pressDown() {
    _controller.stop();
    _controller.animateTo(
      0.88,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _release() {
    _controller.animateWith(SpringSimulation(_spring, _controller.value, 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressDown(),
      onTapCancel: _release,
      onTapUp: (_) => _release(),
      onTap: widget.onTap,
      child: Transform.scale(scale: _controller.value, child: widget.child),
    );
  }
}
