import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'admin_menu_page.dart';

/// The "Enter Admin Password" numeric-keypad gate opened by tapping the VG
/// badge 5 times on the Customer window's Home page. Checks the entered
/// PIN against `admin_pin` in the local `config.json` (see
/// `ConfigService.adminPin`), then opens [AdminMenuPage] on success.
class AdminPinGatePage extends StatefulWidget {
  const AdminPinGatePage({super.key});

  @override
  State<AdminPinGatePage> createState() => _AdminPinGatePageState();
}

class _AdminPinGatePageState extends State<AdminPinGatePage>
    with InactivityTimerMixin {
  final _pinController = TextEditingController();
  final _config = ConfigService();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
    _config.initialize();
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_pinController.text.trim() == _config.adminPin) {
      stopInactivityTimer();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminMenuPage()),
      );
    } else {
      setState(
          () => _errorText = 'The password you have entered is incorrect.');
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
                          const Text('Enter Admin Password',
                              style: AppTextStyles.label),
                          const SizedBox(height: 16),
                          KioskTextField(
                            controller: _pinController,
                            maxLength: 10,
                            obscureText: true,
                            onChanged: (_) => setState(() => _errorText = null),
                          ),
                          if (_errorText != null)
                            ErrorBanner(message: _errorText!),
                          const SizedBox(height: 40),
                          const Text(
                            'For any other queries,\nPlease contact our support\nteam on 0870 57 57 55',
                            style: AppTextStyles.hint,
                          ),
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
                      onEnter: _handleContinue,
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
                    onPressed: _handleContinue,
                    width: 210,
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
