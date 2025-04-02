import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'dart:async'; // 导入 Timer 所需的库
import 'custom_app_bar.dart'; // 导入 CustomAppBar
import 'package:flutter/services.dart'; // 导入 SystemChrome 所需的库
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            AppLocalizations.of(context)!.currentTradeProfit(profit),
            AppLocalizations.of(context)!.profitAmount(profitAbs),
            NotificationDetails(android: androidPlatformChannelSpecifics),
          );
        }
      }
    }).catchError((error) {
      print(AppLocalizations.of(context)!.getCurrentTradeFailed(error));
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
                    '${AppLocalizations.of(context)!.openTime}: ${trade['open_date']}',
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
                _buildInfoRow(AppLocalizations.of(context)!.tradeId, trade['trade_id'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.direction, trade['is_short'] ? AppLocalizations.of(context)!.short : AppLocalizations.of(context)!.long),
                _buildInfoRow(AppLocalizations.of(context)!.leverage, '${trade['leverage']}x'),
                _buildInfoRow(AppLocalizations.of(context)!.amount, trade['amount'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.openPrice, trade['open_rate'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.currentPrice, trade['current_rate'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.stopLoss, trade['stop_loss_abs'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.liquidationPrice, trade['liquidation_price'].toString()),
                _buildInfoRow(AppLocalizations.of(context)!.strategy, trade['strategy']),
                _buildInfoRow(AppLocalizations.of(context)!.enterTag, trade['enter_tag']),
                
                const Divider(),
                Text(AppLocalizations.of(context)!.orderHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
                ..._buildOrdersList(trade['orders']),
                
                const Divider(),
                _buildInfoRow(AppLocalizations.of(context)!.profit, '${trade['profit_abs']} USDT'),
                _buildInfoRow(AppLocalizations.of(context)!.fundingFees, '${trade['funding_fees']} USDT'),
                _buildInfoRow(AppLocalizations.of(context)!.totalProfit, '${trade['total_profit_abs']} USDT'),
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
                  Text('${AppLocalizations.of(context)!.orderId}: ${order['order_id']}'),
                  Text(
                    status,
                    style: TextStyle(color: statusColor),
                  ),
                ],
              ),
              Text('${AppLocalizations.of(context)!.type}: ${order['order_type']}'),
              Text('${AppLocalizations.of(context)!.direction}: ${order['ft_order_side']}'),
              Text('${AppLocalizations.of(context)!.amount}: ${order['amount']}'),
              Text('${AppLocalizations.of(context)!.price}: ${order['safe_price']}'),
              if (order['ft_order_tag'] != null)
                Text('${AppLocalizations.of(context)!.tag}: ${order['ft_order_tag']}'),
              Text('${AppLocalizations.of(context)!.time}: ${order['order_timestamp']}'),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _updateStatusBar();
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.openTrades,
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshTrades,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTrades,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.error));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noData));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => _buildTradeCard(snapshot.data![index]),
          );
        },
      ),
    );
  }
}
