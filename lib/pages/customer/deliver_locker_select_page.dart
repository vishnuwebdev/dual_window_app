import 'package:flutter/material.dart';

import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/mock/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'deliver_place_parcel_page.dart';

/// Ported from `DeliverLockerSelectActivity` /
/// `activity_deliver_locker_select.xml`: pick a locker size, showing a
/// live free-locker count per size and disabling sizes with none free.
class DeliverLockerSelectPage extends StatefulWidget {
  const DeliverLockerSelectPage({super.key, required this.phone});

  final String phone;

  @override
  State<DeliverLockerSelectPage> createState() =>
      _DeliverLockerSelectPageState();
}

class _DeliverLockerSelectPageState extends State<DeliverLockerSelectPage>
    with InactivityTimerMixin {
  final _repo = MockKioskRepository.instance;
  LockerSize? _selected;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _selectSize(LockerSize size, int count) {
    if (count == 0) {
      InfoDialog.show(
        context,
        message:
            'No ${_label(size).toLowerCase()} lockers available. Please choose another locker size',
      );
      return;
    }
    setState(() => _selected = _selected == size ? null : size);
  }

  String _label(LockerSize size) {
    switch (size) {
      case LockerSize.small:
        return 'SMALL';
      case LockerSize.medium:
        return 'MEDIUM';
      case LockerSize.large:
        return 'LARGE';
    }
  }

  void _handleContinue() {
    final selected = _selected;
    if (selected == null) {
      InfoDialog.show(context, message: 'Please select locker size');
      return;
    }
    stopInactivityTimer();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DeliverPlaceParcelPage(phone: widget.phone, size: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final free = _repo.getFreeLockers();
    final counts = {
      for (final size in LockerSize.values)
        size: free.where((l) => l.size == size).length,
    };

    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.left,
        child: Column(
          children: [
            const KioskHeader(),
            const SizedBox(height: 24),
            Text('Select locker size',
                style: AppTextStyles.heading.copyWith(fontSize: 44)),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SizeBox(
                      label: 'SMALL',
                      count: counts[LockerSize.small]!,
                      size: 130,
                      selected: _selected == LockerSize.small,
                      onTap: () => _selectSize(
                          LockerSize.small, counts[LockerSize.small]!),
                    ),
                    const SizedBox(width: 32),
                    _SizeBox(
                      label: 'MEDIUM',
                      count: counts[LockerSize.medium]!,
                      size: 180,
                      selected: _selected == LockerSize.medium,
                      onTap: () => _selectSize(
                          LockerSize.medium, counts[LockerSize.medium]!),
                    ),
                    const SizedBox(width: 32),
                    _SizeBox(
                      label: 'LARGE',
                      count: counts[LockerSize.large]!,
                      size: 230,
                      selected: _selected == LockerSize.large,
                      onTap: () => _selectSize(
                          LockerSize.large, counts[LockerSize.large]!),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KioskButton(
                    label: 'Cancel',
                    width: 220,
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
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

class _SizeBox extends StatelessWidget {
  const _SizeBox({
    required this.label,
    required this.count,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = count == 0;
    final outer = selected
        ? AppColors.boxSelectedOuter
        : unavailable
            ? AppColors.boxInactiveOuter
            : AppColors.boxDefaultOuter;
    final inner = selected
        ? AppColors.boxSelectedInner
        : unavailable
            ? AppColors.boxInactiveInner
            : AppColors.boxDefaultInner;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          color: outer,
          padding: const EdgeInsets.all(10),
          child: Container(
            color: inner,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.boxLabel),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.countBubble,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: AppTextStyles.boxCount.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
