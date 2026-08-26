import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  bool loading = true;
  String? error;
  List logs = [];

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin/audit');

      setState(() {
        logs = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color actionColor(String? action) {
    final a = action?.toUpperCase() ?? '';
    if (a.contains('CREATE')) return Colors.green;
    if (a.contains('UPDATE')) return Colors.blue;
    if (a.contains('DELETE') || a.contains('CANCEL')) return Colors.red;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Audit Logs',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadLogs, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final l = logs[index];
                      final action = l['action']?.toString();

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                actionColor(action).withValues(alpha: 0.15),
                            child:
                                Icon(Icons.history, color: actionColor(action)),
                          ),
                          title: Text(
                            '${l['module'] ?? 'Module'} • ${l['action'] ?? 'Action'}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${l['description'] ?? ''}\n'
                            'Actor: ${l['actorType'] ?? '-'} | Time: ${l['createdAt'] ?? '-'}',
                          ),
                          trailing: Text(
                            l['referenceId']?.toString().substring(0, 8) ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
