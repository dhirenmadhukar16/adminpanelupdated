import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final analyticsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.dio
        .get('/api/admin-panel/analytics/executive-dashboard');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
});

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Analytics',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Real-time data visualization from PostgreSQL',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: analyticsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading analytics: $err')),
                data: (data) {
                  if (data == null)
                    return const Center(
                        child: Text(
                            'Analytics pipeline configuring. No data yet.'));
                  return SingleChildScrollView(
                      child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildKpiCard('Revenue', data['revenue'])),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildKpiCard('Orders', data['orders'])),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildKpiCard('Pickups', data['pickups'])),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildKpiCard(
                                  'Deliveries', data['deliveries'])),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Weekly Revenue',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navy)),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: (data['revenueChart']
                                              as List<dynamic>)
                                          .map((val) {
                                        final height =
                                            (val as num) / 52000 * 200;
                                        return Container(
                                          width: 40,
                                          height: height.toDouble(),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Orders Summary',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navy)),
                                  const SizedBox(height: 16),
                                  _buildSummaryRow(
                                      'Total',
                                      data['ordersSummary']['total'].toString(),
                                      Colors.blue),
                                  _buildSummaryRow(
                                      'Completed',
                                      data['ordersSummary']['completed']
                                          .toString(),
                                      Colors.green),
                                  _buildSummaryRow(
                                      'Processing',
                                      data['ordersSummary']['processing']
                                          .toString(),
                                      Colors.orange),
                                  _buildSummaryRow(
                                      'Pending',
                                      data['ordersSummary']['pending']
                                          .toString(),
                                      Colors.grey),
                                  _buildSummaryRow(
                                      'Cancelled',
                                      data['ordersSummary']['cancelled']
                                          .toString(),
                                      Colors.red),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Active Riders',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.navy)),
                                        Text(data['activeRiders'].toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: AppTheme.primary)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, Map<String, dynamic> data) {
    final value = data['value'];
    final trend = data['trend'] as num;
    final isPositive = trend >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['label'],
              style: const TextStyle(
                  color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(title == 'Revenue' ? '₹$value' : '$value',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red, size: 16),
              const SizedBox(width: 4),
              Text('${trend.abs()}%',
                  style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold)),
              const Text(' vs last week',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.mutedText)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.navy)),
        ],
      ),
    );
  }
}
