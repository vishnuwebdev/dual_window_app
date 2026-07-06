import 'package:flutter/material.dart';

import '../../services/messaging_service.dart';
import 'customer_details_page.dart';

/// Customer window — Welcome page.
///
/// Shows the large centered message, defaulting to "Waiting for
/// message...", and updates live whenever `MessagingService` receives a new
/// message from the Admin window over the method channel — no polling, no
/// manual refresh.
class CustomerWelcomePage extends StatelessWidget {
  const CustomerWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Display')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListenableBuilder(
                listenable: MessagingService.instance,
                builder: (context, _) {
                  final message = MessagingService.instance.latestMessage;
                  return Text(
                    message?.text ?? 'Waiting for message...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerDetailsPage()),
                ),
                icon: const Icon(Icons.info_outline),
                label: const Text('View Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
