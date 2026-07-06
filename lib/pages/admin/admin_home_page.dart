import 'package:flutter/material.dart';

import '../../services/messaging_service.dart';
import '../../services/window_service.dart';
import 'admin_settings_page.dart';

/// Admin window — Home page.
///
/// Navigation demo: Home -> Settings -> Back, using this window's own
/// `Navigator` (see `AdminWindowApp`). Business logic (sending messages,
/// opening the Customer window) is delegated to `MessagingService` and
/// `WindowService` — this widget only wires UI events to those calls and
/// rebuilds when `MessagingService` notifies it of a status change.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await MessagingService.instance.sendToCustomer(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // Standard Navigator.push — scoped to this window only.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Message for customer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. "Order #482 is ready for pickup"',
              ),
              onSubmitted: (_) => _handleSend(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _handleSend,
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Customer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    // Optional, for testing: manually (re)open the Customer
                    // window. Useful if it was closed, or to demonstrate
                    // that WindowService.openOrCreateCustomerWindow() is
                    // idempotent (won't spawn a duplicate window).
                    onPressed: WindowService.openOrCreateCustomerWindow,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Customer Window'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // ListenableBuilder rebuilds only this subtree whenever
            // MessagingService calls notifyListeners() — e.g. after the
            // Customer window acknowledges receipt over the method channel.
            ListenableBuilder(
              listenable: MessagingService.instance,
              builder: (context, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(child: Text(MessagingService.instance.status)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
