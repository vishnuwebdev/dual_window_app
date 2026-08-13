import 'package:flutter_test/flutter_test.dart';

import 'package:cnc_dual_screen/windows/admin_window.dart';
import 'package:cnc_dual_screen/windows/customer_window.dart';

void main() {
  testWidgets('admin window shows drop-off flow only', (tester) async {
    await tester.pumpWidget(const AdminWindowApp());

    expect(find.text('Drop off'), findsOneWidget);
    expect(find.text('Collect'), findsNothing);
  });

  testWidgets('customer window shows collection flow only', (tester) async {
    await tester.pumpWidget(const CustomerWindowApp());

    expect(find.text('Collect'), findsOneWidget);
    expect(find.text('Drop off'), findsNothing);
  });
}
