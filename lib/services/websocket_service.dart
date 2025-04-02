import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String wsUrl;
  final String wsToken;
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;

  WebSocketService({
    required this.wsUrl,
    required this.wsToken,
  });

  void connect() {
    final uri = Uri.parse('$wsUrl?token=$wsToken');
    _channel = WebSocketChannel.connect(uri);
    
    _channel?.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (onMessage != null) {
          onMessage!(data);
        }
      },
      onError: (error) {
        print('WebSocket错误: $error');
        reconnect();
      },
      onDone: () {
        print('WebSocket连接关闭');
        reconnect();
      },
    );

    // 订阅数据
    _subscribe(['analyzed_df', 'whitelist']);
  }

  void _subscribe(List<String> channels) {
    final message = {
      'type': 'subscribe',
      'data': channels,
    };
    _channel?.sink.add(jsonEncode(message));
  }

  void reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  void dispose() {
    _channel?.sink.close();
  }
} 