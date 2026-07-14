import 'package:flutter/material.dart';

import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'collection_complete_page.dart';

/// Ported from `CollectionInputActivity` / `activity_collection_input.xml`:
/// phone number + one-time PIN entry to retrieve a parcel.
class CollectionInputPage extends StatefulWidget {
  const CollectionInputPage({super.key});

  @override
  State<CollectionInputPage> createState() => _CollectionInputPageState();
}

class _CollectionInputPageState extends State<CollectionInputPage>
    with InactivityTimerMixin {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _repo = MockKioskRepository.instance;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
    // Pre-fill "+27" — the on-screen keyboard (see `custom_keyboard.dart`)
    // has no '+' key at all, so without this, a customer has no way to
    // type an international-format number themselves. Only relevant in
    // SA-only mode; global mode leaves the field blank as before. Cursor
    // placed after the prefix so typing just continues the number.
    if (!_repo.isGlobal) {
      _phoneController.value = const TextEditingValue(
        text: '+27',
        selection: TextSelection.collapsed(offset: 3),
      );
    }
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final rawPhone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (rawPhone.isEmpty) {
      setState(() => _errorText = 'Phone number cannot be empty');
      return;
    }

    // Normalize before validating (not after) — this is what collapses a
    // duplicated "+27" (e.g. from typing "0821234567" or "27821234567"
    // after the pre-filled "+27" prefix above) into a single valid
    // number, rather than rejecting it as malformed.
    final phone = MockKioskRepository.normalizeToSouthAfrica(rawPhone);

    if (!MockKioskRepository.validatePhoneNumber(phone, _repo.isGlobal)) {
      setState(() =>
          _errorText = 'Please enter a valid cell phone number and try again.');
      return;
    }

    if (pin.isEmpty) {
      setState(() => _errorText = 'OTP cannot be empty');
      return;
    }

    final matches =
        _repo.itemsForPhone(phone).where((item) => item.pin == pin).toList();

    if (matches.isEmpty) {
      InfoDialog.show(
        context,
        message:
            'The cell phone number or one-time pin that you entered is incorrect. Please try again',
      );
      return;
    }

    stopInactivityTimer();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CollectionCompletePage(phone: phone, oneTimePin: pin),
      ),
    );
  }

  void _handleCancel() {
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
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter cell phone number:',
                          style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      if (!_repo.isGlobal)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '(Use +27XXXXXXXXX for South Africa)',
                            style: AppTextStyles.hint,
                          ),
                        ),
                      KioskTextField(
                        controller: _phoneController,
                        hintText: '0821234567',
                        maxLength: 15,
                        onChanged: (_) => setState(() => _errorText = null),
                      ),
                      const SizedBox(height: 24),
                      Text('Enter one-time pin:', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      KioskTextField(
                        controller: _pinController,
                        hintText: '0000',
                        maxLength: 4,
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
                    onPressed: _handleCancel,
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
