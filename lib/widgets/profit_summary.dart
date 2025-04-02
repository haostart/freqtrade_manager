import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'custom_app_bar.dart';
import 'dart:async';

class ProfitSummary extends StatefulWidget {
  const ProfitSummary({super.key});

  @override
  State<ProfitSummary> createState() => ProfitSummaryState();
}

class ProfitSummaryState extends State<ProfitSummary> {
  late Future<Map<String, dynamic>> _profitData;
  bool autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _profitData = _fetchProfitData();
  }

  Future<Map<String, dynamic>> _fetchProfitData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return await apiService.getProfit();
  }

  Future<void> refreshProfitData() async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getProfit();
      if (!mounted) return;
      setState(() {
        _profitData = Future.value(data);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败: $e')),
      );
    }
  }

  void _toggleAutoRefresh(bool? value) {
    if (!mounted) return;
    setState(() {
      autoRefresh = value ?? false;
      _refreshTimer?.cancel();
      if (autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          refreshProfitData();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '利润总结',
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profitData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('获取利润数据失败: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('无利润数据'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshProfitData();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection('收益统计', [
                  _buildProfitCard('总收益额', '${data['profit_closed_coin'].toStringAsFixed(2)} USDT', data['profit_closed_coin'] > 0),
                  _buildProfitCard('总收益率', '${(data['profit_closed_ratio'] * 100).toStringAsFixed(2)}%', data['profit_closed_ratio'] > 0),
                  _buildProfitCard('法币收益', '${data['profit_closed_fiat'].toStringAsFixed(2)}', data['profit_closed_fiat'] > 0),
                  _buildProfitCard('平均收益率', '${(data['profit_closed_ratio_mean'] * 100).toStringAsFixed(2)}%', data['profit_closed_ratio_mean'] > 0),
                  _buildProfitCard('累计收益率', '${(data['profit_closed_ratio_sum'] * 100).toStringAsFixed(2)}%', data['profit_closed_ratio_sum'] > 0),
                ]),
                _buildSection('交易统计', [
                  _buildProfitCard('总交易次数', '${data['trade_count']}', true),
                  _buildProfitCard('已平仓交易', '${data['closed_trade_count']}', true),
                  _buildProfitCard('盈利交易', '${data['winning_trades']}', true),
                  _buildProfitCard('亏损交易', '${data['losing_trades']}', true),
                  _buildProfitCard('胜率', '${(data['winrate'] * 100).toStringAsFixed(2)}%', true),
                  _buildProfitCard('收益因子', data['profit_factor'].toStringAsFixed(2), true),
                  _buildProfitCard('期望值', data['expectancy'].toStringAsFixed(4), data['expectancy'] > 0),
                  _buildProfitCard('期望比率', data['expectancy_ratio'].toStringAsFixed(4), data['expectancy_ratio'] > 0),
                ]),
                _buildSection('最大回撤', [
                  _buildProfitCard('最大回撤率', '${(data['max_drawdown'] * 100).toStringAsFixed(2)}%', false),
                  _buildProfitCard('最大回撤额', '${data['max_drawdown_abs'].toStringAsFixed(2)} USDT', false),
                  _buildProfitCard('回撤开始', data['max_drawdown_start'], true),
                  _buildProfitCard('回撤结束', data['max_drawdown_end'], true),
                ]),
                _buildSection('交易记录', [
                  _buildProfitCard('交易量', '${data['trading_volume'].toStringAsFixed(2)} USDT', true),
                  _buildProfitCard('平均持仓时间', data['avg_duration'], true),
                  _buildProfitCard('最佳交易对', data['best_pair'], true),
                  _buildProfitCard('最佳收益率', '${(data['best_rate']).toStringAsFixed(2)}%', true),
                  _buildProfitCard('首次交易', data['first_trade_humanized'], true),
                  _buildProfitCard('最近交易', data['latest_trade_humanized'], true),
                  _buildProfitCard('机器人启动', data['bot_start_date'], true),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(String title, String value, bool isPositive) {
    bool isProfit = title.contains('收益') || title.contains('回撤') || 
                    title.contains('期望') || title == '收益因子';
    bool isPercentage = value.contains('%');
    bool isNumeric = value.contains('USDT') || value.contains('CNY') || 
                     isPercentage || title.contains('交易') || 
                     title == '收益因子' || title.contains('期望');

    Color? valueColor;
    if (isProfit) {
      valueColor = isPositive ? Colors.green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isNumeric ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
} 