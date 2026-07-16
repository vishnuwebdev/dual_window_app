import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../widgets/kiosk/kiosk.dart';
import 'admin_dropoff_pin_page.dart';
import 'admin_reset_page.dart';
import 'admin_sms_template_page.dart';
import 'configuration_page.dart';
import 'locker_management_page.dart';
import 'unit_registration_page.dart';

/// Admin menu — shown after a correct PIN on [AdminPinGatePage]. Ported
/// from the Android app's post-login admin menu: Cancel / Locker
/// Management / Change Password / Change Sms template / Change Dropoff
/// Pin.
class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage>
    with InactivityTimerMixin {
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    KioskButton(
                      label: 'Home',
                      width: 220,
                      height: 78,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    KioskButton(
                      label: 'Locker Management',
                      width: 220,
                      height: 78,
                      onPressed: () => _push(const LockerManagementPage()),
                    ),
                    KioskButton(
                      label: 'Change\nPassword',
                      width: 220,
                      height: 78,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                      onPressed: () => _push(const AdminResetPage()),
                    ),
                    KioskButton(
                      label: 'Change Sms\ntemplate',
                      width: 220,
                      height: 78,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                      onPressed: () => _push(const AdminSmsTemplatePage()),
                    ),
                    KioskButton(
                      label: 'Change\nDropoff Pin',
                      width: 220,
                      height: 78,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                      onPressed: () => _push(const AdminDropoffPinPage()),
                    ),
                    KioskButton(
                      label: 'Configuration',
                      width: 220,
                      height: 78,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                      onPressed: () => _push(const ConfigurationPage()),
                    ),
                    KioskButton(
                      label: 'Unit\nRegistration',
                      width: 220,
                      height: 78,
                      textStyle:
                          AppTextStyles.buttonLabel.copyWith(fontSize: 20),
                      onPressed: () => _push(const UnitRegistrationPage()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
