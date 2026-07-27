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

  /// Which field the shared `NumericKeypad` is currently typing into.
  /// `null` means "whichever field is first" (see [_activeField]) — kept
  /// separate from a plain default so [_activeField] can react to
  /// [_isFirstTimeSetup] potentially changing which field is actually
  /// first, rather than baking that in once at `initState`.
  TextEditingController? _activeController;

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

  /// The visible PIN fields in on-screen (top-to-bottom) order — omits
  /// [_currentController] during [_isFirstTimeSetup], matching what's
  /// actually built below. Drives both the shared `NumericKeypad`'s target
  /// field and its "Enter" key's advance-to-next-field behavior.
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

  /// "Enter" on the shared keypad advances to the next PIN field rather
  /// than submitting immediately — with three fields on screen at once,
  /// treating every "Enter" as "submit the whole form" would make it too
  /// easy to submit after only filling in the first field.
  void _advanceOrSubmit() {
    final fields = _orderedFields;
    final index = fields.indexOf(_activeField);
    if (index < fields.length - 1) {
      setState(() => _activeController = fields[index + 1]);
    } else {
      _handleContinue();
    }
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
                            Text('Current pin:', style: AppTextStyles.label),
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
                          Text('New pin:', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          KioskTextField(
                            controller: _newController,
                            maxLength: 6,
                            obscureText: true,
                            useVirtualKeyboard: false,
                            active: _activeField == _newController,
                            onTap: () =>
                                setState(() => _activeController = _newController),
                            onChanged: (_) => _filterDigits(_newController),
                          ),
                          const SizedBox(height: 20),
                          Text('Confirm new pin:', style: AppTextStyles.label),
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
