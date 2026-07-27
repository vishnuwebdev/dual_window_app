import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'deliver_input_page.dart';
import 'pin_reset_page.dart';

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
      // Straight to phone-number entry — see the matching comment in
      // `home_page.dart._handleDeliver` for why there's no Privacy
      // Statement/Disclaimer screen here anymore.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeliverInputPage()),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 420,
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
                            useVirtualKeyboard: false,
                            onChanged: (_) => setState(() => _errorText = null),
                          ),
                          if (_errorText != null)
                            ErrorBanner(message: _errorText!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 64),
                    NumericKeypad(
                      onDigit: (digit) {
                        setState(() {
                          _errorText = null;
                          _pinController.text += digit;
                        });
                      },
                      onBackspace: () {
                        final text = _pinController.text;
                        if (text.isEmpty) return;
                        setState(() {
                          _errorText = null;
                          _pinController.text =
                              text.substring(0, text.length - 1);
                        });
                      },
                      onEnter: _handleManagement,
                    ),
                  ],
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
