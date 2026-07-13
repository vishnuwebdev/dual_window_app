import 'package:flutter/material.dart';

import '../../widgets/kiosk/kiosk.dart';
import 'deliver_input_page.dart';

/// Ported from `DeliverDisclaimerActivity` / `activity_deliver_disclaimer.xml`
/// — a liability disclaimer shown before the drop-off phone-number step.
/// See the note in `privacy_statement_page.dart` about how this screen is
/// wired into the flow here versus in the original Android app.
class DeliverDisclaimerPage extends StatefulWidget {
  const DeliverDisclaimerPage({super.key});

  @override
  State<DeliverDisclaimerPage> createState() => _DeliverDisclaimerPageState();
}

class _DeliverDisclaimerPageState extends State<DeliverDisclaimerPage>
    with InactivityTimerMixin {
  static const _text =
      'The hardware and software developer of this device, its agents, and '
      'or business partners will not be held liable for any special, '
      'indirect, consequential, punitive, or incidental damages (including '
      'without limitation, injuries, death, loss of business information or '
      'any other pecuniary loss) arising out of the use of this product, or '
      'for any other reason whatsoever.';

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.right,
        child: Column(
          children: [
            const KioskHeader(),
            const SizedBox(height: 12),
            Image.asset('assets/images/disclaimer.png', height: 90),
            const Expanded(
              child: Center(
                child: InstructionPanel(
                    text: _text, width: 760, height: 340, fontSize: 22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KioskButton(
                    label: 'Accept',
                    width: 260,
                    onPressed: () {
                      stopInactivityTimer();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const DeliverInputPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 40),
                  KioskButton(
                    label: 'Decline',
                    width: 260,
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
