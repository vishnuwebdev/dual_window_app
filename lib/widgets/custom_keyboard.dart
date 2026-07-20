import 'package:flutter/material.dart';

/// How the shift key currently affects letter keys.
///
/// [off] → lowercase. [single] → the *next* letter typed comes out
/// uppercase, then this reverts to [off] automatically (like a phone
/// keyboard). [locked] → every letter is uppercase until shift is tapped
/// again — entered via a double-tap on the shift key, i.e. "caps lock".
enum _ShiftMode { off, single, locked }

/// A minimal, fully generic on-screen QWERTY keyboard for touch displays
/// that have no physical keyboard attached (e.g. the Raspberry Pi kiosk
/// build).
///
/// This widget is intentionally standalone and reusable: it never touches
/// a `TextEditingController`, a `FocusNode`, or any app-specific state —
/// every key press is reported through one of the three callbacks below,
/// and the caller decides what to do with it. That makes it safe to drop
/// into *any* widget that wants a keyboard, not just text fields (e.g. a
/// search box, a PIN pad wrapper, a custom form control, …).
///
/// [KeyboardTextField] is the ready-made way to wire this up to a normal
/// `TextField`; use it when that's all you need. Reach for `CustomKeyboard`
/// directly when you want the keys but need custom behavior around them.
class CustomKeyboard extends StatefulWidget {
  const CustomKeyboard({
    super.key,
    required this.onCharacter,
    required this.onBackspace,
    required this.onDone,
  });

  /// A single character to insert wherever the caller's cursor is.
  /// Already cased correctly (upper/lowercase) — the caller doesn't need
  /// to look at shift state at all.
  final ValueChanged<String> onCharacter;

  /// Delete the character before the cursor (or the current selection).
  final VoidCallback onBackspace;

  /// "Done" was tapped — normally dismisses the keyboard and unfocuses.
  final VoidCallback onDone;

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  static const _letterRows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  static const _symbolRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', '+', ':', ';', '(', ')', '&', '@', '"'],
    ['.', ',', '?', '!', "'"],
  ];

  // A second tap on shift within this window counts as a double-tap and
  // locks caps on, same convention as iOS/Android on-screen keyboards.
  static const _doubleTapWindow = Duration(milliseconds: 350);

  _ShiftMode _shiftMode = _ShiftMode.off;
  DateTime? _lastShiftTap;
  bool _numeric = false;

  bool get _uppercase => _shiftMode != _ShiftMode.off;

  void _tapShift() {
    final now = DateTime.now();
    final isDoubleTap = _lastShiftTap != null &&
        now.difference(_lastShiftTap!) <= _doubleTapWindow;

    setState(() {
      _shiftMode = switch (_shiftMode) {
        _ShiftMode.locked => _ShiftMode.off,
        _ShiftMode.off ||
        _ShiftMode.single when isDoubleTap =>
          _ShiftMode.locked,
        _ => _ShiftMode.single,
      };
    });
    // Reset after locking so a third tap doesn't immediately re-trigger.
    _lastShiftTap = _shiftMode == _ShiftMode.locked ? null : now;
  }

  void _tapLetter(String lowercaseKey) {
    widget.onCharacter(_uppercase ? lowercaseKey.toUpperCase() : lowercaseKey);
    if (_shiftMode == _ShiftMode.single) {
      setState(() => _shiftMode = _ShiftMode.off); // one-shot consumed
    }
  }

  Widget _keyRow(List<String> keys, {required bool letters}) => Row(
        children: [
          for (final k in keys)
            Expanded(
              child: _Key(
                label: letters && _uppercase ? k.toUpperCase() : k,
                onTap: () => letters ? _tapLetter(k) : widget.onCharacter(k),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final rows = _numeric ? _symbolRows : _letterRows;
    final letters = !_numeric;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _keyRow(rows[0], letters: letters),
              _keyRow(rows[1], letters: letters),
              Row(
                children: [
                  if (letters)
                    Expanded(
                      flex: 3,
                      child: _ControlKey(
                        icon: _shiftMode == _ShiftMode.locked
                            ? Icons.keyboard_capslock
                            : Icons.arrow_upward,
                        selected: _shiftMode != _ShiftMode.off,
                        onTap: _tapShift,
                      ),
                    ),
                  Expanded(flex: 10, child: _keyRow(rows[2], letters: letters)),
                  Expanded(
                    flex: 3,
                    child: _ControlKey(
                      icon: Icons.backspace_outlined,
                      onTap: widget.onBackspace,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ControlKey(
                      label: _numeric ? 'ABC' : '123',
                      onTap: () => setState(() => _numeric = !_numeric),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: _ControlKey(
                      label: 'space',
                      onTap: () => widget.onCharacter(' '),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _ControlKey(
                      label: 'Done',
                      filled: true,
                      onTap: widget.onDone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single character key.
///
/// Plain `GestureDetector` + a manually-tracked pressed flag, instead of
/// `Material`/`InkWell`'s ripple: that ripple is a `Ticker`-driven
/// animation (an expanding, fading circle repainted every frame for
/// ~200-400ms per tap), and with up to 30 keys on screen a fast typist can
/// have several running and repainting at once — real GPU cost, on the
/// same weak Raspberry Pi GPU already carrying two full window engines,
/// for a purely cosmetic effect. An instant color swap on press/release
/// gives the same "the key registered" feedback with no animation at all.
/// `GestureDetector` also never requests focus, so there's no need for
/// the `canRequestFocus: false` workaround `InkWell` required to stop a
/// key tap from stealing focus from the field being typed into.
class _Key extends StatefulWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface;
    final bg = _pressed ? Color.alphaBlend(Colors.black12, base) : base;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        height: 46,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
                child:
                    Text(widget.label, style: const TextStyle(fontSize: 16))),
          ),
        ),
      ),
    );
  }
}

/// A wider control key: shift, backspace, space, 123/ABC toggle, or Done.
///
/// See `_Key`'s doc comment for why this is a plain `GestureDetector` +
/// manual pressed state instead of `Material`/`InkWell`'s animated ripple.
class _ControlKey extends StatefulWidget {
  const _ControlKey({
    this.label,
    this.icon,
    required this.onTap,
    this.selected = false,
    this.filled = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool selected;
  final bool filled;

  @override
  State<_ControlKey> createState() => _ControlKeyState();
}

class _ControlKeyState extends State<_ControlKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.filled
        ? scheme.primary
        : widget.selected
            ? scheme.primaryContainer
            : scheme.surface;
    final bg = _pressed ? Color.alphaBlend(Colors.black12, base) : base;
    final fg = widget.filled ? scheme.onPrimary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        height: 46,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(widget.icon, size: 20, color: fg)
                  : Text(widget.label ?? '',
                      style: TextStyle(fontSize: 14, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
