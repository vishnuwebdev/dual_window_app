import 'package:flutter/material.dart';

import '../pages/customer/customer_welcome_page.dart';

/// The root widget for the Customer window's engine — its own `MaterialApp`
/// and `Navigator`, entirely separate from the Admin window's. See the
/// matching doc comment in `admin_window.dart` for why that separation
/// requires no extra plumbing on our part.
class CustomerWindowApp extends StatelessWidget {
  const CustomerWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Display',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const CustomerWelcomePage(),
    );
  }
}
