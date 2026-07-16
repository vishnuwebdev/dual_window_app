import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/mock/models.dart';
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
///
/// In `ConfigService.pairedLockerMode`, every physical door (drop-off side
/// and collection side alike) is its own real [Locker] with its own row —
/// see `MockKioskRepository.getAdminDoorRows`. Both rows of a pair always
/// show the same occupied state (see `MockKioskRepository.isLockerFree`),
/// and checking either row's checkbox and hitting "Clear" clears/opens
/// both doors (see `MockKioskRepository.clearLocker`); each row also gets
/// its own small "Open" icon for opening just that one specific door.
///
/// Named `LockerManagementPage` (not `AdminOverridePage`, an earlier
/// name carried over from the Android source's `AdminOverrideActivity`)
/// to match the "Locker Management" label this is actually reached by
/// from `AdminMenuPage` — the class/file name had drifted from the
/// user-facing name.
class LockerManagementPage extends StatefulWidget {
  const LockerManagementPage({super.key});

  @override
  State<LockerManagementPage> createState() => _LockerManagementPageState();
}

class _LockerManagementPageState extends State<LockerManagementPage> {
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

  /// Bulk "Open" (from checkbox selection): opens exactly the checked
  /// rows' doors — each row is now its own real physical locker id (see
  /// `MockKioskRepository.getAdminDoorRows`), so there's no "which side"
  /// ambiguity to resolve here anymore. To open both doors of a pair, an
  /// admin checks both of that pair's rows.
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

  /// Per-row "Open" (see [AdminDoorRow]): opens exactly the one physical
  /// door the row represents, regardless of checkbox selection.
  void _handleOpenRow(AdminDoorRow row) {
    _repo.openLockerOnly(row.lockerId);
    _sendAdminUnlockAudit(row.lockerId);
    _showMessage('${row.label} unlocked.');
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
      // In paired mode, `clearLocker` already opens both physical doors
      // internally — see its doc comment.
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
    final rows = _repo.getAdminDoorRows();

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
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _TableRow(
                      row: row,
                      selected: _selectedLockerIds.contains(row.lockerId),
                      onChanged: (value) => _toggleLocker(row.lockerId, value),
                      onOpen: () => _handleOpenRow(row),
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
                    _ManagementButton(label: 'Back', onPressed: () => Navigator.of(context).pop()),
                    _ManagementButton(label: 'Clear', onPressed: _handleClear),
                    _ManagementButton(label: 'Open', onPressed: _handleOpen),
                    _ManagementButton(label: 'Open All', onPressed: _handleOpenAll),
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
class _ManagementButton extends StatelessWidget {
  const _ManagementButton({required this.label, required this.onPressed});

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
        const Expanded(flex: 2, child: Text('Locker', style: _style)),
        const Expanded(child: Text('Status', style: _style)),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.row,
    required this.selected,
    required this.onChanged,
    required this.onOpen,
  });

  final AdminDoorRow row;
  final bool selected;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpen;

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
          Expanded(flex: 2, child: Text(row.label, style: style)),
          Expanded(
            child: Text(
              row.occupied ? 'Occupied' : 'Free',
              style: style.copyWith(color: row.occupied ? Colors.orange[800] : Colors.green[700]),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.lock_open, size: 20, color: Colors.black54),
              tooltip: 'Open just this door',
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
