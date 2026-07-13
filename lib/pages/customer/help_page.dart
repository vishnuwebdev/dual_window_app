import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilities/logging.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Ported from `HelpActivity` / `activity_help.xml`: "Forgot pin?" — enter
/// a phone number to (mock-)resend the collection PIN via SMS.
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with InactivityTimerMixin {
  final _phoneController = TextEditingController();
  final _repo = MockKioskRepository.instance;
  Timer? _autoReturnTimer;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() => _returnHome();

  @override
  void dispose() {
    _phoneController.dispose();
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  void _returnHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleConfirm() {
    var phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = MockKioskRepository.normalizeToSouthAfrica(phone);
    }

    if (!MockKioskRepository.validatePhoneNumber(phone, _repo.isGlobal)) {
      InfoDialog.show(context,
          message: 'Please enter a valid cell phone number.');
      _autoReturnTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
      });
      return;
    }

    final matches = _repo.itemsForPhone(phone);
    if (matches.isNotEmpty) {
      // Mirrors `DbService.sendSms`: substitute the real PIN into
      // `config.json`'s `sms_template` and send it.
      final message =
          ConfigService().smsTemplate.replaceAll('{pin}', matches.first.pin);
      logger.i('Sending SMS to $phone: "$message"');
      // In 'grpc' mode, actually submit it via the unit's send_sms RPC
      // (VaultGroup's backend transmits it from there) — see
      // `LockerGrpcService.sendSms`. In 'mock' mode the log line above is
      // the only "delivery," same as before.
      if (ConfigService().isGrpcBackend) {
        unawaited(LockerGrpcService.instance.sendSms(phone, message));
      }
    }

    InfoDialog.show(
      context,
      message: matches.isNotEmpty
          ? 'You will receive your pin via SMS shortly'
          : 'There are no lockers linked to that cell phone number',
    );

    _autoReturnTimer = Timer(const Duration(seconds: 10), _returnHome);
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.left,
        child: Stack(
          children: [
            BackImageButton(onPressed: _returnHome),
            Column(
              children: [
                const KioskHeader(),
                const SizedBox(height: 12),
                Image.asset('assets/images/click_n_collect.png', height: 100),
                const SizedBox(height: 12),
                const Text('Forgot pin?', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                const Text(
                  'Enter cell phone number to receive pin via SMS',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label,
                ),
                if (!_repo.isGlobal)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('(Use +27XXXXXXXXX for South Africa)',
                        style: AppTextStyles.hint),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 340,
                      child: KioskTextField(
                        controller: _phoneController,
                        hintText: '0821234567',
                        maxLength: 15,
                      ),
                    ),
                    const SizedBox(width: 16),
                    KioskButton(
                      label: 'Confirm',
                      onPressed: _handleConfirm,
                      width: 150,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'For any other queries,\nplease contact our support team\non 0870 57 55 55',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
