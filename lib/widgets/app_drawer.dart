import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/trade_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context)!;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              localizations.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          Tooltip(
            message: localizations.viewAccountInfo,
            child: ListTile(
              leading: const Icon(Icons.home),
              title: Text(localizations.marketData),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
          ),
          Tooltip(
            message: localizations.viewMarketData,
            child: ListTile(
              leading: const Icon(Icons.candlestick_chart),
              title: Text(localizations.trading),
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
            message: localizations.appSettings,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: Text(localizations.settings),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          Tooltip(
            message: localizations.logoutTooltip,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(localizations.logout),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
} 