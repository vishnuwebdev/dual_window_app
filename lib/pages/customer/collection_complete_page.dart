import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/registration/audit_codes.dart';
import '../../widgets/kiosk/kiosk.dart';

/// Ported from `CollectionCompleteActivity` /
/// `activity_collection_complete.xml`: tells the customer which locker(s)
/// to open, removes the collected item(s) from the mock repository, and
/// auto-returns to Home after 8 seconds (Android used
/// `postDelayed(delayMillis = 8000)`).
class CollectionCompletePage extends StatefulWidget {
  const CollectionCompletePage({
    super.key,
    required this.phone,
    required this.oneTimePin,
  });

  final String phone;
  final String oneTimePin;

  @override
  State<CollectionCompletePage> createState() => _CollectionCompletePageState();
}

class _CollectionCompletePageState extends State<CollectionCompletePage>
    with InactivityTimerMixin {
  // Android used INACTIVITY_TIMEOUT_HALF_MINUTE + 10s here specifically.
  @override
  Duration get inactivityTimeout => const Duration(seconds: 40);

  Timer? _autoReturnTimer;
  late final List<int> _lockerIds;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();

    final repo = MockKioskRepository.instance;
    final matches = repo
        .itemsForPhone(widget.phone)
        .where((item) => item.pin == widget.oneTimePin)
        .toList();
    _lockerIds = matches.map((item) => item.lockerId).toList()..sort();

    // Audit trail mirrors `DbService.removeItem`'s pickup flow. A pin that
    // matched nothing approximates Android's AUDIT_LOG_PICKUP_WRONG_PIN;
    // there isn't a distinct call site for that in this port to match
    // exactly, so this is inferred rather than a direct port.
    if (ConfigService().isGrpcBackend) {
      final grpc = LockerGrpcService.instance;
      if (matches.isNotEmpty) {
        unawaited(grpc.userAudit(
          code: AuditCodes.pickupStarted,
          priority: AuditLogPriority.low,
          level: AuditLogLevel.info,
          description: 'Pickup: started',
          parametersJson: '["${widget.phone}",${_lockerIds.join(",")}]',
        ));
        unawaited(grpc.userAudit(
          code: AuditCodes.pickupSuccess,
          priority: AuditLogPriority.medium,
          level: AuditLogLevel.info,
          description: 'Pickup: success',
          parametersJson: '["${widget.phone}",${_lockerIds.join(",")}]',
        ));
      } else {
        unawaited(grpc.userAudit(
          code: AuditCodes.pickupWrongPin,
          priority: AuditLogPriority.normal,
          level: AuditLogLevel.warning,
          description: 'Pickup: wrong pin',
          parametersJson: '["${widget.phone}"]',
        ));
      }
    }

    // Collecting the parcel removes it from the mock repository, freeing
    // the locker(s) up again — matches `dbService.removeItem(item)`.
    repo.removeItems(matches);

    _autoReturnTimer = Timer(const Duration(seconds: 8), _returnHome);
  }

  @override
  void onInactivityTimeout() => _returnHome();

  void _returnHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Pop back to the existing root `HomePage` route (each window's
    // `MaterialApp.home`) instead of pushing a fresh one — a fresh
    // `HomePage()` would use its default `dropOffEnabled`/`collectEnabled`
    // rather than this window's actual role, showing the wrong buttons.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _lockerIds.length > 1
        ? 'Please collect your parcels from lockers ${_lockerIds.join(', ')} and close the locker door once complete'
        : 'Please collect your parcel from locker ${_lockerIds.isEmpty ? '-' : _lockerIds.first} and close the locker door once complete';

    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.left,
        child: Stack(
          children: [
            BackImageButton(onPressed: _returnHome),
            Column(
              children: [
                const KioskHeader(),
                Expanded(
                  child: Center(
                    child: InstructionPanel(text: text, width: 700, height: 380, fontSize: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
