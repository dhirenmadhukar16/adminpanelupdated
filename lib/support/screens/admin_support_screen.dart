import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final supportProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/support');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportAsync = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support & Escalations', style: TextStyle(fontSize: 28, color: AppTheme.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Customer Service Tickets (from PostgreSQL)', style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: supportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty) return const Center(child: Text('No support tickets active.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final ticket = data[index];
                      return ListTile(
                        leading: const Icon(Icons.support_agent, color: AppTheme.primary, size: 32),
                        title: Text('${ticket['customerName']} - ${ticket['issueCategory']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(ticket['description'] ?? ''),
                        trailing: Chip(
                          label: Text(ticket['status'] ?? 'OPEN', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: ticket['status'] == 'OPEN' ? Colors.red : (ticket['status'] == 'RESOLVED' ? Colors.green : Colors.orange),
                        ),
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
