import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Admin menu — "Change Dropoff Pin": resets the customer-facing drop-off
/// PIN, gated by the current one. Writes through to `config.json` (see
/// `ConfigService.setDropOffPin`) so the new PIN takes effect immediately
/// wherever it's checked. Mirrors `AdminResetPage`'s reset flow.
class AdminDropoffPinPage extends StatefulWidget {
  const AdminDropoffPinPage({super.key});

  @override
  State<AdminDropoffPinPage> createState() => _AdminDropoffPinPageState();
}

class _AdminDropoffPinPageState extends State<AdminDropoffPinPage>
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

  /// Which field the shared `NumericKeypad` is currently typing into — see
  /// `PinResetPage._activeController`'s doc comment (same pattern; this
  /// page has the same first-time-setup shape).
  TextEditingController? _activeController;

  List<TextEditingController> get _orderedFields => [
        if (!_isFirstTimeSetup) _currentController,
        _newController,
        _confirmController,
      ];

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
      message: 'THE DROPOFF PIN HAS BEEN SUCCESSFULLY RESET',
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
                          if (!_isFirstTimeSetup) ...[
                            const Text('Current dropoff pin:',
                                style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            KioskTextField(
                              controller: _currentController,
                              maxLength: 6,
                              obscureText: true,
                              useVirtualKeyboard: false,
                              active: _activeField == _currentController,
                              onTap: () => setState(
                                  () => _activeController = _currentController),
                              onChanged: (_) =>
                                  _filterDigits(_currentController),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text('New dropoff pin:',
                              style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _newController,
                            maxLength: 6,
                            obscureText: true,
                            useVirtualKeyboard: false,
                            active: _activeField == _newController,
                            onTap: () => setState(
                                () => _activeController = _newController),
                            onChanged: (_) => _filterDigits(_newController),
                          ),
                          const SizedBox(height: 20),
                          const Text('Confirm new dropoff pin:',
                              style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _confirmController,
                            maxLength: 6,
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
