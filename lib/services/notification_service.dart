import 'dart:async';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class NotificationService {
  static const platform = MethodChannel('trade_notification_service');
  final ApiService apiService;
  Timer? _updateTimer;

  NotificationService(this.apiService);

  Future<void> startTradeNotificationService() async {
    try {
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final trades = await apiService.getOpenTrades();
          if (trades.isNotEmpty) {
            final profit = trades[0]['profit_pct']?.toString() ?? '0.0';
            final profitAbs = trades[0]['profit_abs']?.toString() ?? '0.0';
            
            await platform.invokeMethod('startTradeService', {
              'profit': profit,
              'profitAbs': profitAbs,
            });
          }
        } catch (e) {
          print('更新交易通知失败: $e');
        }
      });
    } catch (e) {
      print('启动通知服务失败: $e');
    }
  }

  Future<void> stopTradeNotificationService() async {
    try {
      _updateTimer?.cancel();
      await platform.invokeMethod('stopTradeService');
    } catch (e) {
      print('停止通知服务失败: $e');
    }
  }
} 