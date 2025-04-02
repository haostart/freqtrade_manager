import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'custom_app_bar.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecentLogs extends StatefulWidget {
  const RecentLogs({super.key});

  @override
  State<RecentLogs> createState() => RecentLogsState();
}

class RecentLogsState extends State<RecentLogs> {
  late Future<List<List<dynamic>>> _logs;
  bool autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _logs = _fetchLogs();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<List<dynamic>>> _fetchLogs() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.getLogs(limit: 50);
    return List<List<dynamic>>.from(response['logs']);
  }

  void refreshLogs() {
    if (!mounted) return;
    setState(() {
      _logs = _fetchLogs();
    });
  }

  void _toggleAutoRefresh(bool? value) {
    if (!mounted) return;
    setState(() {
      autoRefresh = value ?? false;
      _refreshTimer?.cancel();
      if (autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          refreshLogs();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.recentLogs,
        autoRefresh: autoRefresh,
        onToggleAutoRefresh: _toggleAutoRefresh,
      ),
      body: FutureBuilder<List<List<dynamic>>>(
        future: _logs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.getLogsFailed(snapshot.error.toString())));
          }

          final logs = snapshot.data;
          if (logs == null || logs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noLogs));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshLogs();
            },
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final time = log[0] as String;
                final message = log[2] as String;
                final level = log[3] as String;
                final content = log[4] as String;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              level,
                              style: TextStyle(
                                fontSize: 12,
                                color: level == 'ERROR' ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(content),
                      ],
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