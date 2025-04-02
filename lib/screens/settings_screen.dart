import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer2<SettingsProvider, LanguageProvider>(
          builder: (context, settings, languageProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.language,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: languageProvider.currentLocale.languageCode,
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'zh',
                      child: Text('中文'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      languageProvider.setLanguage(value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  localizations.theme,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(settings.isDarkMode ? localizations.darkMode : localizations.lightMode),
                  value: settings.isDarkMode,
                  onChanged: (bool value) {
                    settings.setDarkMode(value);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 