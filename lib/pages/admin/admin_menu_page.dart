import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'admin_dropoff_pin_page.dart';
import 'admin_reset_page.dart';
import 'admin_sms_template_page.dart';
import 'configuration_page.dart';
import 'locker_management_page.dart';
import 'unit_registration_page.dart';

/// Admin menu — shown after a correct PIN on [AdminPinGatePage]. The admin
/// section's landing screen: every other admin screen's inactivity timeout
/// (see `kAdminInactivityTimeout`) pops back to here.
///
/// Laid out as a fixed 3-column grid of icon tiles (2026-07-25 redesign —
/// was a `Wrap` of plain `KioskButton` pills, which on a wide kiosk display
/// could wrap to 4+ per row depending on available width instead of a
/// consistent 3, and read as a flat list of six identical buttons with no
/// visual hierarchy). "Home" is deliberately *not* one of the grid tiles —
/// it's an exit action, not a feature entry point (the six tiles are, per
/// this page's job of "showing all the entry points for the admin section
/// feature screens") — so it's a separate, smaller button below the grid,
/// same bottom-of-screen convention every other admin page uses for
/// Cancel/Back.
class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage>
    with InactivityTimerMixin {
  // Longer than the 30s kiosk default — see kAdminInactivityTimeout's doc
  // comment. This is the admin landing screen itself, so timing out here
  // pops all the way back to Home, same as before, just after 5 minutes
  // idle instead of 30 seconds.
  @override
  Duration get inactivityTimeout => kAdminInactivityTimeout;

  @override
  void initState() {
    super.initState();
    startInactivityTimer();
  }

  @override
  void onInactivityTimeout() => Navigator.of(context).pop();

  void _push(Widget page) {
    stopInactivityTimer();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => startInactivityTimer());
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithActivityDetector(
      KioskScaffold(
        waves: KioskWaves.right,
        child: Column(
          children: [
            const KioskHeader(),
            Expanded(
              child: Center(
                child: SizedBox(
                  // 3 tiles * 224 + 2 gaps * 24 — fixed width (not
                  // screen-relative) is what guarantees exactly 3 per row
                  // regardless of how wide the kiosk display is, unlike the
                  // `Wrap` this replaced.
                  width: 720,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 224 / 176,
                    children: [
                      _AdminEntryTile(
                        icon: Icons.meeting_room_outlined,
                        label: 'Locker\nManagement',
                        onTap: () => _push(const LockerManagementPage()),
                      ),
                      _AdminEntryTile(
                        icon: Icons.password_outlined,
                        label: 'Change\nPassword',
                        onTap: () => _push(const AdminResetPage()),
                      ),
                      _AdminEntryTile(
                        icon: Icons.sms_outlined,
                        label: 'Change SMS\nTemplate',
                        onTap: () => _push(const AdminSmsTemplatePage()),
                      ),
                      _AdminEntryTile(
                        icon: Icons.pin_outlined,
                        label: 'Change\nDropoff Pin',
                        onTap: () => _push(const AdminDropoffPinPage()),
                      ),
                      _AdminEntryTile(
                        icon: Icons.settings_outlined,
                        label: 'Configuration',
                        onTap: () => _push(const ConfigurationPage()),
                      ),
                      _AdminEntryTile(
                        icon: Icons.cloud_sync_outlined,
                        label: 'Unit\nRegistration',
                        onTap: () => _push(const UnitRegistrationPage()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: KioskButton(
                label: 'Home',
                width: 220,
                height: 72,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One admin-menu grid tile: a white rounded card with a filled teal icon
/// badge and a label underneath — reads as a small dashboard shortcut
/// rather than another flat pill button, giving the six entry points some
/// visual identity from each other. Wrapped in [BouncyTap] for the same
/// spring-press feedback `NumericKeypad` uses — cheap for 6 tiles, same
/// reasoning as that widget's doc comment.
class _AdminEntryTile extends StatelessWidget {
  const _AdminEntryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Kept deliberately subtle — a soft lift off the navy background
          // rather than a heavy floating-card drop shadow.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.buttonLabel.copyWith(
                color: AppColors.navy,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
