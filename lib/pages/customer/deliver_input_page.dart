import 'package:flutter/material.dart';

import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'deliver_locker_select_page.dart';

/// Ported from `DeliverInputActivity` / `activity_deliver_input.xml`:
/// enter + confirm the sender's phone number before choosing a locker.
class DeliverInputPage extends StatefulWidget {
  const DeliverInputPage({super.key});

  @override
  State<DeliverInputPage> createState() => _DeliverInputPageState();
}

class _DeliverInputPageState extends State<DeliverInputPage>
    with InactivityTimerMixin {
  final _phoneController = TextEditingController();
  final _repeatController = TextEditingController();
  final _repo = MockKioskRepository.instance;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
    // Pre-fill "+27" on both fields — see the matching comment in
    // `collection_input_page.dart` for why (no '+' key on the on-screen
    // keyboard at all).
    if (!_repo.isGlobal) {
      const prefilled = TextEditingValue(
        text: '+27',
        selection: TextSelection.collapsed(offset: 3),
      );
      _phoneController.value = prefilled;
      _repeatController.value = prefilled;
    }
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final rawPhone = _phoneController.text.trim();
    final rawRepeat = _repeatController.text.trim();

    if (rawPhone.isEmpty) {
      setState(() => _errorText = 'Phone number cannot be empty');
      return;
    }
    if (rawRepeat.isEmpty) {
      setState(() => _errorText = 'Please repeat your cell phone number');
      return;
    }

    // Normalize both before comparing — not the raw text. Otherwise two
    // entries of the *same* number that happen to be typed slightly
    // differently (e.g. "0821234567" in one field, "821234567" — without
    // the leading 0 — in the other, both valid after the pre-filled
    // "+27") would be flagged as a mismatch even though they're identical
    // once normalized.
    final phone = MockKioskRepository.normalizeToSouthAfrica(rawPhone);
    final repeat = MockKioskRepository.normalizeToSouthAfrica(rawRepeat);

    if (phone != repeat) {
      setState(
          () => _errorText = 'The number you have entered does not match.');
      return;
    }
    if (!MockKioskRepository.validatePhoneNumber(phone, _repo.isGlobal)) {
      setState(() => _errorText =
          'Please enter a valid cell phone number in the format +27XXXXXXXXX.');
      return;
    }

    stopInactivityTimer();
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DeliverLockerSelectPage(phone: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.left,
        child: Column(
          children: [
            const KioskHeader(),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Enter cell phone number:',
                          style: AppTextStyles.label),
                      if (!_repo.isGlobal)
                        const Padding(
                          padding: EdgeInsets.only(top: 2, bottom: 8),
                          child: Text('(Use +27XXXXXXXXX for South Africa)',
                              style: AppTextStyles.hint),
                        ),
                      KioskTextField(
                        controller: _phoneController,
                        maxLength: 15,
                        onChanged: (_) => setState(() => _errorText = null),
                      ),
                      const SizedBox(height: 20),
                      const Text('Repeat cell phone number:',
                          style: AppTextStyles.label),
                      if (!_repo.isGlobal)
                        const Padding(
                          padding: EdgeInsets.only(top: 2, bottom: 8),
                          child: Text('(Use +27XXXXXXXXX for South Africa)',
                              style: AppTextStyles.hint),
                        ),
                      KioskTextField(
                        controller: _repeatController,
                        maxLength: 15,
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
                    width: 220,
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
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
