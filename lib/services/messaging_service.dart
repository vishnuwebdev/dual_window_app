import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/customer_message.dart';

/// The channel name shared by the Admin and Customer windows.
///
/// DESKTOP CONCEPT — why no `windowId` anywhere in this file:
/// `WindowMethodChannel` supports two modes. We use the default,
/// `ChannelMode.bidirectional`: the *first two* engines that register a
/// channel with this exact name become a pair, and from then on messages
/// sent on that channel are automatically routed to the partner — neither
/// side has to know the other's window id. Since this POC only ever has
/// one Admin engine and one Customer engine, that's exactly the topology
/// we want. (If you later needed one Admin talking to *several* Customer
/// windows, you'd switch to `ChannelMode.unidirectional` and address
/// windows explicitly via `WindowController.fromWindowId`.)
const String kAdminCustomerChannel = 'admin_customer_channel';

const String _methodUpdateMessage = 'updateMessage';
const String _methodAck = 'messageAck';

/// All inter-window communication logic lives here, and nowhere else.
///
/// Why a dedicated service instead of calling `WindowMethodChannel`
/// straight from a widget's `onPressed`? Two reasons that matter as this
/// POC grows into a real app:
///  1. The message *shape* (JSON encoding, method names) is defined once,
///     in one place, instead of being duplicated at every call site.
///  2. If the transport ever changes — e.g. talking to a *second physical
///     Raspberry Pi* over the network instead of a second window on the
///     same machine — only this file changes. No widget code is touched.
///
/// IMPORTANT DESKTOP GOTCHA: this is a plain singleton (`instance`), which
/// works fine *within* one window, but do not expect `MessagingService`
/// state to be magically shared between the Admin and Customer windows the
/// way a `ChangeNotifierProvider` might be shared between screens in a
/// single-window mobile app. Each window is a separate engine/isolate with
/// its own copy of every static field. The *only* thing that actually
/// crosses the window boundary is what you explicitly send over the
/// `WindowMethodChannel` below.
class MessagingService extends ChangeNotifier {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final _channel = const WindowMethodChannel(kAdminCustomerChannel);

  bool _listening = false;

  CustomerMessage? _latestMessage;
  CustomerMessage? get latestMessage => _latestMessage;

  String _status = 'Idle';
  String get status => _status;

  /// Call once, from the Customer window's `main()`, before `runApp`.
  /// Registers this engine as the handler for `updateMessage` calls that
  /// arrive from the Admin window.
  void startListeningAsCustomer() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _methodUpdateMessage:
          final message = CustomerMessage.decode(call.arguments as String);
          _latestMessage = message;
          _status = 'Message received';
          notifyListeners();

          // Call back into the Admin window. This is the *bidirectional*
          // half of the channel in action: the Customer window is now the
          // one invoking a method, and Admin's handler (below) receives it.
          unawaited(_channel.invokeMethod(
            _methodAck,
            '{"text":"${message.text.replaceAll('"', '\\"')}"}',
          ));
          return null;
        default:
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });
  }

  /// Call once, from the Admin window's `main()`, before `runApp`.
  /// Registers this engine as the handler for the Customer window's
  /// `messageAck` replies, so the Admin UI can show delivery status.
  void startListeningAsAdmin() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _methodAck:
          _status = 'Delivered and displayed on Customer window';
          notifyListeners();
          return null;
        default:
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });
  }

  /// Sends [text] to the Customer window. Called from the Admin UI's
  /// "Send to Customer" button.
  Future<void> sendToCustomer(String text) async {
    final message = CustomerMessage(text: text, sentAt: DateTime.now());
    _status = 'Sending...';
    notifyListeners();
    try {
      await _channel.invokeMethod(_methodUpdateMessage, message.encode());
    } on MissingPluginException {
      // Happens if the Customer window hasn't finished registering its
      // handler yet (a brief window right after app launch), or if it was
      // closed. Surface it in the status bar instead of throwing past the
      // button's onPressed.
      _status = 'Customer window is not ready. Try again.';
      notifyListeners();
    }
  }
}
