import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../keyboard_text_field.dart';

/// A labelled input field matching the Android app's
/// `shadow_background` + `edittext_rounded_border` combo: a white pill-
/// shaped field sitting on a darker navy "shadow" frame offset to the
/// bottom-right. Uses the shared [KeyboardTextField] so the on-screen
/// keyboard (see `KeyboardHost`) pops up on kiosk hardware with no physical
/// keyboard attached.
///
/// `maxLength` is enforced via a controller listener rather than a
/// `TextField`-level `inputFormatter`, matching how the Android activities
/// validate on `doOnTextChanged` instead of hard input filters — the
/// on-screen `CustomKeyboard` inserts characters directly into the
/// controller, bypassing normal `TextField` formatters anyway.
class KioskTextField extends StatefulWidget {
  const KioskTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Set above 1 for a textarea-style field (e.g. the SMS template editor)
  /// — grows the field's height to fit, top-aligns the text instead of
  /// centering it, and switches to a less pill-shaped corner radius so a
  /// tall box doesn't look like a stretched capsule.
  final int maxLines;

  @override
  State<KioskTextField> createState() => _KioskTextFieldState();
}

class _KioskTextFieldState extends State<KioskTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final maxLength = widget.maxLength;
    if (maxLength != null && widget.controller.text.length > maxLength) {
      final trimmed = widget.controller.text.substring(0, maxLength);
      widget.controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      return; // avoid double-firing onChanged for the same edit
    }
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isTextarea = widget.maxLines > 1;
    final outerRadius = isTextarea ? 16.0 : 28.0;
    final innerRadius = isTextarea ? 12.0 : 24.0;
    final fieldHeight = isTextarea ? 22.0 * widget.maxLines + 24 : 46.0;

    return Container(
      padding: EdgeInsets.only(top: isTextarea ? 4 : 6, left: 8, right: 4, bottom: isTextarea ? 4 : 0),
      decoration: BoxDecoration(
        color: AppColors.fieldShadow,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: SizedBox(
        height: fieldHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(innerRadius)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTextarea ? 12 : 0),
            child: KeyboardTextField(
              controller: widget.controller,
              onSubmitted: widget.onSubmitted,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              minLines: isTextarea ? widget.maxLines : null,
              style: AppTextStyles.fieldInput,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: widget.hintText,
                hintStyle: AppTextStyles.fieldInput.copyWith(
                  color: AppColors.fieldHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
