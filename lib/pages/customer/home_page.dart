import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/config_service.dart';
import '../../core/grpc/locker_grpc_service.dart';
import '../../core/mock/mock_kiosk_repository.dart';
import '../../core/registration/audit_codes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilities/app_version.dart';
import '../../core/utilities/logging.dart';
import '../../widgets/kiosk/kiosk.dart';
import '../admin/admin_pin_gate_page.dart';
import 'deliver_input_page.dart';
import 'help_page.dart';
import 'privacy_statement_page.dart';
import 'verify_pin_page.dart';

/// Customer/Admin window — Home ("Welcome") page.
///
/// Ported from `MainActivity` / `activity_main.xml`: the "Drop off" /
/// "Collect" buttons, the Help shortcut, and a locker-availability check
/// that disables "Drop off" when every compartment is occupied.
///
/// Both buttons are also disabled whenever
/// `MockKioskRepository.slaveBoardConnected` is false — a background poll
/// (`MockKioskRepository._pollSlaveBoardOnce`, every 15s while
/// `ConfigService.isGrpcBackend`) asking the unit's `get_slave_firmware`
/// RPC whether any slave board is actually responding right now. Neither
/// journey has anywhere to physically open a locker without one, even if
/// `cvmain` itself answers. This is a 2026-07-30 addition; always `true`
/// (no gating) in `'mock'` mode, where there's no hardware to check.
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

  // Last-logged enabled state of each button — `null` until the first
  // check, so that check (run once from `initState`) always logs the
  // starting state rather than only later transitions. Compared against on
  // every repo change (see `_logButtonStateChangesIfAny`) so a log line is
  // only emitted when a button's *actual* enabled state flips, not on
  // every unrelated repo notification (e.g. a parcel being dropped off
  // elsewhere shouldn't produce a Collect-button log line here).
  bool? _lastDropOffButtonEnabled;
  bool? _lastCollectButtonEnabled;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _logButtonStateChangesIfAny();
    AppVersion.name().then((version) {
      if (!mounted) return;
      setState(() => _versionLabel = 'V$version');
    });
  }

  /// Logs a line whenever the Drop off/Collect button's *actual* enabled
  /// state (the same AND of conditions used in `build()`'s `enabled:` and
  /// `_handleDeliver`/`_handleCollect`'s early-return checks) differs from
  /// what was last logged — includes the slave-board reason specifically
  /// when that's what's driving a `disabled` result, since that's the
  /// condition this was added to make traceable (2026-07-30). Only checks
  /// whichever button this window actually offers (mirrors the `if
  /// (!widget.collectEnabled)`/`if (widget.collectEnabled)` split in
  /// `build()` — see the class doc comment for why each window only shows
  /// one of the two).
  ///
  /// A transition to `disabled` specifically *because* the slave board
  /// isn't connected is also escalated to Rapid7 via
  /// `LockerGrpcService.userAudit` — see [_reportSlaveBoardDisabled]'s doc
  /// comment for why only that direction (never the "re-enabled" recovery)
  /// gets sent there.
  void _logButtonStateChangesIfAny() {
    if (!widget.collectEnabled) {
      final enabled = widget.dropOffEnabled &&
          _repo.getFreeLockers().isNotEmpty &&
          _repo.slaveBoardConnected;
      if (enabled != _lastDropOffButtonEnabled) {
        logger.i('HomePage: Drop off button ${enabled ? "enabled" : "disabled"}'
            '${_repo.slaveBoardConnected ? "" : " — slave board not connected"}');
        _lastDropOffButtonEnabled = enabled;
        if (!enabled && !_repo.slaveBoardConnected) {
          _reportSlaveBoardDisabled(
            code: AuditCodes.dropoffUnlockingFailure,
            description: 'Dropoff: unavailable — Drop off button disabled, '
                'slave board not connected',
          );
        }
      }
    }
    if (widget.collectEnabled) {
      final enabled = widget.collectEnabled && _repo.slaveBoardConnected;
      if (enabled != _lastCollectButtonEnabled) {
        logger.i('HomePage: Collect button ${enabled ? "enabled" : "disabled"}'
            '${_repo.slaveBoardConnected ? "" : " — slave board not connected"}');
        _lastCollectButtonEnabled = enabled;
        if (!enabled && !_repo.slaveBoardConnected) {
          _reportSlaveBoardDisabled(
            code: AuditCodes.pickupUnlockingFailure,
            description: 'Pickup: unavailable — Collect button disabled, '
                'slave board not connected',
          );
        }
      }
    }
  }

  /// Sends a `userAudit` event to Rapid7 for a button just having been
  /// disabled because the slave board isn't connected — deliberately only
  /// called for that one direction, never for the matching "re-enabled"
  /// recovery: there's no existing `AuditCodes` value that means "hardware
  /// is available again" without borrowing a *success* code like
  /// `dropoffSuccess`/`pickupSuccess`, which specifically mean "a real
  /// drop-off/pickup transaction just completed" — reusing either of those
  /// here would misrepresent a button becoming enabled as an actual
  /// customer transaction on the dashboard. [code] has no dedicated real
  /// code for "hardware unavailable" in VaultGroup's `LogConstants.kt`
  /// (see `AuditCodes`'s class doc comment) — `dropoffUnlockingFailure`/
  /// `pickupUnlockingFailure` are used as the closest existing stand-ins
  /// (both already mean "couldn't unlock," which is exactly why the button
  /// is being disabled pre-emptively) until a dedicated code is confirmed.
  /// No-ops outside `'grpc'` mode — nothing to report to in `'mock'` mode,
  /// where there's no unit to relay this to Rapid7 through anyway.
  void _reportSlaveBoardDisabled({required int code, required String description}) {
    if (!ConfigService().isGrpcBackend) return;
    unawaited(LockerGrpcService.instance.userAudit(
      code: code,
      priority: AuditLogPriority.normal,
      level: AuditLogLevel.warning,
      description: description,
    ));
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
      if (!mounted) return;
      _logButtonStateChangesIfAny();
      setState(() {});
    });
  }

  void _handleBadgeTap() {
    if (widget.collectEnabled) return;
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
    if (!widget.dropOffEnabled ||
        _repo.getFreeLockers().isEmpty ||
        !_repo.slaveBoardConnected) {
      return;
    }

    if (_repo.dropoffPinEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VerifyPinPage()),
      );
    } else {
      // Straight to phone-number entry — no Privacy Statement or
      // Disclaimer screen in between (removed 2026-07-25; see git history
      // for the old `PrivacyStatementPage`/`DeliverDisclaimerPage` if this
      // ever needs to come back).
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DeliverInputPage()),
      );
    }
  }

  void _handleCollect() {
    if (!widget.collectEnabled || !_repo.slaveBoardConnected) return;

    // Collection has no PIN-gate equivalent to `dropoffPinEnabled` (see
    // `_handleDeliver`) — every collection goes through the POPIA privacy
    // consent screen first, with no disclaimer screen after it (unlike the
    // old drop-off flow, which had both and has since had both removed).
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyStatementPage()),
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
                        height: 200),
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
                      enabled: widget.dropOffEnabled &&
                          hasFreeLockers &&
                          _repo.slaveBoardConnected,
                      textStyle: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      width: 400,
                      height: 150,
                    ),
                  if (widget.collectEnabled) ...[
                    const SizedBox(width: 60),
                    KioskButton(
                      label: 'Collect',
                      onPressed: _handleCollect,
                      enabled: widget.collectEnabled && _repo.slaveBoardConnected,
                      textStyle: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      width: 400,
                      height: 150,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Hardware-connectivity takes priority over the "no free
              // lockers" message below — if the unit's slave board isn't
              // even responding, telling the customer "occupied" would be
              // misleading (`_repo.getFreeLockers()` reflects the last
              // known/cached inventory, not live hardware state, so it can
              // still report free lockers even while the board is down).
              if (!_repo.slaveBoardConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'This locker is temporarily unavailable, please try again shortly.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(fontSize: 18),
                  ),
                )
              else if (widget.dropOffEnabled && !hasFreeLockers)
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
                  child: Image.asset('assets/images/help.png', height: 60),
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
