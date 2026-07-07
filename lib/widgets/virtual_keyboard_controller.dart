import 'package:flutter/foundation.dart';

/// Coordinates a single on-screen keyboard per window engine.
///
/// `KeyboardTextField` calls [attach] when it gains focus and [detach] when
/// it loses it; `KeyboardHost` (mounted once, at the root of each window's
/// `MaterialApp`) listens to this and renders `CustomKeyboard` pinned to
/// the bottom of the window whenever [visible] is true.
///
/// Routing key presses through a shared controller — instead of each
/// `KeyboardTextField` rendering its own inline keyboard — is what lets the
/// keyboard live in a `Stack` overlay at the window root: an overlay needs
/// exactly one place to mount, and only one field can be focused at a time
/// anyway, so a single controller is a natural fit.
///
/// Same desktop gotcha as `MessagingService`: this is a plain singleton, so
/// it's scoped to *one* window's engine. The Admin and Customer windows
/// each get their own independent copy — which is exactly what we want,
/// since each window has its own keyboard.
class VirtualKeyboardController extends ChangeNotifier {
  VirtualKeyboardController._();

  static final VirtualKeyboardController instance = VirtualKeyboardController._();

  bool _visible = false;
  bool get visible => _visible;

  Object? _owner;

  ValueChanged<String>? onCharacter;
  VoidCallback? onBackspace;
  VoidCallback? onDone;

  /// Called by a `KeyboardTextField` when it gains focus. [owner] should be
  /// a stable, unique-per-field token (its `State` object works well) —
  /// it's what lets [detach] tell "my field blurred" apart from "a *different*
  /// field already took over focus", which matters when focus moves
  /// directly from one field to another.
  void attach({
    required Object owner,
    required ValueChanged<String> onCharacter,
    required VoidCallback onBackspace,
    required VoidCallback onDone,
  }) {
    _owner = owner;
    this.onCharacter = onCharacter;
    this.onBackspace = onBackspace;
    this.onDone = onDone;
    _visible = true;
    notifyListeners();
  }

  /// Called by a `KeyboardTextField` when it loses focus. No-ops if [owner]
  /// isn't the field that's currently attached, so an old field's blur
  /// event can't hide the keyboard out from under a field that has since
  /// taken over.
  void detach(Object owner) {
    if (_owner != owner) return;
    _visible = false;
    notifyListeners();
  }
}
