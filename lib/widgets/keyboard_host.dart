import 'package:flutter/material.dart';

import 'custom_keyboard.dart';
import 'virtual_keyboard_controller.dart';

/// Mount once per window, via `MaterialApp(builder: ...)` — see
/// `AdminWindowApp`/`CustomerWindowApp`. Renders the window's normal
/// content, plus a `CustomKeyboard` pinned to the bottom edge whenever
/// [VirtualKeyboardController.instance] is visible.
///
/// Deliberately a `Stack` overlay rather than something inline in the page
/// layout: an overlay sits on top of existing content instead of pushing
/// it up and squeezing the available height, which is both how a real
/// mobile keyboard behaves and what avoids bottom-overflow when the
/// keyboard opens on a short window.
///
/// Show/hide is an instant mount/unmount — no slide-in transition. This
/// used to animate in via `AnimatedSlide` (200ms), but on the Raspberry Pi
/// kiosk hardware this app targets, the weak GPU struggles to composite
/// that animation smoothly alongside everything else on screen (two full
/// window engines, `Material` elevation/ink on ~30 keys), so it showed up
/// as visible stutter rather than a polished transition. Unmounting the
/// keyboard entirely while hidden (instead of keeping it built off-screen)
/// is also cheaper at rest, since there's nothing for the engine to layout
/// or paint at all when no field is focused.
class KeyboardHost extends StatelessWidget {
  const KeyboardHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = VirtualKeyboardController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ready = controller.visible &&
            controller.onCharacter != null &&
            controller.onBackspace != null &&
            controller.onDone != null;

        // Report this overlay keyboard's height as a bottom "view inset" on
        // everything beneath it — exactly the signal a real system keyboard
        // sends via `MediaQuery.viewInsets.bottom` — so `Scaffold`'s default
        // `resizeToAvoidBottomInset` shrinks the page underneath it, and any
        // focused `TextField`'s built-in scroll-into-view-on-focus (which
        // already reacts to `viewInsets` changes) auto-scrolls it above the
        // keyboard instead of leaving it hidden underneath. Only applied
        // while `ready`, using the last-measured height (0 until the first
        // post-layout report — see `_MeasureAndReport` — lands, a frame
        // after the keyboard first mounts).
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = ready ? controller.keyboardHeight : 0.0;
        // `EdgeInsets` has no `copyWith` (unlike `MediaQueryData`), so the
        // adjusted insets are rebuilt field-by-field from the current ones.
        final currentInsets = mediaQuery.viewInsets;
        final adjustedChild = MediaQuery(
          data: mediaQuery.copyWith(
            viewInsets: EdgeInsets.only(
              left: currentInsets.left,
              top: currentInsets.top,
              right: currentInsets.right,
              bottom: currentInsets.bottom + bottomInset,
            ),
          ),
          child: child,
        );

        return Stack(
          children: [
            Positioned.fill(child: adjustedChild),
            if (ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // Since Flutter 3.7, TextField auto-unfocuses on any tap
                // that lands "outside" it. The keyboard lives in this
                // separate Stack overlay, so without this wrapper every
                // key tap would count as an outside tap and instantly
                // close the keyboard before the key press could register.
                // TextFieldTapRegion is the API Flutter provides
                // specifically to fold a custom keyboard into the same
                // tap region as the field it's typing into.
                child: TextFieldTapRegion(
                  child: _MeasureAndReport(
                    onSize: controller.reportKeyboardHeight,
                    child: CustomKeyboard(
                      onCharacter: controller.onCharacter!,
                      onBackspace: controller.onBackspace!,
                      onDone: controller.onDone!,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Reports [child]'s rendered height to [onSize] after every layout pass,
/// without affecting [child]'s own size or layout in any way — a single
/// pass-through `RenderBox` measurement, not a second layout constraint.
/// Used to feed `CustomKeyboard`'s actual on-screen height back into
/// `VirtualKeyboardController.keyboardHeight` (see `KeyboardHost`'s doc
/// comment on `mediaQuery` above for why). Deliberately *not* keyed to
/// `child`'s own state — it measures whatever's currently built, so
/// toggling between the letter/numeric keyboard layouts (which happen to be
/// the same height, but wouldn't have to be) is picked up automatically.
class _MeasureAndReport extends StatefulWidget {
  const _MeasureAndReport({required this.onSize, required this.child});

  final ValueChanged<double> onSize;
  final Widget child;

  @override
  State<_MeasureAndReport> createState() => _MeasureAndReportState();
}

class _MeasureAndReportState extends State<_MeasureAndReport> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        widget.onSize(box.size.height);
      }
    });
    return widget.child;
  }
}
