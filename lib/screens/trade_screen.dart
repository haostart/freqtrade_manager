import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/k_line_chart.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final GlobalKey<KLineChartState> _kLineChartKey = GlobalKey<KLineChartState>();
  List<Map<String, dynamic>>? _trades;
  Timer? _refreshTimer;
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _fetchTrades();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrades() async {
    if (!mounted) return;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final trades = await apiService.getOpenTrades();
      if (!mounted) return;
      setState(() {
        _trades = trades;
      });
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _handleAutoRefreshToggle(bool? value) {
    if (!mounted) return;
    setState(() {
      _autoRefresh = value ?? false;
    });
    
    _refreshTimer?.cancel();
    
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _fetchTrades();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Tooltip(
            message: '打开导航菜单',
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        title: const Text('交易行情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Tooltip(
            message: '刷新数据',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _kLineChartKey.currentState?.refreshData();
              },
            ),
          ),
          Tooltip(
            message: '退出登录',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await StorageService.clearCredentials();
                if (!mounted) return;
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: KLineChart(
                key: _kLineChartKey,
                trades: _trades,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 