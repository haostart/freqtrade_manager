import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DailyProfit extends StatefulWidget {
  const DailyProfit({super.key});

  @override
  State<DailyProfit> createState() => DailyProfitState();
}

class DailyProfitState extends State<DailyProfit> {
  late Future<Map<String, dynamic>> _dailyData;
  bool autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _dailyData = _fetchDailyData();
  }

  @override  
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoRefresh(bool? value) {
    if (!mounted) return;
    setState(() {
      autoRefresh = value ?? false;
      _refreshTimer?.cancel();
      if (autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          refreshDailyData();
        });
      }
    });
  }

  Future<Map<String, dynamic>> _fetchDailyData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return await apiService.getDaily(days: 7); // 获取最近7天的数据
  }

  void refreshDailyData() {
    setState(() {
      _dailyData = _fetchDailyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.dailyProfit,
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dailyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.getDailyDataFailed(snapshot.error.toString())));
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noDailyData));
          }
          final dailyList = List<Map<String, dynamic>>.from(data['data']);
          return RefreshIndicator(
            onRefresh: () async {
              refreshDailyData();
            },
            child: ListView.builder(
              itemCount: dailyList.length,
              itemBuilder: (context, index) {
                final daily = dailyList[index];
                final date = daily['date'] as String;
                final profit = double.parse(daily['abs_profit'].toString());
                final profitRatio = double.parse(daily['rel_profit'].toString());
                final tradeCount = daily['trade_count'] as int;
                final fiatValue = double.parse(daily['fiat_value'].toString());
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // 左边显示日期和交易次数
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.tradeCount}: $tradeCount',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 中间显示收益率
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              '${(profitRatio * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        // 右边显示具体金额
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${profit.toStringAsFixed(2)} USDT',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profit >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              Text(
                                '${fiatValue.toStringAsFixed(2)} ${snapshot.data?['fiat_display_currency'] ?? 'USDT'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fiatValue >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 