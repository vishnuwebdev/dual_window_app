import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Ported from `AdminResetActivity` / `activity_admin_reset.xml`: reset the
/// admin PIN, gated by the current one. Writes through to `config.json`
/// (see `ConfigService.setAdminPin`) so the new PIN takes effect
/// immediately on the "tap the VG badge 5 times" gate.
class AdminResetPage extends StatefulWidget {
  const AdminResetPage({super.key});

  @override
  State<AdminResetPage> createState() => _AdminResetPageState();
}

class _AdminResetPageState extends State<AdminResetPage>
    with InactivityTimerMixin {
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
  void onInactivityTimeout() => Navigator.of(context).pop();

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

  Future<void> _handleContinue() async {
    final current = _currentController.text.trim();
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current != _config.adminPin) {
      setState(() => _errorText = 'Current PIN you have entered does not match.');
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorText = 'The PINs you have entered do not match.');
      return;
    }

    final error = await _config.setAdminPin(newPin);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    if (!mounted) return;
    stopInactivityTimer();
    InfoDialog.show(
      context,
      message: 'YOUR ADMIN PIN HAS BEEN SUCCESSFULLY RESET',
      // Previously this sat open until someone noticed and tapped the
      // "X" — on a kiosk with no one watching that could mean it never
      // closes. Auto-dismiss after a few seconds so the flow moves on by
      // itself either way; `onClose` (popping back to the admin menu)
      // still runs the same whether it was tapped or timed out.
      autoCloseDuration: const Duration(seconds: 4),
      onClose: () => Navigator.of(context).pop(),
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
                      Text('Current admin PIN:', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _currentController,
                          maxLength: 10,
                          obscureText: true,
                          onChanged: (_) => _filterDigits(_currentController)),
                      const SizedBox(height: 20),
                      Text('New admin PIN:', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _newController,
                          maxLength: 10,
                          obscureText: true,
                          onChanged: (_) => _filterDigits(_newController)),
                      const SizedBox(height: 20),
                      Text('Confirm new admin PIN:', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _confirmController,
                          maxLength: 10,
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
                    width: 220,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 40),
                  KioskButton(
                      label: 'Continue',
                      width: 220,
                      onPressed: _handleContinue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
