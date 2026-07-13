import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Admin menu — "Change Sms template": edits the SMS body sent on
/// drop-off/collection notifications. Writes through to `config.json`
/// (see `ConfigService.setSmsTemplate`).
class AdminSmsTemplatePage extends StatefulWidget {
  const AdminSmsTemplatePage({super.key});

  @override
  State<AdminSmsTemplatePage> createState() => _AdminSmsTemplatePageState();
}

class _AdminSmsTemplatePageState extends State<AdminSmsTemplatePage>
    with InactivityTimerMixin {
  final _config = ConfigService();
  late final _templateController =
      TextEditingController(text: _config.smsTemplate);
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
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final template = _templateController.text.trim();
    final error = await _config.setSmsTemplate(template);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    if (!mounted) return;
    stopInactivityTimer();
    InfoDialog.show(
      context,
      message: 'THE SMS TEMPLATE HAS BEEN SUCCESSFULLY UPDATED',
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
                      Text(
                          'SMS template (use {pin} for the PIN, 40-160 characters):',
                          style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      KioskTextField(
                          controller: _templateController,
                          maxLength: 160,
                          maxLines: 6,
                          onChanged: (_) => setState(() => _errorText = null)),
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
