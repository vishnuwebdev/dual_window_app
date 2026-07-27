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
  // Longer than the 30s kiosk default — see kAdminInactivityTimeout's doc
  // comment. Timing out here pops back to AdminMenuPage (the admin
  // landing screen), same as every other admin feature screen.
  @override
  Duration get inactivityTimeout => kAdminInactivityTimeout;

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _config = ConfigService();
  String? _errorText;

  /// Which field the shared `NumericKeypad` is currently typing into —
  /// `null` means "the first field" (see [_activeField]). Same pattern as
  /// `PinResetPage`'s `_activeController`.
  TextEditingController? _activeController;

  /// All three PIN fields, in on-screen (top-to-bottom) order — this page
  /// always shows all three (unlike `PinResetPage`/`AdminDropoffPinPage`,
  /// there's no first-time-setup case where the current PIN is empty).
  List<TextEditingController> get _orderedFields =>
      [_currentController, _newController, _confirmController];

  TextEditingController get _activeField =>
      _activeController ?? _orderedFields.first;

  void _appendDigit(String digit) {
    setState(() {
      _errorText = null;
      _activeField.text += digit;
    });
  }

  void _backspace() {
    final field = _activeField;
    if (field.text.isEmpty) return;
    setState(() {
      _errorText = null;
      field.text = field.text.substring(0, field.text.length - 1);
    });
  }

  /// "Enter" advances to the next PIN field instead of submitting
  /// immediately — see `PinResetPage._advanceOrSubmit`'s doc comment.
  void _advanceOrSubmit() {
    final fields = _orderedFields;
    final index = fields.indexOf(_activeField);
    if (index < fields.length - 1) {
      setState(() => _activeController = fields[index + 1]);
    } else {
      _handleContinue();
    }
  }

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
      // closes. Auto-dismiss so the flow moves on by itself either way;
      // `onClose` (popping back to the admin menu) still runs the same
      // whether it was tapped or timed out. Uses the same 15s as every
      // other admin dialog (was 4s here specifically, before that became
      // the standard — see kDialogAutoCloseDuration's doc comment).
      autoCloseDuration: kDialogAutoCloseDuration,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 380,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current admin PIN:',
                              style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _currentController,
                            maxLength: 10,
                            obscureText: true,
                            useVirtualKeyboard: false,
                            active: _activeField == _currentController,
                            onTap: () => setState(
                                () => _activeController = _currentController),
                            onChanged: (_) =>
                                _filterDigits(_currentController),
                          ),
                          const SizedBox(height: 20),
                          Text('New admin PIN:', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _newController,
                            maxLength: 10,
                            obscureText: true,
                            useVirtualKeyboard: false,
                            active: _activeField == _newController,
                            onTap: () =>
                                setState(() => _activeController = _newController),
                            onChanged: (_) => _filterDigits(_newController),
                          ),
                          const SizedBox(height: 20),
                          Text('Confirm new admin PIN:',
                              style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _confirmController,
                            maxLength: 10,
                            obscureText: true,
                            useVirtualKeyboard: false,
                            active: _activeField == _confirmController,
                            onTap: () => setState(
                                () => _activeController = _confirmController),
                            onChanged: (_) => _filterDigits(_confirmController),
                          ),
                          if (_errorText != null)
                            ErrorBanner(message: _errorText!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    NumericKeypad(
                      onDigit: _appendDigit,
                      onBackspace: _backspace,
                      onEnter: _advanceOrSubmit,
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
