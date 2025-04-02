import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/trade_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    // 清除保存的凭据
    await StorageService.clearCredentials();
    
    // 清除认证状态
    if (!context.mounted) return;
    context.read<AuthProvider>().logout();
    
    // 返回登录页面
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              '交易菜单',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          Tooltip(
            message: '查看账户信息和当前交易',
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text('账户概览'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
          ),
          Tooltip(
            message: '查看实时行情数据',
            child: ListTile(
              leading: const Icon(Icons.candlestick_chart),
              title: const Text('交易行情'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TradeScreen()),
                );
              },
            ),
          ),
          const Divider(),
          Tooltip(
            message: '退出当前账号',
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
} 