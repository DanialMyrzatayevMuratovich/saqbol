import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'voice_models.dart';

class CallSocket {
  CallSocket(this._wsBaseUrl);

  final String _wsBaseUrl;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  void connect({
    required String token,
    required void Function(CallAlert alert) onAlert,
    required void Function() onClosed,
  }) {
    final uri = Uri.parse('$_wsBaseUrl/ws/call?token=$token');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    _subscription = channel.stream.listen(
      (event) {
        final decoded = jsonDecode(event as String) as Map<String, dynamic>;
        onAlert(CallAlert.fromJson(decoded));
      },
      onDone: onClosed,
      onError: (_) => onClosed(),
      cancelOnError: true,
    );
  }

  void sendFragment(String text) {
    final channel = _channel;
    if (channel == null || text.trim().isEmpty) return;
    channel.sink.add(jsonEncode({'text': text}));
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }
}
