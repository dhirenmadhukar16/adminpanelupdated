import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../cashcollection/screens/admin_cash_collection_screen.dart';

// ============================================================
// FINANCE DATA PROVIDER
// ============================================================

final financeDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get(
      '/api/admin/finance/expenses',
    );

    final expenses = response.data as List<dynamic>;

    double totalRev = 125000;
    double operatingCosts = 0;

    final List<Map<String, dynamic>> transactions = [];

    transactions.add({
      'title': 'Store Monthly Revenue',
      'time': '2026-06-30',
      'amount': '+₹125000',
      'isCredit': true,
    });

    for (final e in expenses) {
      final amount = (e['amount'] ?? 0).toDouble();

      operatingCosts += amount;

      transactions.add({
        'title': e['title'] ?? 'Expense',
        'time': e['expenseDate'] ?? 'Unknown',
        'amount': '-₹${amount.toStringAsFixed(0)}',
        'isCredit': false,
      });
    }

    final margin =
        totalRev == 0 ? 0 : ((totalRev - operatingCosts) / totalRev) * 100;

    return {
      'revenue': '₹${totalRev.toStringAsFixed(0)}',
      'revenue_trend': '+12.5%',
      'costs': '₹${operatingCosts.toStringAsFixed(0)}',
      'costs_trend': '+5.0%',
      'margin': '${margin.toStringAsFixed(1)}%',
      'margin_trend': '+1.2%',
      'transactions': transactions.reversed.toList(),
    };
  } catch (e) {
    debugPrint(
      'Error fetching finance: $e',
    );

    return {
      'revenue': '₹125000',
      'revenue_trend': '0%',
      'costs': '₹0',
      'costs_trend': '0%',
      'margin': '100%',
      'margin_trend': '0%',
      'transactions': <Map<String, dynamic>>[],
    };
  }
});

// ============================================================
// ADMIN FINANCE ERP
// ============================================================

class AdminFinanceERP extends ConsumerStatefulWidget {
  const AdminFinanceERP({
    super.key,
  });

  @override
  ConsumerState<AdminFinanceERP> createState() => _AdminFinanceERPState();
}

class _AdminFinanceERPState extends ConsumerState<AdminFinanceERP>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Overview & ERP',
                  style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddExpenseDialog(
                      context,
                      ref,
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                  ),
                  label: const Text(
                    'Add Expense',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // FINANCE TABS
            // ==================================================

            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: const Color(
                    0xFFE2E8F0,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.mutedText,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(
                      Icons.analytics_outlined,
                      size: 20,
                    ),
                    text: 'Financial Overview',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                    ),
                    text: 'Cash Collection',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // TAB CONTENT
            // ==================================================

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCashCollectionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FINANCIAL OVERVIEW TAB
  // ============================================================

  Widget _buildOverviewTab() {
    final financeAsync = ref.watch(
      financeDataProvider,
    );

    return financeAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
      data: (data) {
        return Column(
          children: [
            // --------------------------------------------------
            // FINANCE CARDS
            // --------------------------------------------------

            Row(
              children: [
                _buildFinanceCard(
                  'Total Revenue (MTD)',
                  data['revenue'],
                  data['revenue_trend'],
                  AppTheme.primary,
                ),
                const SizedBox(
                  width: 24,
                ),
                _buildFinanceCard(
                  'Operating Costs',
                  data['costs'],
                  data['costs_trend'],
                  AppTheme.warning,
                ),
                const SizedBox(
                  width: 24,
                ),
                _buildFinanceCard(
                  'Net Margin',
                  data['margin'],
                  data['margin_trend'],
                  AppTheme.success,
                ),
              ],
            ),

            const SizedBox(
              height: 32,
            ),

            // --------------------------------------------------
            // CHARTS
            // --------------------------------------------------

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildRevenueChart(),
                  ),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildTransactions(
                      data,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CASH COLLECTION TAB
  // ============================================================

  Widget _buildCashCollectionTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // CASH COLLECTION HEADER
          // --------------------------------------------------

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Cash Collection',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Monitor store-wise cash collection, refunds and reconciliation by date.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCashCollectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                  ),
                  label: const Text(
                    'Open Cash Collection',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // --------------------------------------------------
          // CASH COLLECTION INFORMATION
          // --------------------------------------------------

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(
                24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _cashCollectionInfoCard(
                      icon: Icons.store_outlined,
                      title: 'Store-wise',
                      subtitle: 'View collection separately for every store.',
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: _cashCollectionInfoCard(
                      icon: Icons.date_range_outlined,
                      title: 'Date-wise',
                      subtitle: 'Select a specific collection date.',
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: _cashCollectionInfoCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Reconciliation',
                      subtitle:
                          'Check declared, expected and difference amounts.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CASH COLLECTION INFO CARD
  // ============================================================

  Widget _cashCollectionInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF8FAFC,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVENUE CHART
  // ============================================================

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue vs Costs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 100),
                      FlSpot(1, 150),
                      FlSpot(2, 130),
                      FlSpot(3, 220),
                      FlSpot(4, 250),
                      FlSpot(5, 300),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 80),
                      FlSpot(1, 90),
                      FlSpot(2, 85),
                      FlSpot(3, 110),
                      FlSpot(4, 115),
                      FlSpot(5, 120),
                    ],
                    isCurved: true,
                    color: AppTheme.warning,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Widget _buildTransactions(
    Map<String, dynamic> data,
  ) {
    final transactions = data['transactions'] as List;

    return Container(
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];

                final isCredit = t['isCredit'] == true;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isCredit
                            ? Colors.green.withValues(
                                alpha: 0.1,
                              )
                            : Colors.red.withValues(
                                alpha: 0.1,
                              ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                          size: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              t['time'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        t['amount'].toString(),
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCE CARD
  // ============================================================

  Widget _buildFinanceCard(
    String title,
    String amount,
    String change,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(
          32,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: const Color(
              0xFFE2E8F0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.02,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Text(
                change,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD EXPENSE
  // ============================================================

  void _showAddExpenseDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final titleController = TextEditingController();

    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Operating Expense',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.dio.post(
                    '/api/admin/finance/expenses',
                    data: {
                      'title': titleController.text,
                      'category': 'General',
                      'amount': double.tryParse(
                            amountController.text,
                          ) ??
                          0,
                      'description': 'Manual expense entry',
                    },
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                  );

                  ref.refresh(
                    financeDataProvider,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Expense added successfully!',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed: $e',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Add Expense',
              ),
            ),
          ],
        );
      },
    );
  }
}
