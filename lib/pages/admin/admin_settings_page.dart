import 'package:flutter/material.dart';

/// Admin window — Settings page.
///
/// Nothing desktop-specific here — it's a completely ordinary second route
/// pushed onto the Admin window's own `Navigator`. It's included to satisfy
/// (and demonstrate) the required Home -> Settings -> Back navigation flow.
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ListTile(
            leading: Icon(Icons.desktop_windows),
            title: Text('Window role'),
            subtitle: Text('Admin'),
          ),
          const ListTile(
            leading: Icon(Icons.cable),
            title: Text('Transport'),
            subtitle: Text('desktop_multi_window WindowMethodChannel'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
