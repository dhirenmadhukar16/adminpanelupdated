import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final payrollProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/hroperations/leaves');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminPayrollScreen extends ConsumerWidget {
  const AdminPayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HR & Leaves', style: TextStyle(fontSize: 28, color: AppTheme.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Employee Leave Requests (from PostgreSQL)', style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: payrollAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty) return const Center(child: Text('No leave requests found.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final leave = data[index];
                      return ListTile(
                        leading: const Icon(Icons.event_busy, color: AppTheme.primary, size: 32),
                        title: Text(leave['employeeName'] ?? 'Unknown Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Reason: ${leave['reason']}'),
                        trailing: Chip(
                          label: Text(leave['status'] ?? 'PENDING', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: leave['status'] == 'APPROVED' ? Colors.green : (leave['status'] == 'REJECTED' ? Colors.red : Colors.orange),
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
