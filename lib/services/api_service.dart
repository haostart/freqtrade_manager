import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService extends ChangeNotifier {
  String baseUrl;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
  ));

  ApiService({required this.baseUrl});

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    notifyListeners();
  }

  void updateToken(String token) {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/login'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );
      
      if (kDebugMode) {
        print('Login url: $baseUrl/token/login');
        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        // 设置token过期时间为15分钟后
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
        if (kDebugMode) {
          print('Got token: $_accessToken');
        }
      } else {
        throw Exception('登录失败: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      rethrow;
    }
  }

  Future<void> _refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh'),
        headers: {'Authorization': 'Bearer $_refreshToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
      } else {
        throw Exception('刷新token失败');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh error: $e');
      }
      rethrow;
    }
  }

  Future<void> placeOrder({
    required String pair,
    required String side,
    required double amount,
    required double price,
    String orderType = 'limit',
  }) async {
    await _authenticatedPost(
      '/forceenter',
      body: {
        'pair': pair,
        'side': side,
        'price': price.toString(),
        'amount': amount.toString(),
        'ordertype': orderType,
      },
    );
  }

  Future<http.Response> _authenticatedGet(String path) async {
    if (_accessToken == null) throw Exception('未登录');
    
    // 检查token是否即将过期（比如还有1分钟就过期）
    if (_tokenExpiry != null && 
        _tokenExpiry!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      await _refreshAccessToken();
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    // if (kDebugMode) {
    //   print('Response status: ${response.statusCode}');
    //   print('Response body: ${response.body}');
    // }
    return response;
  }

  Future<http.Response> _authenticatedPost(String path, {Map<String, dynamic>? body}) async {
    if (_accessToken == null) throw Exception('未登录');
    
    return await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> getAccountInfo() async {
    try {
      final response = await _authenticatedGet('/balance');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currencies = data['currencies'] as List;
        
        // 转换为更易用的Map格式
        final Map<String, dynamic> balanceMap = {};
        for (var item in currencies) {
          if (item is Map<String, dynamic>) {
            final currency = item['currency'] as String;
            balanceMap[currency] = {
              'free': item['free'],
              'used': item['used'],
              'total': item['balance'],
              'bot_owned': item['bot_owned'],
              'est_stake': item['est_stake'],
            };
          }
        }
        
        // 添加总计信息
        balanceMap['__summary__'] = {
          'total': data['total'],
          'total_bot': data['total_bot'],
          'total_value': data['value'],
          'total_bot_value': data['value_bot'],
          'stake_currency': data['stake'],
          'fiat_currency': data['symbol'],
          'starting_capital': data['starting_capital'],
          'starting_capital_fiat': data['starting_capital_fiat'],
          'profit_pct': data['starting_capital_pct'],
        };
        
        return balanceMap;
      } else {
        throw Exception('获取账户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getAccountInfo: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOpenTrades() async {
    try {
      final response = await _authenticatedGet('/status');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('获取交易状态失败: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOpenTrades: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getKLineData({
    required String pair,
    required String interval,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final response = await _dio.get(
          'https://api.binance.com/api/v3/klines',
          queryParameters: {
            'symbol': pair,
            'interval': interval,
            'limit': 200,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          return data.map((item) {
            return {
              'time': item[0],
              'open': item[1],
              'high': item[2],
              'low': item[3],
              'close': item[4],
              'volume': item[5],
            };
          }).toList();
        } else {
          throw Exception('获取K线数据失败: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('获取K线数据失败: $e (已重试$maxRetries次)');
        }
        // 等待一段时间后重试
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    throw Exception('获取K线数据失败: 达到最大重试次数');
  }

  Future<List<Map<String, dynamic>>> getTrades({int limit = 20}) async {
    final response = await _authenticatedGet('/trades');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['trades']);
    }
    throw Exception('获取交易记录失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getLogs({int limit = 50}) async {
    final response = await _authenticatedGet('/logs?limit=$limit');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('获取日志失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getProfit() async {
    final response = await _authenticatedGet('/profit');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('获取利润数据失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getDaily({int days = 7}) async {
    final response = await _authenticatedGet('/daily?days=$days');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('获取每日数据失败: ${response.statusCode}');
  }

  String? get token => _accessToken;
} 