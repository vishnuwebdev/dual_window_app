import 'dart:convert';

/// The message the Admin window sends to the Customer window.
///
/// This is a plain data model with no Flutter or IPC-specific imports —
/// business/data logic stays separate from the transport (see
/// `services/messaging_service.dart`) and from the UI (see `pages/`).
class CustomerMessage {
  const CustomerMessage({required this.text, required this.sentAt});

  final String text;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory CustomerMessage.fromJson(Map<String, dynamic> json) {
    return CustomerMessage(
      text: json['text'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String encode() => jsonEncode(toJson());

  static CustomerMessage decode(String raw) =>
      CustomerMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
