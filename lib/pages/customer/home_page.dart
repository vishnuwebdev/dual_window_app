import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilities/app_version.dart';
import '../../widgets/kiosk/kiosk.dart';
import '../admin/admin_pin_gate_page.dart';
import 'collection_input_page.dart';
import 'help_page.dart';
import 'privacy_statement_page.dart';
import 'verify_pin_page.dart';

/// Customer/Admin window — Home ("Welcome") page.
///
/// Ported from `MainActivity` / `activity_main.xml`: the "Drop off" /
/// "Collect" buttons, the Help shortcut, and a locker-availability check
/// that disables "Drop off" when every compartment is occupied.
///
/// Shared by both physical windows, each restricted to one function: the
/// Customer window shows this with [dropOffEnabled] false (collect-only),
/// and the Admin window shows it with [collectEnabled] false (drop-off
/// only) — see `windows/customer_window.dart` / `windows/admin_window.dart`.
///
/// Also ports the "tap the VaultGroup logo 5 times to open Admin" easter
/// egg: tapping the VG badge (bottom-right) 5 times within
/// [_tapResetWindow] opens [AdminPinGatePage], the numeric-keypad PIN gate
/// checked against `config.json` (see `ConfigService.adminPin`) that leads
/// into the admin management flow — reachable from either window's copy of
/// this page.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.dropOffEnabled = true,
    this.collectEnabled = true,
  });

  /// Whether the "Drop off" button is offered on this window. Still
  /// further gated by locker availability when true (see [_handleDeliver]).
  final bool dropOffEnabled;

  /// Whether the "Collect" button is offered on this window.
  final bool collectEnabled;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _requiredTaps = 5;
  static const _tapResetWindow = Duration(seconds: 2);

  final _repo = MockKioskRepository.instance;
  int _badgeTapCount = 0;
  Timer? _badgeTapResetTimer;

  // Starts blank rather than a guessed placeholder — see `AppVersion`,
  // which reads the real value from `pubspec.yaml` — and fills in once
  // that (near-instant) asset read completes.
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    AppVersion.name().then((version) {
      if (!mounted) return;
      setState(() => _versionLabel = 'V$version');
    });
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _badgeTapResetTimer?.cancel();
    super.dispose();
  }

  // `MockKioskRepository.addItem` (called from `DeliverPlaceParcelPage`'s
  // `initState`) notifies listeners synchronously while that page's own
  // route is still being built — i.e. while this still-mounted HomePage's
  // ancestor `Builder` is mid-build. Calling `setState` straight from the
  // listener would hit "setState() or markNeedsBuild() called during
  // build", so defer the rebuild to just after the current frame instead.
  void _onRepoChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _handleBadgeTap() {
    _badgeTapCount++;
    _badgeTapResetTimer?.cancel();

    if (_badgeTapCount >= _requiredTaps) {
      _badgeTapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminPinGatePage()),
      );
      return;
    }

    _badgeTapResetTimer = Timer(_tapResetWindow, () => _badgeTapCount = 0);
  }

  void _handleDeliver() {
    if (!widget.dropOffEnabled || _repo.getFreeLockers().isEmpty) return;

    if (_repo.dropoffPinEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VerifyPinPage()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrivacyStatementPage()),
      );
    }
  }

  void _handleCollect() {
    if (!widget.collectEnabled) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CollectionInputPage()),
    );
  }

  void _handleHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFreeLockers = _repo.getFreeLockers().isNotEmpty;

    return KioskScaffold(
      waves: KioskWaves.left,
      showBadge: false,
      child: Stack(
        children: [
          Column(
            children: [
              const KioskHeader(),
              const SizedBox(height: 24),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Image.asset('assets/images/click_n_collect.png',
                        height: 120),
                  ),
                  // Matches `gifImageView` in `activity_main.xml`: the
                  // animated hint sits just beneath the button, pointing
                  // up at it, regardless of screen resolution.
                  const Positioned(
                    bottom: 10,
                    left: -8,
                    child: IgnorePointer(
                      child: Image(
                        image: AssetImage('assets/images/click.gif'),
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The "Drop off" button and its "tap to start" GIF are in
                  // their own local Stack, so the GIF is positioned
                  // *relative to the button itself* rather than to the
                  // whole screen. Anchoring it with screen-absolute
                  // coordinates (the previous approach) meant it drifted
                  // away from the button whenever the window was resized,
                  // since the button's own position shifts with the
                  // `Spacer()`-driven centering above/below it, but a
                  // fixed-coordinate `Positioned` doesn't. This way it
                  // tracks the button at every window size.
                  if (!widget.collectEnabled)
                    KioskButton(
                      label: 'Drop off',
                      onPressed: _handleDeliver,
                      enabled: widget.dropOffEnabled && hasFreeLockers,
                      width: 260,
                    ),
                  if (widget.collectEnabled) ...[
                    const SizedBox(width: 60),
                    KioskButton(
                      label: 'Collect',
                      onPressed: _handleCollect,
                      enabled: widget.collectEnabled,
                      width: 260,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (widget.dropOffEnabled && !hasFreeLockers)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'All of our lockers are currently occupied, please try again later.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(fontSize: 18),
                  ),
                ),
              const Spacer(),
            ],
          ),
          // Help + VG badge — bottom-right, opposite the waves image.
          // Tap the VG badge 5 times to open the Admin PIN gate.
          Positioned(
            right: 16,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  onTap: _handleHelp,
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/help.png', height: 44),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleBadgeTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/vg_square_blue.png',
                          width: 56, height: 56),
                      const SizedBox(height: 4),
                      Text(
                        _versionLabel,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          color: AppColors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
