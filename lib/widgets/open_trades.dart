import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'dart:async'; // 导入 Timer 所需的库
import 'custom_app_bar.dart'; // 导入 CustomAppBar
import 'package:flutter/services.dart'; // 导入 SystemChrome 所需的库
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class OpenTrades extends StatefulWidget {
  const OpenTrades({super.key});

  @override
  State<OpenTrades> createState() => OpenTradesState();
}

class OpenTradesState extends State<OpenTrades> {
  late Future<List<Map<String, dynamic>>> _futureTrades;
  bool autoRefresh = false;
  Timer? _refreshTimer;
  bool _isIOS = false; // 添加一个字段来存储是否为 iOS
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late Timer _statusBarUpdateTimer;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _requestNotificationPermissions();
    _futureTrades = _fetchOpenTrades();
    
    _statusBarUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateStatusBar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里检查平台
    _isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (_isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // 允许状态栏显示内容
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOpenTrades() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return await apiService.getOpenTrades();
  }

  void refreshTrades() {
    setState(() {
      _futureTrades = _fetchOpenTrades();
    });
  }

  void _toggleAutoRefresh(bool? value) {
    if (!mounted) return;
    setState(() {
      autoRefresh = value ?? false;
      _refreshTimer?.cancel();
      if (autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          refreshTrades();
        });
      }
    });
  }

  void _updateStatusBar() {
    _futureTrades.then((trades) {
      if (trades.isNotEmpty) {
        final profit = (trades[0]['profit_pct'] ?? 0.0).toStringAsFixed(2);
        final profitAbs = (trades[0]['profit_abs'] ?? 0.0).toStringAsFixed(2);
        
        if (Platform.isAndroid) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'trade_status',
            'Trade Status',
            channelDescription: 'Shows current trade status',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
          );
          
          _flutterLocalNotificationsPlugin.show(
            1,
            '当前交易收益率: $profit%',
            '收益金额: $profitAbs USDT',
            NotificationDetails(android: androidPlatformChannelSpecifics),
          );
        }
      }
    }).catchError((error) {
      print('获取当前交易失败: $error');
    });
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _statusBarUpdateTimer.cancel();
    super.dispose();
  }

  Widget _buildTradeCard(Map<String, dynamic> trade) {
    final profit = (trade['profit_pct'] ?? 0.0).toStringAsFixed(2);
    final profitColor = (trade['profit_pct'] ?? 0.0) >= 0 ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trade['pair']} (${trade['trading_mode']})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '开仓时间: ${trade['open_date']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$profit%',
              style: TextStyle(
                color: profitColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('交易ID', trade['trade_id'].toString()),
                _buildInfoRow('方向', trade['is_short'] ? '做空' : '做多'),
                _buildInfoRow('杠杆', '${trade['leverage']}x'),
                _buildInfoRow('数量', trade['amount'].toString()),
                _buildInfoRow('开仓价格', trade['open_rate'].toString()),
                _buildInfoRow('当前价格', trade['current_rate'].toString()),
                _buildInfoRow('止损价格', trade['stop_loss_abs'].toString()),
                _buildInfoRow('清算价格', trade['liquidation_price'].toString()),
                _buildInfoRow('策略', trade['strategy']),
                _buildInfoRow('进场标签', trade['enter_tag']),
                
                const Divider(),
                const Text('订单历史:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._buildOrdersList(trade['orders']),
                
                const Divider(),
                _buildInfoRow('收益金额', '${trade['profit_abs']} USDT'),
                _buildInfoRow('资金费率', '${trade['funding_fees']} USDT'),
                _buildInfoRow('总收益', '${trade['total_profit_abs']} USDT'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  List<Widget> _buildOrdersList(List<dynamic> orders) {
    return orders.map<Widget>((order) {
      final status = order['status'];
      final statusColor = status == 'closed' ? Colors.green : Colors.blue;
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('订单ID: ${order['order_id']}'),
                  Text(
                    status,
                    style: TextStyle(color: statusColor),
                  ),
                ],
              ),
              Text('类型: ${order['order_type']}'),
              Text('方向: ${order['ft_order_side']}'),
              Text('数量: ${order['amount']}'),
              Text('价格: ${order['safe_price']}'),
              if (order['ft_order_tag'] != null)
                Text('标签: ${order['ft_order_tag']}'),
              Text('时间: ${order['order_timestamp']}'),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _updateStatusBar(); // 在构建时更新状态栏
    return Scaffold(
      appBar: CustomAppBar(
        title: '当前交易',
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTrades,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('获取当前交易失败: ${snapshot.error}'));
          }

          final trades = snapshot.data;
          if (trades == null || trades.isEmpty) {
            return const Center(child: Text('无当前交易'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshTrades();
            },
            child: ListView.builder(
              itemCount: trades.length,
              itemBuilder: (context, index) => _buildTradeCard(trades[index]),
            ),
          );
        },
      ),
    );
  }
}
