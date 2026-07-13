import 'package:flutter/material.dart';

import '../../core/registration/unit_registration_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/admin_section_card.dart';
import '../../widgets/keyboard_text_field.dart';

/// Admin window — Unit Registration page.
///
/// Ported from `AdminOverrideActivity.openUnitRegistration()`'s dialog:
/// enter a registration code (created on the VaultGroup platform first,
/// same as on the Android app) to register this unit with VaultGroup's
/// cloud and establish the identity audit events are relayed under — see
/// `core/registration/unit_registration_service.dart` for the full flow
/// and `LockerGrpcService.userAudit` for what actually sends those events.
///
/// Uses the same navy/teal/Metropolis "admin chrome"
/// (`AdminSectionCard`/`AdminTextStyles`/`AdminInputStyle`) as
/// `ConfigurationPage` rather than default Material styling, so the two
/// settings screens read as one consistent surface.
class UnitRegistrationPage extends StatefulWidget {
  const UnitRegistrationPage({super.key});

  @override
  State<UnitRegistrationPage> createState() => _UnitRegistrationPageState();
}

class _UnitRegistrationPageState extends State<UnitRegistrationPage> {
  final _codeController = TextEditingController();
  final _service = UnitRegistrationService.instance;
  String? _resultMessage;
  bool _resultIsError = false;
  bool _refreshingJwt = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final error = await _service.registerWithCode(_codeController.text);
    if (!mounted) return;
    setState(() {
      _resultIsError = error != null;
      _resultMessage = error ??
          'Registered as "${_service.username}". mq.json has been '
              'written — audit events sent via LockerGrpcService.userAudit '
              'will now be relayed under this unit\'s identity.';
    });
    if (error == null) _codeController.clear();
  }

  Future<void> _refreshJwt() async {
    setState(() => _refreshingJwt = true);
    final ok = await _service.refreshJwt();
    if (!mounted) return;
    setState(() {
      _refreshingJwt = false;
      _resultIsError = !ok;
      _resultMessage = ok
          ? 'JWT refreshed — mq.json updated.'
          : 'Could not refresh the JWT. Check network connectivity and '
              'that this unit is still registered.';
    });
  }

  Future<void> _forget() async {
    await _service.forget();
    if (!mounted) return;
    setState(() {
      _resultMessage = 'Registration forgotten locally. auth.json/mq.json '
          'removed — this does not deregister the unit on the platform '
          'itself.';
      _resultIsError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Unit Registration',
          style: TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.panelBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _service,
              builder: (context, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _service.isRegistered
                      ? AppColors.teal.withOpacity(0.15)
                      : AppColors.adminCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _service.isRegistered ? AppColors.teal : AppColors.panelBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _service.isRegistered ? Icons.check_circle : Icons.info_outline,
                      color: _service.isRegistered ? AppColors.teal : Colors.white60,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _service.isRegistered
                            ? 'Registered as "${_service.username}"'
                            : 'Not registered with VaultGroup yet.',
                        style: const TextStyle(
                          fontFamily: 'Metropolis',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Registration code', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a unit + registration code on the VaultGroup '
                    'platform first, then enter it here.',
                    style: AdminTextStyles.body,
                  ),
                  const SizedBox(height: 10),
                  KeyboardTextField(
                    controller: _codeController,
                    style: AdminTextStyles.fieldInput,
                    decoration: AdminInputStyle.fieldDecoration(hint: 'Registration code'),
                    onSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _service,
                    builder: (context, _) => FilledButton.icon(
                      style: AdminInputStyle.primaryButton,
                      onPressed: _service.isBusy ? null : _register,
                      icon: _service.isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.how_to_reg),
                      label: const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Manage registration', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: AdminInputStyle.outlinedButton,
                          onPressed: _refreshingJwt ? null : _refreshJwt,
                          icon: _refreshingJwt
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Refresh JWT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent[100],
                            side: BorderSide(color: Colors.redAccent[100]!),
                            textStyle: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _forget,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Forget'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _resultMessage!,
                style: TextStyle(
                  fontFamily: 'Metropolis',
                  color: _resultIsError ? Colors.redAccent[100] : Colors.greenAccent[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
