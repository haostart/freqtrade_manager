import 'package:flutter/material.dart';
import '../widgets/account_info.dart';
import '../widgets/open_trades.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // 导入 Timer 所需的库
import '../widgets/recent_trades.dart';
import '../widgets/recent_logs.dart';
import '../widgets/profit_summary.dart';
import '../widgets/daily_profit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer; // 定义一个 Timer
  final PageController _pageController = PageController(); // 创建 PageController
  final GlobalKey<OpenTradesState> _openTradesKey = GlobalKey<OpenTradesState>(); // 创建 GlobalKey
  final GlobalKey<RecentTradesState> _recentTradesKey = GlobalKey<RecentTradesState>();
  final GlobalKey<RecentLogsState> _recentLogsKey = GlobalKey<RecentLogsState>();
  final GlobalKey<ProfitSummaryState> _profitSummaryKey = GlobalKey<ProfitSummaryState>();
  final GlobalKey<DailyProfitState> _dailyProfitKey = GlobalKey<DailyProfitState>();

  @override
  void initState() {
    super.initState();
    // 设置定时器，每隔 30 秒刷新一次数据
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // 只刷新勾选了自动刷新的页面
      if (_openTradesKey.currentState?.autoRefresh == true) {
        _openTradesKey.currentState?.refreshTrades();
      }
      if (_recentLogsKey.currentState?.autoRefresh == true) {
        _recentLogsKey.currentState?.refreshLogs();
      }
      if (_profitSummaryKey.currentState?.autoRefresh == true) {
        _profitSummaryKey.currentState?.refreshProfitData();
      }
      if (_dailyProfitKey.currentState?.autoRefresh == true) {
        _dailyProfitKey.currentState?.refreshDailyData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 取消定时器
    _pageController.dispose(); // 释放 PageController
    super.dispose();
  }

  void _nextPage() {
    // 总页面数为6（AccountInfo, OpenTrades, RecentTrades, RecentLogs, ProfitSummary, DailyProfit）
    if (_pageController.page! < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _logout() async {
    // 显示确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    // 如果用户没有确认或组件已经卸载，则返回
    if (!mounted || confirm != true) return;

    try {
      await StorageService.clearCredentials();
      if (!mounted) return;
      context.read<AuthProvider>().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败: $e')),
      );
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
        title: const Text('账号交易信息'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Tooltip(
            message: '退出登录',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ),
          PopupMenuButton<int>(
            onSelected: (value) {
              _pageController.jumpToPage(value); // 跳转到选定的页面
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('账号信息')),
              const PopupMenuItem(value: 1, child: Text('开放交易')),
              const PopupMenuItem(value: 2, child: Text('最近交易')),
              const PopupMenuItem(value: 3, child: Text('最近日志')),
              const PopupMenuItem(value: 4, child: Text('利润摘要')),
              const PopupMenuItem(value: 5, child: Text('每日利润')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              const AccountInfo(),
              OpenTrades(key: _openTradesKey),
              ProfitSummary(key: _profitSummaryKey),
              RecentTrades(key: _recentTradesKey),
              RecentLogs(key: _recentLogsKey),
              Scaffold(
                body: DailyProfit(key: _dailyProfitKey),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 20, // 垂直居中
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 40),
              onPressed: _previousPage,
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 20, // 垂直居中
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, size: 40),
              onPressed: _nextPage,
            ),
          ),
        ],
      ),
    );
  }
} 