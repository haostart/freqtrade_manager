import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecentTrades extends StatefulWidget {
  const RecentTrades({super.key});

  @override
  State<RecentTrades> createState() => RecentTradesState();
}

class RecentTradesState extends State<RecentTrades> {
  late Future<List<Map<String, dynamic>>> _trades;
  bool autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _trades = _fetchTrades();
  }

  Future<List<Map<String, dynamic>>> _fetchTrades() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return await apiService.getTrades(limit: 20);
  }

  void refreshTrades() {
    setState(() {
      _trades = _fetchTrades();
    });
  }

  void _toggleAutoRefresh(bool? value) {
    if (!mounted) return;
    setState(() {
      autoRefresh = value ?? false;
      _refreshTimer?.cancel();
      if (autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          refreshTrades();
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
        title: AppLocalizations.of(context)!.recentTrades,
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _trades,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.getTradesFailed(snapshot.error.toString())));
          }

          final trades = snapshot.data;
          if (trades == null || trades.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noTrades));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshTrades();
            },
            child: ListView.builder(
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades.reversed.toList()[index];
                final profitRatio = trade['realized_profit_ratio'] is String 
                    ? double.parse(trade['realized_profit_ratio'] ?? '0') 
                    : (trade['realized_profit_ratio'] ?? 0.0) as double;
                final isProfit = profitRatio > 0;
                final openTime = DateTime.parse(trade['open_date']);
                final closeTime = trade['close_date'] != null 
                    ? DateTime.parse(trade['close_date'])
                    : null;
                final isShort = trade['is_short'] ?? false;

                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            trade['pair'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isShort ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isShort ? AppLocalizations.of(context)!.short : AppLocalizations.of(context)!.long,
                            style: TextStyle(
                              color: isShort ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)!.openTime}: ${DateFormat('MM-dd HH:mm').format(openTime)}\n'
                      '${closeTime != null ? '${AppLocalizations.of(context)!.closeTime}: ${DateFormat('MM-dd HH:mm').format(closeTime)}' : AppLocalizations.of(context)!.open}\n'
                      '${AppLocalizations.of(context)!.openPrice}: ${trade['open_rate']}, ${AppLocalizations.of(context)!.closePrice}: ${trade['close_rate'] ?? AppLocalizations.of(context)!.notClosed}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(profitRatio * 100).toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isProfit ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '${trade['realized_profit'] ?? '0'} USDT',
                            style: TextStyle(
                              fontSize: 14,
                              color: isProfit ? Colors.green : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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