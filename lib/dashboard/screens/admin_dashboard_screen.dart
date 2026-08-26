import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../orders/screens/admin_orders_kanban.dart';
import 'admin_revenue_details.dart';
import 'admin_active_riders_details.dart';

// Provider for Dashboard Analytics Data
final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response =
      await ApiClient.dio.get('/api/admin-panel/analytics/executive-dashboard');
  return response.data as Map<String, dynamic>;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: dashboardDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading dashboard: $err',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (data) => _buildDashboard(context, data),
      ),
    );
  }

  Widget _buildTimeStatusFilters(BuildContext context) {
    final filters = [
      {'label': 'Overdue', 'color': Colors.red},
      {'label': 'Late', 'color': Colors.orange},
      {'label': 'Advanced', 'color': Colors.blue},
      {'label': 'Urgent', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operational Tracking',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((f) {
            return ActionChip(
              label: Text(f['label'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: (f['color'] as Color).withValues(alpha: 0.1),
              labelStyle: TextStyle(color: f['color'] as Color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: f['color'] as Color, width: 1.5),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          " Garments filter coming to Admin Kanban soon!")),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Good Morning, Devansh 👋',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy)),
                    const SizedBox(height: 8),
                    const Text(
                        'Here\'s what\'s happening with your business today.',
                        style:
                            TextStyle(fontSize: 14, color: AppTheme.mutedText)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.mutedText),
                          SizedBox(width: 8),
                          Text('Today, 29 Jun 2026',
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Morning, Devansh 👋',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy)),
                        SizedBox(height: 8),
                        Text(
                            'Here\'s what\'s happening with your business today.',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.mutedText)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.mutedText),
                          SizedBox(width: 8),
                          Text('Today, 29 Jun 2026',
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 32),

              // KPI Cards Row
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                      width: isMobile
                          ? double.infinity
                          : (constraints.maxWidth - 64) / 5 - 16,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminRevenueDetailsScreen()));
                        },
                        child: _buildKpiCard(
                            'Total Revenue',
                            '₹${data['revenue']['value']}',
                            '+${data['revenue']['trend']}%',
                            Icons.account_balance_wallet,
                            Colors.green),
                      )),
                  SizedBox(
                      width: isMobile
                          ? double.infinity
                          : (constraints.maxWidth - 64) / 5 - 16,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminOrdersKanban()));
                        },
                        child: _buildKpiCard(
                            'Total Orders',
                            '${data['orders']['value']}',
                            '+${data['orders']['trend']}%',
                            Icons.receipt_long,
                            Colors.purple),
                      )),
                  SizedBox(
                      width: isMobile
                          ? double.infinity
                          : (constraints.maxWidth - 64) / 5 - 16,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminOrdersKanban()));
                        },
                        child: _buildKpiCard(
                            'Pickups',
                            '${data['pickups']['value']}',
                            '+${data['pickups']['trend']}%',
                            Icons.local_shipping,
                            Colors.blue),
                      )),
                  SizedBox(
                      width: isMobile
                          ? double.infinity
                          : (constraints.maxWidth - 64) / 5 - 16,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminOrdersKanban()));
                        },
                        child: _buildKpiCard(
                            'Deliveries',
                            '${data['deliveries']['value']}',
                            '+${data['deliveries']['trend']}%',
                            Icons.check_circle,
                            Colors.orange),
                      )),
                  SizedBox(
                    width: isMobile
                        ? double.infinity
                        : (constraints.maxWidth - 64) / 5 - 16,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminActiveRidersDetails()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.cyan.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.electric_moped,
                                        color: Colors.cyan, size: 20)),
                                const SizedBox(width: 12),
                                const Text('Active Riders',
                                    style: TextStyle(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('${data['activeRiders']}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.navy)),
                            const Text('Online now',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 32),

              // Charts Row
              isMobile
                  ? Column(
                      children: [
                        _buildRevenueChart(data),
                        const SizedBox(height: 24),
                        _buildOrdersSummary(data),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRevenueChart(data)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildOrdersSummary(data)),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true, reservedSize: 22, interval: 1),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(data['revenueChart']),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSummary(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orders Summary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                          color: AppTheme.primary,
                          value: data['ordersSummary']['completed'].toDouble(),
                          title: '',
                          radius: 20),
                      PieChartSectionData(
                          color: Colors.purple,
                          value: data['ordersSummary']['processing'].toDouble(),
                          title: '',
                          radius: 20),
                      PieChartSectionData(
                          color: Colors.orange,
                          value: data['ordersSummary']['pending'].toDouble(),
                          title: '',
                          radius: 20),
                      PieChartSectionData(
                          color: Colors.red,
                          value: data['ordersSummary']['cancelled'].toDouble(),
                          title: '',
                          radius: 20),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${data['ordersSummary']['total']}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy)),
                      const Text('Total Orders',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedText)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLegendItem('Completed', data['ordersSummary']['completed'],
              AppTheme.primary),
          _buildLegendItem(
              'Processing', data['ordersSummary']['processing'], Colors.purple),
          _buildLegendItem(
              'Pending', data['ordersSummary']['pending'], Colors.orange),
          _buildLegendItem(
              'Cancelled', data['ordersSummary']['cancelled'], Colors.red),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
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
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 12, color: color),
              const SizedBox(width: 4),
              Text('$trend vs yesterday',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.mutedText)),
            ],
          ),
          Text('$value',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.navy)),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(List<dynamic> rawData) {
    List<FlSpot> spots = [];
    for (int i = 0; i < rawData.length; i++) {
      spots.add(FlSpot(i.toDouble(), rawData[i].toDouble()));
    }
    return spots;
  }
}
