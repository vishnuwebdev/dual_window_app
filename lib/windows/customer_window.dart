import 'package:flutter/material.dart';

import '../pages/customer/customer_welcome_page.dart';
import '../widgets/keyboard_host.dart';

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
      // Same reusable keyboard host as the Admin window — see its doc
      // comment in admin_window.dart. Nothing on this window uses
      // KeyboardTextField yet, but any page added here can opt in for
      // free, same as Admin's.
      builder: (context, child) => KeyboardHost(child: child ?? const SizedBox()),
    );
  }
}
