import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class StoreAnalyticsTab extends StatefulWidget {
  final String storeId;

  const StoreAnalyticsTab({super.key, required this.storeId});

  @override
  State<StoreAnalyticsTab> createState() => _StoreAnalyticsTabState();
}

class _StoreAnalyticsTabState extends State<StoreAnalyticsTab> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _analyticsData;

  DateTimeRange? _selectedDateRange;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      Map<String, dynamic> queryParams = {};
      if (_selectedDateRange != null) {
        queryParams['startDate'] =
            _selectedDateRange!.start.toIso8601String().split('T')[0];
        queryParams['endDate'] =
            _selectedDateRange!.end.toIso8601String().split('T')[0];
      } else {
        queryParams['days'] = '30';
      }

      if (_selectedCategory != 'All') {
        queryParams['category'] = _selectedCategory;
      }

      final response = await ApiClient.dio.get(
        '/api/admin-panel/stores/${widget.storeId}/analytics',
        queryParameters: queryParams,
      );

      if (mounted) {
        setState(() {
          _analyticsData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_analyticsData == null) {
      return const Center(child: Text('No analytics data available.'));
    }

    final dailyOrders = _analyticsData!['dailyOrders'] as List<dynamic>? ?? [];
    final dailyRevenue =
        _analyticsData!['dailyRevenue'] as List<dynamic>? ?? [];
    final servicesBreakdown =
        _analyticsData!['servicesBreakdown'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics Overview',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedCategory,
                      items: ['All', 'Dry Cleaning', 'Wash & Fold', 'Ironing']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                          _fetchAnalytics();
                        }
                      },
                      underline: Container(),
                      icon: const Icon(Icons.filter_list,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_selectedDateRange == null
                          ? 'Last 30 Days'
                          : '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}'),
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
                          setState(() => _selectedDateRange = range);
                          _fetchAnalytics();
                        }
                      },
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() => _selectedDateRange = null);
                          _fetchAnalytics();
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildChartCard(
                        title: 'Daily Revenue (₹)',
                        child: _buildRevenueChart(dailyRevenue),
                      ),
                      const SizedBox(height: 24),
                      _buildChartCard(
                        title: 'Daily Orders',
                        child: _buildOrdersChart(dailyOrders),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildChartCard(
                        title: 'Services Breakdown',
                        child: _buildServicesPieChart(servicesBreakdown),
                      ),
                      const SizedBox(height: 24),
                      _buildChartCard(
                        title: 'Revenue Breakdown',
                        child: _buildRevenueBreakdownList(
                            _analyticsData!['revenueBreakdown']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
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
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.navy)),
          const SizedBox(height: 24),
          SizedBox(height: 250, child: child),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < data.length; i++) {
      double val = (data[i]['value'] as num).toDouble();
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                if (index % (data.length ~/ 5 + 1) != 0 &&
                    index != data.length - 1) return const Text('');
                String dateStr = data[index]['date'].toString();
                String shortDate = dateStr.substring(5); // MM-DD
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(shortDate,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.mutedText)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        minX: 0,
        maxX: data.isNotEmpty ? data.length - 1.0 : 0,
        minY: 0,
        maxY: maxY * 1.2,
      ),
    );
  }

  Widget _buildOrdersChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    for (int i = 0; i < data.length; i++) {
      double val = (data[i]['value'] as num).toDouble();
      if (val > maxY) maxY = val;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: const Color(0xFF1E3A8A),
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                if (index % (data.length ~/ 5 + 1) != 0 &&
                    index != data.length - 1) return const Text('');
                String dateStr = data[index]['date'].toString();
                String shortDate = dateStr.substring(5); // MM-DD
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(shortDate,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.mutedText)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        maxY: maxY * 1.2,
      ),
    );
  }

  Widget _buildServicesPieChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final colors = [
      AppTheme.primary,
      const Color(0xFF1E3A8A),
      const Color(0xFF38BDF8),
      const Color(0xFF34D399),
      const Color(0xFFFBBF24),
    ];

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < data.length; i++) {
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: (data[i]['count'] as num).toDouble(),
          title: '${data[i]['count']}',
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(data.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  data[index]['serviceName'].toString(),
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdownList(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty)
      return const Center(child: Text('No data'));

    return ListView(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.navy)),
              Text('₹${(e.value as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
