import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/admin_section_card.dart';
import '../../widgets/keyboard_text_field.dart';

/// Admin window — Configuration page.
///
/// `ConfigurationActivity` in the Android app was an empty stub (just
/// inflated a blank layout, no logic, and nothing in the app ever
/// navigated to it — see the screen inventory). Rather than port an empty
/// screen, this version gives it a real job: choosing between the mock
/// backend and a real physical unit, editing the locker gRPC backend
/// address, and editing the locker inventory — all managed by this
/// project's `ConfigService` (see `core/config/config_service.dart`).
///
/// Styling note: earlier versions of this page used a bare `Scaffold`
/// with no explicit colors, which meant it silently inherited the app's
/// forced navy `scaffoldBackgroundColor` (see `AdminWindowApp`) while its
/// text and controls stayed at Material's *light-theme* defaults — dark
/// text on a navy background, barely readable. This version opts in to
/// the same navy/teal/Metropolis "admin chrome" (`AppColors`,
/// `AdminSectionCard`/`AdminTextStyles`/`AdminInputStyle` — shared with
/// `UnitRegistrationPage`) instead of inheriting it by accident.
class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  late final TextEditingController _addressController;
  late final TextEditingController _lockerMappingController;
  final _config = ConfigService();
  late String _backend;
  late bool _kioskMode;
  String? _savedMessage;
  String? _lockerMappingError;
  bool _checkingConnection = false;
  String? _connectionResult;
  bool _syncingLockers = false;
  String? _syncResult;

  // --- Paired slave-board mode ------------------------------------------
  //
  // See `ConfigService.pairedLockerMode`/`boardLockerCounts`: an overlay
  // on top of the flat "Locker mapping" above, for the "drop-off board
  // mounted opposite a matching collection board" physical topology. Off
  // by default. Unlike the flat mapping (which is *always* in effect),
  // this is purely additive — the locker mapping above still lists every
  // physical door, board by board; this just says how many doors belong
  // to each board so sequential boards can be paired up.
  late final TextEditingController _boardCountsController;
  late bool _pairedMode;
  String? _boardCountsError;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: _config.lockerAddress);
    // Shown as the comma-separated size shorthand (e.g.
    // "small,small,medium,large") — see `ConfigService.lockerMappingText`.
    _lockerMappingController =
        TextEditingController(text: _config.lockerMappingText);
    _boardCountsController =
        TextEditingController(text: _config.boardLockerCountsText);
    _backend = _config.lockerBackend;
    _kioskMode = _config.kioskMode;
    _pairedMode = _config.pairedLockerMode;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _lockerMappingController.dispose();
    _boardCountsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    await _config.setLockerAddress(address);
    await _config.setLockerBackend(_backend);
    await _config.setKioskMode(_kioskMode);

    // The flat mapping is always saved first and always applies — paired
    // mode is an overlay on top of it, not a replacement (see the class
    // doc comment on `_boardCountsController`).
    final mappingError =
        await _config.setLockerMapping(_lockerMappingController.text.trim());
    if (mappingError != null) {
      setState(() {
        _lockerMappingError = mappingError;
        _savedMessage = null;
      });
      return;
    }

    await _config.setPairedLockerMode(_pairedMode);

    if (_pairedMode) {
      final boardCountsError =
          await _config.setBoardLockerCounts(_boardCountsController.text.trim());
      if (boardCountsError != null) {
        setState(() {
          _lockerMappingError = null;
          _boardCountsError = boardCountsError;
          _savedMessage = null;
        });
        return;
      }
    }

    setState(() {
      _lockerMappingError = null;
      _boardCountsError = null;
      _connectionResult = null;
      _savedMessage = _backend == 'grpc'
          ? 'Saved. Real hardware mode — address: $address'
          : 'Saved. Mock mode — no physical unit contacted.';
    });
  }

  Future<void> _reset() async {
    await _config.reset();
    setState(() {
      _addressController.text = _config.lockerAddress;
      _lockerMappingController.text = _config.lockerMappingText;
      _boardCountsController.text = _config.boardLockerCountsText;
      _backend = _config.lockerBackend;
      _kioskMode = _config.kioskMode;
      _pairedMode = _config.pairedLockerMode;
      _lockerMappingError = null;
      _boardCountsError = null;
      _connectionResult = null;
      _syncResult = null;
      _savedMessage = 'Reset to defaults.';
    });
  }

  /// Asks the unit how many lockers it has and reconciles
  /// `ConfigService.lockerMapping` to match, then refreshes the mapping
  /// field to show the result — see
  /// `MockKioskRepository.syncLockersFromHardware`.
  Future<void> _syncLockersFromHardware() async {
    setState(() {
      _syncingLockers = true;
      _syncResult = null;
    });

    final ok = await MockKioskRepository.instance.syncLockersFromHardware();

    if (!mounted) return;
    setState(() {
      _syncingLockers = false;
      _lockerMappingController.text = _config.lockerMappingText;
      _syncResult = ok
          ? 'Synced — locker mapping now has '
              '${_config.lockerMapping.length} locker(s). Sizes were kept '
              'where possible; review before saving.'
          : 'Could not reach the unit to fetch locker count. Try Test '
              'Connection above first.';
    });
  }

  /// Manually exercises `LockerGrpcService.checkHealth()` (via
  /// `MockKioskRepository.checkBackendHealth`) against whatever address is
  /// currently in the field — mirrors the Android app's
  /// `MainActivity.handleGrpcCall` liveness check, but as an explicit,
  /// admin-triggered action here rather than gating every button press.
  Future<void> _testConnection() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _checkingConnection = true;
      _connectionResult = null;
    });

    // Test against whatever's in the field right now, even if it hasn't
    // been saved yet, by pointing ConfigService at it first. If the admin
    // cancels out without saving, the previous address is still in
    // config.json — this only affects the live in-memory value.
    await _config.setLockerAddress(address);
    final reachable = await MockKioskRepository.instance.checkBackendHealth();

    if (!mounted) return;
    setState(() {
      _checkingConnection = false;
      _connectionResult = reachable
          ? 'Unit responded — connection OK.'
          : 'No response from $address. Check the unit is powered on, '
              'reachable on the network, and cvmain is running.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGrpc = _backend == 'grpc';

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configuration',
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
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Locker backend', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AppColors.adminFieldFill,
                      foregroundColor: Colors.white70,
                      selectedBackgroundColor: AppColors.teal,
                      selectedForegroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.panelBorder),
                      textStyle: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.w600),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 'mock',
                        label: Text('Mock'),
                        icon: Icon(Icons.developer_mode),
                      ),
                      ButtonSegment(
                        value: 'grpc',
                        label: Text('Real hardware'),
                        icon: Icon(Icons.lock_outline),
                      ),
                    ],
                    selected: {_backend},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _backend = selection.first;
                        _connectionResult = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGrpc
                        ? 'Drop-off, collection, and admin-override actions send '
                            'real unlock_locker calls to the address below.'
                        : 'Everything runs in-memory / via db.json — no physical '
                            'unit is contacted.',
                    style: AdminTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kiosk mode', style: AdminTextStyles.sectionTitle),
                        const SizedBox(height: 6),
                        const Text(
                          'Frameless, fullscreen windows — for a Raspberry '
                          'Pi/kiosk deployment. Leave off for normal window '
                          'chrome during development. Takes effect the next '
                          'time each window is restarted, not immediately.',
                          style: AdminTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _kioskMode,
                    // `activeColor` (not the newer `activeThumbColor`) for
                    // compatibility with older pinned Flutter SDKs — see
                    // the same reasoning on `Colors.green.withOpacity` used
                    // elsewhere in the admin pages.
                    activeColor: AppColors.teal,
                    activeTrackColor: AppColors.teal.withOpacity(0.4),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    onChanged: (value) => setState(() => _kioskMode = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Locker backend address (IP:PORT)', style: AdminTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  KeyboardTextField(
                    controller: _addressController,
                    style: AdminTextStyles.fieldInput,
                    decoration: AdminInputStyle.fieldDecoration(hint: '192.168.8.107:7777'),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: AdminInputStyle.outlinedButton,
                        onPressed: _checkingConnection ? null : _testConnection,
                        icon: _checkingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: const Text('Test Connection'),
                      ),
                      if (_connectionResult != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _connectionResult!,
                            style: TextStyle(
                              fontFamily: 'Metropolis',
                              color: _connectionResult!.startsWith('Unit responded')
                                  ? Colors.greenAccent[400]
                                  : Colors.redAccent[100],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Locker mapping — one size per physical locker, in order '
                    '(small, medium, or large, comma-separated). Each locker\'s '
                    'id is its position in this list. In paired mode below, '
                    'this is every door on every board, board by board '
                    '(e.g. board 1\'s doors, then board 2\'s, then board 3\'s...).',
                    style: AdminTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  KeyboardTextField(
                    controller: _lockerMappingController,
                    style: AdminTextStyles.fieldInput,
                    decoration: AdminInputStyle.fieldDecoration(
                      hint: 'small,small,medium,medium,large,large',
                      errorText: _lockerMappingError,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: AdminInputStyle.outlinedButton,
                        onPressed: (_syncingLockers || !isGrpc) ? null : _syncLockersFromHardware,
                        icon: _syncingLockers
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Sync Lockers from Hardware'),
                      ),
                      if (!isGrpc) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Switch to Real hardware mode to use this.',
                            style: AdminTextStyles.body,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_syncResult != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _syncResult!,
                      style: TextStyle(
                        fontFamily: 'Metropolis',
                        color: _syncResult!.startsWith('Synced')
                            ? Colors.greenAccent[400]
                            : Colors.redAccent[100],
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paired slave boards', style: AdminTextStyles.sectionTitle),
                            SizedBox(height: 6),
                            Text(
                              'For a wall-mounted setup where each drop-off '
                              'board is paired with a matching collection '
                              'board on the other side of the wall: a '
                              'drop-off into locker N of the pair\'s '
                              'drop-off board is collected by opening '
                              'locker N of the paired collection board, '
                              'and both doors show occupied until it\'s '
                              'collected. Boards pair up sequentially — '
                              'board 1 with board 2, board 3 with board '
                              '4, and so on.',
                              style: AdminTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _pairedMode,
                        activeColor: AppColors.teal,
                        activeTrackColor: AppColors.teal.withOpacity(0.4),
                        inactiveThumbColor: Colors.white70,
                        inactiveTrackColor: Colors.white24,
                        onChanged: (value) => setState(() => _pairedMode = value),
                      ),
                    ],
                  ),
                  if (_pairedMode) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Board sizes — how many lockers belong to each '
                      'board, in the same order as the locker mapping '
                      'above (comma-separated). Needs an even number of '
                      'boards, and a pair\'s two boards must match. E.g. '
                      '"4,4,4,4" for four 4-locker boards (board 1 paired '
                      'with board 2, board 3 with board 4).',
                      style: AdminTextStyles.body,
                    ),
                    const SizedBox(height: 10),
                    KeyboardTextField(
                      controller: _boardCountsController,
                      style: AdminTextStyles.fieldInput,
                      decoration: AdminInputStyle.fieldDecoration(
                        hint: '4,4,4,4',
                        errorText: _boardCountsError,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: AdminInputStyle.primaryButton,
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: AdminInputStyle.outlinedButton,
                    onPressed: _reset,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Default'),
                  ),
                ),
              ],
            ),
            if (_savedMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _savedMessage!,
                style: TextStyle(fontFamily: 'Metropolis', color: Colors.greenAccent[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
