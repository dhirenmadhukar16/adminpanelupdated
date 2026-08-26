import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final auditProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/audit');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(auditProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audit & Security Logs', style: TextStyle(fontSize: 28, color: AppTheme.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('System-wide Audit Trail (from PostgreSQL)', style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: auditAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty) return const Center(child: Text('No audit logs recorded yet.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final log = data[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: AppTheme.primary),
                        title: Text('${log['actorName']} (${log['actorType']}) ${log['action']} - ${log['entityType']}'),
                        subtitle: Text('Entity: ${log['entityType']} [${log['entityId']}] • IP: ${log['ipAddress']}'),
                        trailing: Text(log['timestamp']?.toString().split('T').join(' ') ?? '', style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
