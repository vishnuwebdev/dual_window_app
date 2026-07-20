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

        return Stack(
          children: [
            Positioned.fill(child: child),
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
                  child: CustomKeyboard(
                    onCharacter: controller.onCharacter!,
                    onBackspace: controller.onBackspace!,
                    onDone: controller.onDone!,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
