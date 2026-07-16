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

/// One locker pairing being edited on-screen, before it's actually saved
/// — see `_ConfigurationPageState._pendingPairs`. Mirrors
/// `LockerPairMapping` (the persisted shape); kept as a separate tiny type
/// so the in-progress editor list doesn't need to round-trip through
/// `ConfigService` on every add/remove.
class _PendingLockerPair {
  const _PendingLockerPair({required this.dropoffId, required this.collectionId});

  final int dropoffId;
  final int collectionId;
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
  // See `ConfigService.pairedLockerMode`. Off by default. Two independent
  // pieces sit under this toggle:
  //
  // - `_boardCountsController` (optional): purely a *display* aid — see
  //   `ConfigService.boardLockerCounts`'s doc comment — labels lockers as
  //   "Board N, Locker L" instead of a raw number. Has no effect on which
  //   lockers are actually paired.
  // - `_pendingPairs` (required before drop-off works): the actual
  //   drop-off/collection locker links, freely chosen below — any two
  //   not-yet-used lockers can be linked, in any combination. See
  //   `ConfigService.lockerPairMappings`.
  late final TextEditingController _boardCountsController;
  late bool _pairedMode;
  String? _boardCountsError;

  final List<_PendingLockerPair> _pendingPairs = [];
  int? _selectedDropoffId;
  int? _selectedCollectionId;
  String? _pairingError;

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
    _loadPendingPairsFromConfig();
  }

  void _loadPendingPairsFromConfig() {
    _pendingPairs
      ..clear()
      ..addAll(_config.lockerPairMappings.map((p) => _PendingLockerPair(
            dropoffId: p.dropoffLockerId,
            collectionId: p.collectionLockerId,
          )));
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

    // The flat mapping is always saved first — the board layout and
    // pairing below are both validated against *this* new total, so it
    // has to land before either of them.
    final mappingError =
        await _config.setLockerMapping(_lockerMappingController.text.trim());
    if (mappingError != null) {
      setState(() {
        _lockerMappingError = mappingError;
        _boardCountsError = null;
        _pairingError = null;
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
          _pairingError = null;
          _savedMessage = null;
        });
        return;
      }

      final pairingError = await _config.setLockerPairMappings([
        for (final p in _pendingPairs)
          LockerPairMapping(
            dropoffLockerId: p.dropoffId,
            collectionLockerId: p.collectionId,
          ),
      ]);
      if (pairingError != null) {
        setState(() {
          _lockerMappingError = null;
          _boardCountsError = null;
          _pairingError = pairingError;
          _savedMessage = null;
        });
        return;
      }
    }

    setState(() {
      _lockerMappingError = null;
      _boardCountsError = null;
      _pairingError = null;
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
      _loadPendingPairsFromConfig();
      _selectedDropoffId = null;
      _selectedCollectionId = null;
      _lockerMappingError = null;
      _boardCountsError = null;
      _pairingError = null;
      _connectionResult = null;
      _syncResult = null;
      _savedMessage = 'Reset to defaults.';
    });
  }

  void _addPendingPair() {
    final dropoffId = _selectedDropoffId;
    final collectionId = _selectedCollectionId;
    if (dropoffId == null || collectionId == null || dropoffId == collectionId) {
      return;
    }
    setState(() {
      _pendingPairs.add(_PendingLockerPair(dropoffId: dropoffId, collectionId: collectionId));
      _selectedDropoffId = null;
      _selectedCollectionId = null;
      _pairingError = null;
    });
  }

  void _removePendingPair(int index) {
    setState(() {
      _pendingPairs.removeAt(index);
      _pairingError = null;
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

    // Pairing UI state, derived fresh every build from `_pendingPairs` and
    // the *currently saved* locker mapping (not whatever's unsaved in
    // `_lockerMappingController` — see the "Locker pairing" section's
    // helper text telling the admin to save the mapping above first).
    final totalLockers = _config.lockerMapping.length;
    final usedIds = _pendingPairs.expand((p) => [p.dropoffId, p.collectionId]).toSet();
    final allLockerIds = List.generate(totalLockers, (i) => i + 1);
    final availableIds = allLockerIds.where((id) => !usedIds.contains(id)).toList();
    final dropoffValue =
        (_selectedDropoffId != null && availableIds.contains(_selectedDropoffId))
            ? _selectedDropoffId
            : null;
    final collectionValue =
        (_selectedCollectionId != null && availableIds.contains(_selectedCollectionId))
            ? _selectedCollectionId
            : null;
    final dropoffOptions = availableIds.where((id) => id != collectionValue).toList();
    final collectionOptions = availableIds.where((id) => id != dropoffValue).toList();
    final maxUnmapped = totalLockers.isOdd ? 1 : 0;
    final unmapped = totalLockers - usedIds.length;
    final isPairingComplete = unmapped <= maxUnmapped;

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
                    'id is its position in this list — that\'s the number used '
                    'below to pair lockers together.',
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
                            Text('Paired lockers', style: AdminTextStyles.sectionTitle),
                            SizedBox(height: 6),
                            Text(
                              'For a wall-mounted setup where a drop-off '
                              'door has a matching collection door wired '
                              'to the same cavity: dropping a parcel off '
                              'in one locker means it\'s collected by '
                              'opening its linked locker instead, and '
                              'both show occupied in between. Turn this '
                              'on, then pair lockers below.',
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
                ],
              ),
            ),
            if (_pairedMode) ...[
              const SizedBox(height: 16),
              AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Board layout (optional)', style: AdminTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    const Text(
                      'Only affects the wording shown to customers/admins '
                      '— e.g. "Board 2, Locker 3" instead of a raw number '
                      '— so it matches what\'s printed on the physical '
                      'door. Doesn\'t affect pairing at all. How many '
                      'lockers belong to each board, in the same order as '
                      'the locker mapping above (comma-separated). Leave '
                      'blank to just show plain numbers.',
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
                ),
              ),
              const SizedBox(height: 16),
              AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Locker pairing', style: AdminTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick any two unpaired lockers and link them — the '
                      'first is the drop-off door, the second is where '
                      'that parcel is collected from. Every locker can '
                      'only be used once. If the locker mapping above has '
                      'an odd count, one locker is allowed to stay '
                      'unpaired. Drop-off stays unavailable to customers '
                      'until pairing below is complete. Save the locker '
                      'mapping above first if you just changed it — the '
                      'lockers offered below come from the saved count.',
                      style: AdminTextStyles.body,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      totalLockers == 0
                          ? 'No lockers configured yet.'
                          : isPairingComplete
                              ? 'All set — ${usedIds.length} of $totalLockers locker(s) paired.'
                              : '${usedIds.length} of $totalLockers locker(s) paired — '
                                  'drop-off stays disabled until this is complete.',
                      style: TextStyle(
                        fontFamily: 'Metropolis',
                        fontWeight: FontWeight.w600,
                        color: isPairingComplete
                            ? Colors.greenAccent[400]
                            : Colors.amber[300],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            // `value` (not the newer `initialValue`) for
                            // compatibility with older pinned Flutter SDKs
                            // — same reasoning as `activeColor` elsewhere
                            // on this page.
                            value: dropoffValue,
                            dropdownColor: AppColors.adminFieldFill,
                            style: AdminTextStyles.fieldInput,
                            decoration: AdminInputStyle.fieldDecoration(hint: 'Drop-off locker'),
                            items: [
                              for (final id in dropoffOptions)
                                DropdownMenuItem(value: id, child: Text('Locker $id')),
                            ],
                            onChanged: (value) => setState(() => _selectedDropoffId = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, color: Colors.white54),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: collectionValue,
                            dropdownColor: AppColors.adminFieldFill,
                            style: AdminTextStyles.fieldInput,
                            decoration: AdminInputStyle.fieldDecoration(hint: 'Collection locker'),
                            items: [
                              for (final id in collectionOptions)
                                DropdownMenuItem(value: id, child: Text('Locker $id')),
                            ],
                            onChanged: (value) => setState(() => _selectedCollectionId = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: AdminInputStyle.outlinedButton,
                      onPressed: (dropoffValue != null && collectionValue != null)
                          ? _addPendingPair
                          : null,
                      icon: const Icon(Icons.link),
                      label: const Text('Add pair'),
                    ),
                    if (_pendingPairs.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Drop-off locker',
                                style: AdminTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Text('Collection locker',
                                style: AdminTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const Divider(color: AppColors.panelBorder),
                      for (var i = 0; i < _pendingPairs.length; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text('${_pendingPairs[i].dropoffId}', style: AdminTextStyles.fieldInput),
                            ),
                            Expanded(
                              child: Text('${_pendingPairs[i].collectionId}', style: AdminTextStyles.fieldInput),
                            ),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                                tooltip: 'Remove pair',
                                onPressed: () => _removePendingPair(i),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Colors.white12),
                      ],
                    ],
                    if (_pairingError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _pairingError!,
                        style: TextStyle(fontFamily: 'Metropolis', color: Colors.redAccent[100]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
