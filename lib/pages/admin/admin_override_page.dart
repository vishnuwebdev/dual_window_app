import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/registration/audit_codes.dart';
import 'configuration_page.dart';

/// Ported from `AdminOverrideActivity` / `activity_admin_override.xml`: the
/// admin locker-management table — a plain white checklist (Select All +
/// per-row checkboxes) with LockerId / Status columns, and Back / Clear /
/// Open / Open All controls at the bottom.
///
/// The Android activity is ~1,080 lines wired to real HTTP calls against
/// the locker backend; only its layout and table/button structure were
/// ported here (see the "UI + navigation first" scope decision — this
/// screen isn't wired to `LockerService`/gRPC yet). "Clear"/"Open" act on
/// every checked row; "Open all" clears every occupied locker regardless
/// of selection.
class AdminOverridePage extends StatefulWidget {
  const AdminOverridePage({super.key});

  @override
  State<AdminOverridePage> createState() => _AdminOverridePageState();
}

class _AdminOverridePageState extends State<AdminOverridePage> {
  final _repo = MockKioskRepository.instance;
  final Set<int> _selectedLockerIds = {};

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() => setState(() {});

  bool get _allSelected {
    final ids = _repo.getAllLockers().map((l) => l.id);
    return ids.isNotEmpty && ids.every(_selectedLockerIds.contains);
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedLockerIds.addAll(_repo.getAllLockers().map((l) => l.id));
      } else {
        _selectedLockerIds.clear();
      }
    });
  }

  void _toggleLocker(int lockerId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedLockerIds.add(lockerId);
      } else {
        _selectedLockerIds.remove(lockerId);
      }
    });
  }

  void _handleOpen() {
    if (_selectedLockerIds.isEmpty) {
      _showMessage('Select at least one locker first.');
      return;
    }
    for (final id in _selectedLockerIds) {
      // Mirrors `AdminOverrideActivity`'s "Open" action: physically unlock
      // without clearing the parcel record (see
      // `MockKioskRepository.openLockerOnly`, distinct from "Clear").
      _repo.openLockerOnly(id);
      _sendAdminUnlockAudit(id);
    }
    _showMessage('Locker(s) ${_selectedLockerIds.join(', ')} unlocked.');
  }

  /// Mirrors `openLockerWithAdminLogs`: sends both the "starting" and
  /// "success" audit events around an admin-triggered unlock. Fire-and-
  /// forget, and only actually reaches the unit in `'grpc'` mode — see
  /// `LockerGrpcService.userAudit`.
  void _sendAdminUnlockAudit(int lockerId) {
    if (!ConfigService().isGrpcBackend) return;
    final grpc = LockerGrpcService.instance;
    unawaited(grpc.userAudit(
      code: AuditCodes.adminUnlockStarting,
      priority: AuditLogPriority.normal,
      level: AuditLogLevel.info,
      description: 'Admin unlock: starting',
      parametersJson: '[$lockerId,false,true]',
    ));
    unawaited(grpc.userAudit(
      code: AuditCodes.adminUnlockSuccess,
      priority: AuditLogPriority.veryHigh,
      level: AuditLogLevel.info,
      description: 'Admin unlock: success',
      parametersJson: '[$lockerId,false,true]',
    ));
  }

  void _handleClear() {
    if (_selectedLockerIds.isEmpty) {
      _showMessage('Select at least one locker first.');
      return;
    }
    for (final id in _selectedLockerIds) {
      _repo.clearLocker(id);
    }
    setState(() => _selectedLockerIds.clear());
    _showMessage('Selected locker(s) cleared.');
  }

  void _handleOpenAll() {
    _repo.clearAllLockers();
    setState(() => _selectedLockerIds.clear());
    _showMessage('All lockers opened and cleared.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final lockers = _repo.getAllLockers();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Version 0.1.0',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black54),
                    tooltip: 'Configuration',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConfigurationPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TableHeader(allSelected: _allSelected, onSelectAll: _toggleSelectAll),
              const Divider(height: 1, color: Colors.black12),
              Expanded(
                child: ListView.separated(
                  itemCount: lockers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final locker = lockers[index];
                    final occupied = !_repo.isLockerFree(locker.id);
                    return _TableRow(
                      lockerId: locker.id,
                      occupied: occupied,
                      selected: _selectedLockerIds.contains(locker.id),
                      onChanged: (value) => _toggleLocker(locker.id, value),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.black26),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _OverrideButton(label: 'Back', onPressed: () => Navigator.of(context).pop()),
                    _OverrideButton(label: 'Clear', onPressed: _handleClear),
                    _OverrideButton(label: 'Open', onPressed: _handleOpen),
                    _OverrideButton(label: 'Open All', onPressed: _handleOpenAll),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark-navy pill button used for Back/Clear/Open/Open All, matching
/// the reference design's plain filled buttons (distinct from the kiosk
/// app's bordered `KioskButton`, since this screen sits on a white
/// background rather than the navy kiosk chrome).
class _OverrideButton extends StatelessWidget {
  const _OverrideButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E2844),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.allSelected, required this.onSelectAll});

  final bool allSelected;
  final ValueChanged<bool?> onSelectAll;

  static const _style = TextStyle(fontFamily: 'Metropolis', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Checkbox(value: allSelected, onChanged: onSelectAll),
              const Text('Select All', style: _style),
            ],
          ),
        ),
        const Expanded(child: Text('LockerId', style: _style)),
        const Expanded(child: Text('Status', style: _style)),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.lockerId,
    required this.occupied,
    required this.selected,
    required this.onChanged,
  });

  final int lockerId;
  final bool occupied;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'Metropolis', fontSize: 16, color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Checkbox(value: selected, onChanged: onChanged),
          ),
          Expanded(child: Text('$lockerId', style: style)),
          Expanded(
            child: Text(
              occupied ? 'Occupied' : 'Free',
              style: style.copyWith(color: occupied ? Colors.orange[800] : Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }
}
