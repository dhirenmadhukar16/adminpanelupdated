import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final storeReportsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  try {
    final dateRange = ref.watch(selectedDateRangeProvider);
    final category = ref.watch(selectedCategoryProvider);

    Map<String, dynamic> queryParams = {};
    if (dateRange != null) {
      queryParams['startDate'] =
          dateRange.start.toIso8601String().split('T')[0];
      queryParams['endDate'] = dateRange.end.toIso8601String().split('T')[0];
    }
    if (category != null && category != 'All') {
      queryParams['category'] = category;
    }

    final response = await ApiClient.dio.get(
      '/api/admin-panel/stores/$storeId/reports',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  } catch (e) {
    print('Error fetching store reports: $e');
    return {};
  }
});

class StoreReportsTab extends ConsumerWidget {
  final String storeId;

  const StoreReportsTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(storeReportsProvider(storeId));
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDateRange = ref.watch(selectedDateRangeProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Reports & Analytics',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedCategory ?? 'All',
                    items: ['All', 'Dry Cleaning', 'Wash & Fold', 'Ironing']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        ref.read(selectedCategoryProvider.notifier).state = val,
                    underline: Container(),
                    icon:
                        const Icon(Icons.filter_list, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(selectedDateRange == null
                        ? 'Select Date'
                        : '${selectedDateRange.start.toLocal().toString().split(' ')[0]} - ${selectedDateRange.end.toLocal().toString().split(' ')[0]}'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: AppTheme.primary,
                        elevation: 0),
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (range != null) {
                        ref.read(selectedDateRangeProvider.notifier).state =
                            range;
                      }
                    },
                  ),
                  if (selectedDateRange != null)
                    IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () => ref
                            .read(selectedDateRangeProvider.notifier)
                            .state = null),
                  const SizedBox(width: 16),
                  IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.primary),
                      onPressed: () =>
                          ref.refresh(storeReportsProvider(storeId))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (reports) {
                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 2.5,
                    children: [
                      _buildReportCard(
                          'Total Orders',
                          '${reports['totalOrders'] ?? 0}',
                          Icons.list_alt,
                          AppTheme.primary),
                      _buildReportCard(
                          'Online Orders',
                          '${reports['onlineOrders'] ?? 0}',
                          Icons.shopping_cart,
                          Colors.blue),
                      _buildReportCard(
                          'Walk-in Orders',
                          '${reports['walkInOrders'] ?? 0}',
                          Icons.storefront,
                          Colors.orange),
                      _buildReportCard(
                          'Completed Orders',
                          '${reports['completedOrders'] ?? 0}',
                          Icons.check_circle,
                          Colors.green),
                      _buildReportCard(
                          'Total Revenue',
                          '₹${reports['totalRevenue'] ?? 0}',
                          Icons.monetization_on,
                          AppTheme.navy),
                      _buildReportCard(
                          'Online Revenue',
                          '₹${reports['onlineRevenue'] ?? 0}',
                          Icons.payments,
                          Colors.blue),
                      _buildReportCard(
                          'Walk-in Revenue',
                          '₹${reports['walkInRevenue'] ?? 0}',
                          Icons.account_balance_wallet,
                          Colors.orange),
                      _buildReportCard(
                          'Performance Score',
                          '${reports['performanceScore'] ?? 0}%',
                          Icons.star,
                          Colors.blueGrey),
                    ],
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildReportCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.mutedText)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
