import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

final storeEmployeesProvider =
    FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  try {
    final response =
        await ApiClient.dio.get('/api/admin-panel/stores/$storeId/employees');
    return response.data as List<dynamic>;
  } catch (e) {
    print('Error fetching store employees: $e');
    return [];
  }
});

class StoreEmployeesTab extends ConsumerWidget {
  final String storeId;

  const StoreEmployeesTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(storeEmployeesProvider(storeId));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Staff',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primary),
                  onPressed: () =>
                      ref.refresh(storeEmployeesProvider(storeId))),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: employeesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (employees) {
                  if (employees.isEmpty) {
                    return const Center(
                        child: Text('No employees found for this store.'));
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(Icons.person, color: AppTheme.primary),
                          ),
                          title: Text(emp['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy)),
                          subtitle: Text(
                              '${emp['role'] ?? 'STAFF'} • ${emp['phone'] ?? ''}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: emp['status'] == 'ACTIVE'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              emp['status'] ?? 'UNKNOWN',
                              style: TextStyle(
                                color: emp['status'] == 'ACTIVE'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }
}
