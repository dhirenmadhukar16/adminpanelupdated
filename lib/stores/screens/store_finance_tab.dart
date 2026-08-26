import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

final storeFinanceProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  try {
    final response =
        await ApiClient.dio.get('/api/admin-panel/stores/$storeId/finance');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    print('Error fetching store finance: $e');
    return {};
  }
});

class StoreFinanceTab extends ConsumerWidget {
  final String storeId;

  const StoreFinanceTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(storeFinanceProvider(storeId));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Finance Summary (Today)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primary),
                  onPressed: () => ref.refresh(storeFinanceProvider(storeId))),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: financeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (finance) {
                  return GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.5,
                    children: [
                      _buildFinanceCard(
                          'Total Revenue',
                          '₹${finance['totalRevenue'] ?? 0}',
                          Icons.account_balance_wallet,
                          Colors.green),
                      _buildFinanceCard(
                          'Total Expenses',
                          '₹${finance['totalExpenses'] ?? 0}',
                          Icons.money_off,
                          Colors.red),
                      _buildFinanceCard(
                          'Pending Bills',
                          '₹${finance['pendingBills'] ?? 0}',
                          Icons.receipt,
                          Colors.orange),
                      _buildFinanceCard(
                          'Total Orders',
                          '${finance['totalOrders'] ?? 0}',
                          Icons.shopping_cart,
                          AppTheme.primary),
                    ],
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.mutedText)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
