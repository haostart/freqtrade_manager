import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'custom_app_bar.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountInfo extends StatefulWidget {
  const AccountInfo({super.key});

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  late Future<Map<String, dynamic>> _accountInfo;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _accountInfo = _fetchAccountInfo();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleAutoRefreshToggle(bool? value) {
    setState(() {
      _autoRefresh = value ?? false;
    });
    
    _refreshTimer?.cancel();
    
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        setState(() {
          _accountInfo = _fetchAccountInfo();
        });
      });
    }
  }

  Future<Map<String, dynamic>> _fetchAccountInfo() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.getAccountInfo();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: localizations.accountInfo,
        autoRefresh: _autoRefresh,
        onToggleAutoRefresh: _handleAutoRefreshToggle,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _accountInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(localizations.loading));
          }

          if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          }

          final accountInfo = snapshot.data;
          if (accountInfo == null) {
            return Center(child: Text(localizations.noData));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _accountInfo = _fetchAccountInfo();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.accountOverview,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                localizations.totalAssets,
                                '${_formatNumber(accountInfo['__summary__']?['total'])} ${accountInfo['__summary__']?['stake_currency'] ?? 'USDT'}',
                                fiatValue: '${_formatNumber(accountInfo['__summary__']?['total_value'])} ${accountInfo['__summary__']?['fiat_currency']}',
                              ),
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                localizations.botHoldings,
                                '${_formatNumber(accountInfo['__summary__']?['total_bot'])} USDT',
                                fiatValue: '${_formatNumber(accountInfo['__summary__']?['total_bot_value'])} ${accountInfo['__summary__']?['fiat_currency']}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                localizations.initialCapital,
                                '${_formatNumber(accountInfo['__summary__']?['starting_capital'])} ${accountInfo['__summary__']?['stake_currency'] ?? 'USDT'}',
                                fiatValue: '${_formatNumber(accountInfo['__summary__']?['starting_capital_fiat'])} ${accountInfo['__summary__']?['fiat_currency']}',
                              ),
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                localizations.profitRate,
                                '${_formatNumber(accountInfo['__summary__']?['profit_pct'])}%',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.currencyBalance,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        ...accountInfo.entries.where((entry) => entry.key != '__summary__').map((entry) {
                          final currency = entry.key;
                          final balance = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBalanceItem(localizations.available, _formatNumber(balance['free'])),
                                    ),
                                    Expanded(
                                      child: _buildBalanceItem(localizations.stakedAmount, _formatNumber(balance['est_stake'])),
                                    ),
                                    Expanded(
                                      child: _buildBalanceItem(localizations.total, _formatNumber(balance['total'])),
                                    ),
                                  ],
                                ),
                                if ((balance['bot_owned'] ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${localizations.botOwned}: ${_formatNumber(balance['bot_owned'])}',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                const Divider(),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, {String? fiatValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value),
        if (fiatValue != null)
          Text(
            fiatValue,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0.00';
    return number.toStringAsFixed(2);
  }
} 