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
    final phone = _phoneController.text.trim();
    final repeat = _repeatController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorText = 'Phone number cannot be empty');
      return;
    }
    if (repeat.isEmpty) {
      setState(() => _errorText = 'Please repeat your cell phone number');
      return;
    }
    if (phone != repeat) {
      setState(
          () => _errorText = 'The number you have entered does not match.');
      return;
    }
    if (!MockKioskRepository.validatePhoneNumber(phone, _repo.isGlobal)) {
      setState(() =>
          _errorText = 'Please enter a valid cell phone number and try again.');
      return;
    }

    final normalized = MockKioskRepository.normalizeToSouthAfrica(phone);
    stopInactivityTimer();
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DeliverLockerSelectPage(phone: normalized)),
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
