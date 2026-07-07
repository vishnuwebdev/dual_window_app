import 'package:flutter/material.dart';

import 'virtual_keyboard_controller.dart';

/// A `TextField` that opens the shared on-screen keyboard (see
/// `KeyboardHost`, `VirtualKeyboardController`) whenever it has focus, and
/// releases it again on blur or when "Done" is tapped.
///
/// Drop-in replacement for `TextField` on touch kiosks with no physical
/// keyboard attached (see `AdminHomePage` for the intended usage). Requires
/// a `KeyboardHost` to be mounted somewhere above it in the tree — every
/// window's `MaterialApp` in this app provides one via `builder:`.
class KeyboardTextField extends StatefulWidget {
  const KeyboardTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.onSubmitted,
    this.style,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;

  @override
  State<KeyboardTextField> createState() => _KeyboardTextFieldState();
}

class _KeyboardTextFieldState extends State<KeyboardTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    // If this field is disposed while it still owns the keyboard (e.g. its
    // page was popped without the field ever losing focus first), release
    // it — otherwise the keyboard is left pointing at callbacks for a
    // controller that may itself be gone.
    VirtualKeyboardController.instance.detach(this);
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      VirtualKeyboardController.instance.attach(
        owner: this,
        onCharacter: _insert,
        onBackspace: _backspace,
        onDone: _done,
      );
    } else {
      VirtualKeyboardController.instance.detach(this);
    }
  }

  TextSelection _currentSelection() {
    final selection = widget.controller.selection;
    return selection.isValid
        ? selection
        : TextSelection.collapsed(offset: widget.controller.text.length);
  }

  void _insert(String text) {
    final value = widget.controller.value;
    final selection = _currentSelection();
    final newText = value.text.replaceRange(selection.start, selection.end, text);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _backspace() {
    final value = widget.controller.value;
    final selection = _currentSelection();
    if (selection.start == selection.end) {
      if (selection.start == 0) return;
      final newText = value.text.replaceRange(selection.start - 1, selection.start, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    } else {
      final newText = value.text.replaceRange(selection.start, selection.end, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  void _done() {
    widget.onSubmitted?.call(widget.controller.text);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      style: widget.style,
      // Flutter desktop never auto-shows a software keyboard on its own,
      // so there's nothing to suppress here — CustomKeyboard (via
      // KeyboardHost) is purely additive, and hardware-keyboard typing
      // keeps working normally too.
      onSubmitted: widget.onSubmitted,
    );
  }
}
