import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'pin_reset_page.dart';
import 'privacy_statement_page.dart';

/// Ported from `VerifyPinActivity` / `activity_verify_pin.xml`: a PIN gate
/// shown before starting a drop-off, only when `dropoffPinEnabled` is on
/// (see `MockKioskRepository.dropoffPinEnabled`), checked against
/// `config.json`'s drop-off PIN (see `ConfigService.dropOffPin`).
class VerifyPinPage extends StatefulWidget {
  const VerifyPinPage({super.key});

  @override
  State<VerifyPinPage> createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage>
    with InactivityTimerMixin {
  final _pinController = TextEditingController();
  final _config = ConfigService();
  String? _errorText;

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
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleManagement() {
    if (_pinController.text.trim() == _config.dropOffPin) {
      stopInactivityTimer();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PrivacyStatementPage()),
      );
    } else {
      setState(() => _errorText = 'The pin you have entered is incorrect.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.right,
        child: Column(
          children: [
            const KioskHeader(),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter pin:', style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      KioskTextField(
                        controller: _pinController,
                        maxLength: 6,
                        obscureText: true,
                        onChanged: (_) => setState(() => _errorText = null),
                      ),
                      if (_errorText != null) ErrorBanner(message: _errorText!),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KioskButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    width: 210,
                  ),
                  const SizedBox(width: 24),
                  KioskButton(
                    label: 'Continue',
                    onPressed: _handleManagement,
                    width: 210,
                  ),
                  const SizedBox(width: 24),
                  KioskButton(
                    label: 'Change\nPin',
                    onPressed: () {
                      stopInactivityTimer();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PinResetPage()),
                      );
                    },
                    width: 210,
                    textStyle: AppTextStyles.buttonLabel.copyWith(fontSize: 18),
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
