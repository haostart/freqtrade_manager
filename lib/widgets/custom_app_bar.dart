import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool autoRefresh;
  final ValueChanged<bool?>? onToggleAutoRefresh;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.autoRefresh,
    this.onToggleAutoRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        Row(
          children: [
            const Text('自动刷新'),
            Checkbox(
              value: autoRefresh,
              onChanged: onToggleAutoRefresh,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 