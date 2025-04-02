import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class BinanceService {
  final String baseUrl = 'https://api.binance.com/api/v3';
  WebSocketChannel? _wsChannel;

  Future<List<Map<String, dynamic>>> getKlineData(
    String symbol,
    String interval,
    {int limit = 500}
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/klines?symbol=$symbol&interval=$interval&limit=$limit')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((kline) => {
          'time': kline[0],         // 开盘时间
          'open': double.parse(kline[1]),
          'high': double.parse(kline[2]),
          'low': double.parse(kline[3]),
          'close': double.parse(kline[4]),
          'volume': double.parse(kline[5]),
        }).toList();
      } else {
        print('获取K线数据失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('获取K线数据失败: $e');
      return [];
    }
  }

  void connectToKlineStream(String symbol, String interval, Function(Map<String, dynamic>) onData) {
    final wsUrl = Uri.parse('wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@kline_$interval');
    
    _wsChannel = WebSocketChannel.connect(wsUrl);
    _wsChannel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['e'] == 'kline') {
          final k = data['k'];
          onData({
            'time': k['t'],
            'open': double.parse(k['o']),
            'high': double.parse(k['h']),
            'low': double.parse(k['l']),
            'close': double.parse(k['c']),
            'volume': double.parse(k['v']),
          });
        }
      },
      onError: (error) => print('WebSocket错误: $error'),
      onDone: () => print('WebSocket连接关闭'),
    );
  }

  void dispose() {
    _wsChannel?.sink.close();
  }
} 