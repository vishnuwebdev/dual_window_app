import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/mock/models.dart';
import '../../core/registration/audit_codes.dart';
import '../../core/utilities/logging.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'deliver_dropoff_complete_page.dart';

/// Ported from `DeliverPlaceParcelActivity` /
/// `activity_deliver_place_parcel.xml`: assigns a random free locker of the
/// chosen size, creates the parcel record (reusing an existing PIN for
/// this phone if one exists — see `MockKioskRepository.addItem`), and
/// tells the customer where to place the item.
///
/// Deviation from the Android source: there, both the 10s timeout and the
/// back button go straight to `MainActivity`, never to
/// `DeliverDropoffCompleteActivity` (which has no caller anywhere in the
/// app — see the screen inventory). Here they go to the Dropoff Complete
/// screen instead, so that screen has a reachable place in the flow. See
/// the same note in `privacy_statement_page.dart`.
class DeliverPlaceParcelPage extends StatefulWidget {
  const DeliverPlaceParcelPage({super.key, required this.phone, required this.size});

  final String phone;
  final LockerSize size;

  @override
  State<DeliverPlaceParcelPage> createState() => _DeliverPlaceParcelPageState();
}

class _DeliverPlaceParcelPageState extends State<DeliverPlaceParcelPage> {
  Timer? _autoAdvanceTimer;
  int? _lockerId;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    final repo = MockKioskRepository.instance;
    final locker = repo.pickRandomFreeLocker(widget.size);
    if (locker != null) {
      // Mirrors `DbService.addItem`'s audit trail: "started" before the
      // record is created, "success" after. See
      // `core/registration/audit_codes.dart`.
      final grpc = LockerGrpcService.instance;
      final isGrpc = ConfigService().isGrpcBackend;
      if (isGrpc) {
        unawaited(grpc.userAudit(
          code: AuditCodes.dropoffStarted,
          priority: AuditLogPriority.low,
          level: AuditLogLevel.info,
          description: 'Dropoff: started',
          parametersJson: '["${widget.phone}",${locker.id}]',
        ));
      }

      final item = repo.addItem(phone: widget.phone, lockerId: locker.id);
      _lockerId = locker.id;

      // Mirrors `DbService.addItem` -> `sendSms`: substitute the real PIN
      // into `config.json`'s `sms_template` and send the drop-off
      // notification. `repo.addItem` above already triggered the physical
      // unlock (see `MockKioskRepository._unlockPhysicalLocker`) when in
      // 'grpc' mode; this submits the SMS itself the same way.
      final message =
          ConfigService().smsTemplate.replaceAll('{pin}', item.pin);
      logger.i('Sending SMS to ${widget.phone}: "$message"');
      if (isGrpc) {
        unawaited(grpc.sendSms(widget.phone, message));
        unawaited(grpc.userAudit(
          code: AuditCodes.dropoffSuccess,
          priority: AuditLogPriority.medium,
          level: AuditLogLevel.info,
          description: 'Dropoff: success',
          parametersJson: '["${widget.phone}",${locker.id}]',
        ));
      }
    }

    _autoAdvanceTimer = Timer(const Duration(seconds: 10), _advance);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeliverDropoffCompletePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _lockerId == null
        ? 'Sorry, no lockers of that size are available right now.'
        : 'Please place your parcel(s) in locker $_lockerId and close the locker door once complete';

    return KioskScaffold(
      waves: KioskWaves.right,
      child: Stack(
        children: [
          BackImageButton(onPressed: _advance),
          Column(
            children: [
              const KioskHeader(),
              Expanded(
                child: Center(
                  child: InstructionPanel(text: text, width: 700, height: 380, fontSize: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
