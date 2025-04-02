import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool autoRefresh;
  final ValueChanged<bool?>? onToggleAutoRefresh;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.autoRefresh,
    this.onToggleAutoRefresh,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final List<Widget> allActions = [
      if (actions != null) ...actions!,
      Row(
        children: [
          Text(localizations.refresh),
          Checkbox(
            value: autoRefresh,
            onChanged: onToggleAutoRefresh,
          ),
        ],
      ),
    ];

    return AppBar(
      title: Text(title),
      actions: allActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 