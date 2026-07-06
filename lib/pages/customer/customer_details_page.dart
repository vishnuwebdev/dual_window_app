import 'package:flutter/material.dart';

import '../../services/messaging_service.dart';

/// Customer window — Details page.
///
/// Second route on the Customer window's own `Navigator`, completely
/// independent of the Admin window's navigation stack (see the doc comment
/// in `windows/customer_window.dart`). Shows when the last message arrived,
/// to make the "own Navigator, own state" separation tangible: navigating
/// here never touches, and is never touched by, anything happening in the
/// Admin window.
class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final message = MessagingService.instance.latestMessage;
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last message', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message?.text ?? 'No message received yet.'),
            const SizedBox(height: 16),
            Text('Received at', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message?.sentAt.toLocal().toString() ?? '—'),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
