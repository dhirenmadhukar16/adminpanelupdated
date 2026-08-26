import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    loadFinance();
  }

  Future<void> loadFinance() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get(
        '/api/admin-panel/finance/stats',
      );

      setState(() {
        stats = Map<String, dynamic>.from(response.data);
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String v(String key) => '${stats[key] ?? 0}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Finance',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadFinance, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _card(
                        'Total Revenue',
                        '₹${v('totalRevenue')}',
                        Icons.currency_rupee,
                      ),
                      _card('Today Revenue', '₹${v('todayRevenue')}',
                          Icons.today),
                      _card(
                          'Total Payments', v('totalPayments'), Icons.payments),
                      _card('Paid Orders', v('paidOrders'), Icons.check_circle),
                      _card(
                        'Unpaid Orders',
                        v('unpaidOrders'),
                        Icons.pending_actions,
                      ),
                      _card(
                        'Partial Paid',
                        v('partialPaidOrders'),
                        Icons.pie_chart,
                      ),
                      _card(
                        'Pending Amount',
                        '₹${v('pendingAmount')}',
                        Icons.warning_amber,
                      ),
                      _card('Invoices', v('totalInvoices'), Icons.receipt),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.25),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(title, style: const TextStyle(color: AppTheme.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
