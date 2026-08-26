import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

final storeOrdersProvider =
    FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  try {
    final response =
        await ApiClient.dio.get('/api/admin-panel/stores/$storeId/orders');
    return response.data as List<dynamic>;
  } catch (e) {
    print('Error fetching store orders: $e');
    return [];
  }
});

class StoreOrdersTab extends ConsumerWidget {
  final String storeId;

  const StoreOrdersTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(storeOrdersProvider(storeId));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Orders',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primary),
                  onPressed: () => ref.refresh(storeOrdersProvider(storeId))),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(
                        child: Text('No orders found for this store.'));
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.receipt_long,
                                color: AppTheme.primary),
                          ),
                          title: Text(order['orderNumber'] ?? 'Unknown Order',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy)),
                          subtitle: Text(
                              'Status: ${order['status'] ?? 'PENDING'} • Total: ₹${order['subtotal'] ?? 0}'),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppTheme.mutedText),
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
