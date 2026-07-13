import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/kiosk/inactivity_timer.dart';
import 'deliver_disclaimer_page.dart';

/// Ported from `PrivacyStatementActivity` / `activity_privacy_statement.xml`
/// — the POPIA data-collection consent screen shown before every drop-off.
///
/// Deviation from the Android source: there, "Accept & Continue" jumps
/// straight to `DeliverInputActivity`, skipping `DeliverDisclaimerActivity`
/// entirely (that screen has no caller anywhere in the app — see the
/// screen inventory). Here "Accept" instead continues into the Disclaimer
/// screen, so that page has a real, reachable place in the flow instead of
/// being dead code. Both screens still support Decline -> Home.
class PrivacyStatementPage extends StatefulWidget {
  const PrivacyStatementPage({super.key});

  @override
  State<PrivacyStatementPage> createState() => _PrivacyStatementPageState();
}

class _PrivacyStatementPageState extends State<PrivacyStatementPage>
    with InactivityTimerMixin {
  static const _content =
      'VaultGroup (Pty) Ltd collects your cellphone number (and name, if '
      'provided) directly from you to:\n\n'
      '• Send you a one-time PIN (OTP) for locker access,\n'
      '• Manage and record locker use,\n'
      '• Contact you if an item is not collected, and\n'
      '• Investigate and resolve service or security incidents.\n\n'
      'Providing your number is required to use the locker.\n\n'
      'Your information is stored securely in the EU and may be shared only '
      'when necessary, with the organisation that provided this locker '
      '(e.g. retailer, estate, or event sponsor) to resolve locker issues, '
      'or with legal authorities if required by law.\n\n'
      'You have the right to access, correct, or request deletion of your '
      'information, and to complain to the Information Regulator.\n\n'
      'For more info view our Privacy Policy at: '
      'vaultgroup.co.za/privacy-policy/\nor Email: info@vaultgroup.co.za.';

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _decline() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _accept() {
    stopInactivityTimer();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeliverDisclaimerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset('assets/images/vg.png', width: 72, height: 72),
                const SizedBox(height: 16),
                const Text(
                  'Privacy Statement (POPIA)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Metropolis',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _content,
                      style: const TextStyle(
                        fontFamily: 'Metropolis',
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _decline,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            side: BorderSide.none,
                          ),
                          child: const Text(
                            'Decline / Exit',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _accept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                          ),
                          child: const Text(
                            'Accept & Continue',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
