import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'providers/market_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'services/binance_service.dart';
import 'widgets/fireworks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'screens/settings_screen.dart';
import 'providers/sidebar_provider.dart';
import 'services/notification_service.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final credentials = await StorageService.getCredentials();
  final binanceService = BinanceService();
  final storageService = StorageService(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ApiService(baseUrl: credentials['api_url'] ?? ''),
        ),
        Provider.value(value: binanceService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => SidebarProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: const TradingApp(),
    ),
  );
}

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, SettingsProvider>(
      builder: (context, languageProvider, settings, child) {
        return MaterialApp(
          title: 'Freqtrade Manager',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 255, 255, 255),
              primary: Color.fromARGB(255, 7, 176, 182),
            ),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 255, 255, 255),
              primary: Color.fromARGB(255, 7, 176, 182),
              brightness: Brightness.dark,
            ),
            brightness: Brightness.dark,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => context.watch<AuthProvider>().isLoggedIn 
                ? const HomeScreen()
                : const LoginScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
