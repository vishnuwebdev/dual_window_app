import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/registration/mqtt_sync_service.dart';
import '../../core/registration/settings_sync_service.dart';
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
/// Also surfaces the "physical unit sync" step (mirroring
/// `auth.json`/`mq.json` into the real `cvmain` config directory — see
/// `UnitRegistrationService.mirrorToCvmainConfig`), since registering
/// *this app* alone has no effect on whether the unit shows "online" on
/// VaultGroup's dashboard — that's driven entirely by cvmain's own MQTT
/// session on the physical unit. Restarting cvmain itself is deliberately
/// left as a manual SSH step (`sudo pkill -f cvmain_rs`) rather than
/// something this app automates — see the doc comment on
/// `mirrorToCvmainConfig` for why.
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
  final _config = ConfigService();
  final _mqtt = MqttSyncService.instance;

  late final TextEditingController _cvmainDirController;

  String? _resultMessage;
  bool _resultIsError = false;
  bool _refreshingJwt = false;
  bool _mirroring = false;
  bool _resetting = false;
  String? _syncSavedMessage;

  bool _pulling = false;
  bool _pushing = false;
  bool _reconnectingMqtt = false;
  String? _cloudSyncMessage;
  bool _cloudSyncIsError = false;

  @override
  void initState() {
    super.initState();
    _cvmainDirController = TextEditingController(text: _config.cvmainConfigDir);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cvmainDirController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final error = await _service.registerWithCode(_codeController.text);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _resultIsError = true;
        _resultMessage = error;
      });
      return;
    }

    _codeController.clear();
    final buffer = StringBuffer(
      'Registered as "${_service.username}". mq.json has been written — '
      'audit events sent via LockerGrpcService.userAudit will now be '
      'relayed under this unit\'s identity.',
    );

    // Auto-mirror to the physical unit's cvmain config dir right after a
    // successful registration, same as the Android flow does it in one
    // pass — but only if the admin has actually configured the directory
    // below; otherwise this is a no-op. Restarting cvmain is still a
    // manual step (see the "Physical unit sync" card below).
    final mirrorResult = await _service.mirrorToCvmainConfig();
    if (mirrorResult != null) buffer.write('\n\n$mirrorResult');

    // A fresh mq.json means a fresh MQTT identity — reconnect right away
    // rather than leaving the admin to notice the "Cloud settings sync"
    // card still shows the pre-registration disconnected status.
    unawaited(_mqtt.start());

    if (!mounted) return;
    setState(() {
      _resultIsError = false;
      _resultMessage = buffer.toString();
    });
  }

  Future<void> _refreshJwt() async {
    setState(() => _refreshingJwt = true);
    final ok = await _service.refreshJwt();
    if (ok) unawaited(_mqtt.start());
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

  /// Mirrors Android's `readSettingsFromServer`/`readDbFromServer` — pulls
  /// the SMS template, locker sizes, cvmain's native config, and the
  /// parcel database from the cloud. See `SettingsSyncService` for the
  /// full field-by-field breakdown of what's applied and what's skipped.
  Future<void> _pullFromCloud() async {
    setState(() {
      _pulling = true;
      _cloudSyncMessage = null;
    });
    final result = await SettingsSyncService.instance.pullFromServer();
    if (!mounted) return;
    setState(() {
      _pulling = false;
      _cloudSyncIsError = !result.success;
      _cloudSyncMessage = result.message;
    });
  }

  /// Mirrors Android's `putSettingsToTheServer` — pushes the SMS template,
  /// locker sizes, parcel database, and admin PIN to the cloud.
  Future<void> _pushToCloud() async {
    setState(() {
      _pushing = true;
      _cloudSyncMessage = null;
    });
    final result = await SettingsSyncService.instance.pushToServer();
    if (!mounted) return;
    setState(() {
      _pushing = false;
      _cloudSyncIsError = !result.success;
      _cloudSyncMessage = result.message;
    });
  }

  /// Re-runs `MqttSyncService.start()` — useful right after "Refresh JWT"
  /// above rotates the password in `mq.json`, or if the broker connection
  /// dropped and didn't auto-recover.
  Future<void> _reconnectMqtt() async {
    setState(() => _reconnectingMqtt = true);
    await _mqtt.start();
    if (!mounted) return;
    setState(() => _reconnectingMqtt = false);
  }

  Future<void> _saveSyncSettings() async {
    await _config.setCvmainConfigDir(_cvmainDirController.text);
    if (!mounted) return;
    setState(() {
      _syncSavedMessage = 'Saved.';
    });
  }

  Future<void> _mirrorNow() async {
    await _saveSyncSettings();
    setState(() => _mirroring = true);
    final result = await _service.mirrorToCvmainConfig();
    if (!mounted) return;
    setState(() {
      _mirroring = false;
      _syncSavedMessage = result ??
          'cvmain config directory is blank above — nothing to mirror.';
    });
  }

  /// Confirms before doing anything — unlike "Mirror now"/"Forget", this
  /// overwrites the physical unit's real `auth.json`/`mq.json` with the
  /// "-reset" template files, which can't be undone from this app.
  Future<void> _resetToFactoryDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.adminCard,
        title: const Text(
          'Reset unit registration?',
          style: TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: const Text(
          'This clears this app\'s local registration and overwrites the '
          'physical unit\'s auth.json and mq/mq.json with its factory '
          '"-reset" template files, in the cvmain config directory below. '
          'cvmain will still need a manual restart to pick it up. This '
          'cannot be undone from here.',
          style: TextStyle(fontFamily: 'Metropolis', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent[100]),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _resetting = true);
    final result = await _service.resetToFactoryDefaults();
    if (!mounted) return;
    setState(() {
      _resetting = false;
      _resultIsError = false;
      _resultMessage = result;
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
            const SizedBox(height: 24),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cloud settings sync', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'Manually pull/push the SMS template, locker sizes, and '
                    'parcel database to/from VaultGroup\'s cloud — mirrors '
                    'the Android app\'s settings sync. The cloud can also '
                    'trigger this automatically over MQTT once this unit '
                    'is registered above; connection status below.',
                    style: AdminTextStyles.body,
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _mqtt,
                    builder: (context, _) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _mqtt.isConnected
                            ? AppColors.teal.withOpacity(0.15)
                            : AppColors.adminFieldFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _mqtt.isConnected ? AppColors.teal : AppColors.panelBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _mqtt.isConnected ? Icons.cloud_done : Icons.cloud_off,
                            size: 18,
                            color: _mqtt.isConnected ? AppColors.teal : Colors.white60,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'MQTT: ${_mqtt.status}',
                              style: const TextStyle(fontFamily: 'Metropolis', color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _reconnectingMqtt ? null : _reconnectMqtt,
                            child: _reconnectingMqtt
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                  )
                                : const Text('Reconnect'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: AdminInputStyle.outlinedButton,
                          onPressed: _pulling ? null : _pullFromCloud,
                          icon: _pulling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                )
                              : const Icon(Icons.cloud_download_outlined),
                          label: const Text('Pull from cloud'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: AdminInputStyle.outlinedButton,
                          onPressed: _pushing ? null : _pushToCloud,
                          icon: _pushing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Push to cloud'),
                        ),
                      ),
                    ],
                  ),
                  if (_cloudSyncMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _cloudSyncMessage!,
                      style: TextStyle(
                        fontFamily: 'Metropolis',
                        color: _cloudSyncIsError ? Colors.redAccent[100] : Colors.greenAccent[400],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Physical unit sync', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'Registering above only updates this app\'s own copy of '
                    'auth.json/mq.json — it does NOT make the physical '
                    'unit show "online" on VaultGroup by itself. This app '
                    'copies those files into cvmain\'s real config folder '
                    'automatically after each registration (plain file '
                    'copy, no special permissions needed) — the directory '
                    'below is already set to this unit\'s confirmed path; '
                    'only change it if you\'re pointing at a different '
                    'unit, or clear it to skip mirroring entirely.',
                    style: AdminTextStyles.body,
                  ),
                  const SizedBox(height: 14),
                  const Text('cvmain config directory on the unit', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 8),
                  KeyboardTextField(
                    controller: _cvmainDirController,
                    style: AdminTextStyles.fieldInput,
                    decoration: AdminInputStyle.fieldDecoration(
                      hint: 'e.g. /home/pi/cv/cvmain/config — leave blank to skip',
                    ),
                    onSubmitted: (_) => _saveSyncSettings(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.adminFieldFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.panelBorder),
                    ),
                    child: const Text(
                      'After the files are copied, cvmain still needs a '
                      'restart to actually pick them up — that\'s a manual '
                      'step, on purpose. Over SSH:\n\n'
                      '  sudo pkill -f cvmain_rs\n\n'
                      'Its supervisor script relaunches it within a few '
                      'seconds with the new credentials. Check '
                      'cv/cvmain/logs/cvmain.log to confirm, then check '
                      'VaultGroup\'s dashboard.',
                      style: TextStyle(fontFamily: 'Metropolis', fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: AdminInputStyle.outlinedButton,
                          onPressed: _mirroring ? null : _mirrorNow,
                          icon: _mirroring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                )
                              : const Icon(Icons.drive_file_move_outline),
                          label: const Text('Mirror now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: AdminInputStyle.outlinedButton,
                          onPressed: _saveSyncSettings,
                          child: const Text('Save directory'),
                        ),
                      ),
                    ],
                  ),
                  if (_syncSavedMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _syncSavedMessage!,
                      style: const TextStyle(fontFamily: 'Metropolis', color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Factory reset', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'Clears this app\'s local registration, and overwrites '
                    'the physical unit\'s real auth.json and mq/mq.json '
                    '(in the cvmain config directory above) with its '
                    'factory "auth.json-reset"/"mq.json-reset" template '
                    'files. Use this to fully unregister the unit before '
                    're-registering it, or handing it off. cvmain still '
                    'needs a manual restart afterwards to pick this up.',
                    style: AdminTextStyles.body,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent[100],
                      side: BorderSide(color: Colors.redAccent[100]!),
                      textStyle: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _resetting ? null : _resetToFactoryDefaults,
                    icon: _resetting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent[100]),
                          )
                        : const Icon(Icons.restart_alt),
                    label: const Text('Reset to factory defaults'),
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
