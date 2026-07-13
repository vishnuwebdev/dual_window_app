import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Ported from `PinResetActivity` / `activity_pin_reset.xml`: change the
/// customer-facing drop-off PIN, gated by the current PIN. Writes through
/// to `config.json` (see `ConfigService.setDropOffPin`).
class PinResetPage extends StatefulWidget {
  const PinResetPage({super.key});

  @override
  State<PinResetPage> createState() => _PinResetPageState();
}

class _PinResetPageState extends State<PinResetPage> with InactivityTimerMixin {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _config = ConfigService();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() => _goHome();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _filterDigits(TextEditingController controller) {
    final filtered = ConfigService.digitsOnly(controller.text);
    if (filtered != controller.text) {
      controller.value = TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
    }
    setState(() => _errorText = null);
  }

  void _goHome() {
    if (!mounted) return;
    // Pop back to the existing root `HomePage` route (each window's
    // `MaterialApp.home`) instead of pushing a fresh one — a fresh
    // `HomePage()` would use its default `dropOffEnabled`/`collectEnabled`
    // rather than this window's actual role, showing the wrong buttons.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// No drop-off PIN has been set yet — `config.json`'s `drop_off_pin` is
  /// empty, so there's nothing to show or match against on this screen.
  bool get _isFirstTimeSetup => _config.dropOffPin.isEmpty;

  Future<void> _handleContinue() async {
    final current = _currentController.text.trim();
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!_isFirstTimeSetup && current != _config.dropOffPin) {
      setState(
          () => _errorText = 'Current pin you have entered does not match.');
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorText = 'The pins you have entered do not match.');
      return;
    }

    final error = await _config.setDropOffPin(newPin);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    if (!mounted) return;
    stopInactivityTimer();
    InfoDialog.show(
      context,
      message: 'YOUR PIN HAS BEEN SUCCESSFULLY RESET',
      onClose: _goHome,
    );
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
                      if (!_isFirstTimeSetup) ...[
                        Text('Current pin:', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        KioskTextField(
                            controller: _currentController,
                            maxLength: 6,
                            obscureText: true,
                            onChanged: (_) =>
                                _filterDigits(_currentController)),
                        const SizedBox(height: 20),
                      ],
                      Text('New pin:', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _newController,
                          maxLength: 6,
                          obscureText: true,
                          onChanged: (_) => _filterDigits(_newController)),
                      const SizedBox(height: 20),
                      Text('Confirm new pin:', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _confirmController,
                          maxLength: 6,
                          obscureText: true,
                          onChanged: (_) => _filterDigits(_confirmController)),
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
                    onPressed: _goHome,
                    width: 220,
                  ),
                  const SizedBox(width: 40),
                  KioskButton(
                    label: 'Continue',
                    onPressed: _handleContinue,
                    width: 220,
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
