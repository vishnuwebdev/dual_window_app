import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The collection journey's actual "you're done" confirmation — the
/// direct equivalent of `DeliverDropoffCompletePage` on the drop-off
/// side, and new as of 2026-09-03. Before this existed, the collection
/// journey had no card like this at all: the instruction screen
/// (`CollectionInstructionPage`, née `CollectionCompletePage` — see its
/// doc comment for the rename) went straight back to Home once its timer
/// or Back button fired, with nothing ever telling the customer the
/// transaction had actually finished. See `collection_instruction_page.dart`
/// for how this screen is now reachable.
class CollectionCompletePage extends StatefulWidget {
  const CollectionCompletePage({super.key});

  @override
  State<CollectionCompletePage> createState() =>
      _CollectionCompletePageState();
}

class _CollectionCompletePageState extends State<CollectionCompletePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 9), () {
      if (!mounted) return;
      // Pop back to the existing root `HomePage` route (each window's
      // `MaterialApp.home`) instead of pushing a fresh one — a fresh
      // `HomePage()` would use its default `dropOffEnabled`/
      // `collectEnabled` rather than this window's actual role, showing
      // the wrong buttons. Same reasoning as
      // `DeliverDropoffCompletePage`'s matching timer.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            border: Border.all(color: AppColors.tealBorder, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Collection completed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Metropolis',
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
