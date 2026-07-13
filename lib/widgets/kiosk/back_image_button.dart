import 'package:flutter/material.dart';

/// The `back.png` image button used top-left on several screens (Help,
/// Collection Complete, Deliver Locker Select) instead of an app-bar back
/// arrow, matching the Android app's borderless `ImageView` +
/// `setOnClickListener` pattern.
class BackImageButton extends StatelessWidget {
  const BackImageButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      top: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/images/back.png', width: 56, height: 48),
          ),
        ),
      ),
    );
  }
}
