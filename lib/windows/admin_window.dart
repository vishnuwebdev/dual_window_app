import 'package:flutter/material.dart';

import '../pages/admin/admin_home_page.dart';

/// The root widget for the Admin window's engine.
///
/// DESKTOP CONCEPT: this `MaterialApp` — and the `Navigator` it creates
/// internally — belongs *only* to this window's Flutter engine. The
/// Customer window (see `customer_window.dart`) builds a completely
/// separate `MaterialApp`/`Navigator` in a completely separate engine.
/// Pushing a route here has no way to affect, or even see, the Customer
/// window's navigation stack — they are as independent as two different
/// apps running on the same computer. That independence is "free" (you get
/// it just by each window running its own `main()`); you don't need to do
/// anything special to isolate them.
class AdminWindowApp extends StatelessWidget {
  const AdminWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Console',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AdminHomePage(),
    );
  }
}
