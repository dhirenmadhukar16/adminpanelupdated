import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminRevenueDetailsScreen extends StatelessWidget {
  const AdminRevenueDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Revenue Details & AI Summary',
            style:
                TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.navy),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Summary Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.navy.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.smart_toy,
                        color: Colors.purple, size: 32),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Revenue Insights',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy)),
                        const SizedBox(height: 12),
                        Text(
                          "Revenue is up 12.5% compared to yesterday. Store 1 (Downtown) is driving the highest volume, contributing to 45% of total sales today. "
                          "Premium Dry Cleaning requests spiked during the afternoon. Consider running targeted promotions on standard wash services tomorrow to boost off-peak hours.",
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppTheme.navy.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Revenue Breakdown by Store',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy)),
            const SizedBox(height: 24),
            // Store Breakdown List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStoreRow('Store 1 (Downtown)', '₹22,000', '+15%'),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildStoreRow('Store 2 (Suburbs)', '₹14,500', '+5%'),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildStoreRow('Store 3 (Westside)', '₹11,950', '+22%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreRow(String storeName, String revenue, String growth) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.storefront, color: AppTheme.primary),
      ),
      title: Text(storeName,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 16)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(revenue,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.green,
                  fontSize: 18)),
          Text(growth,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
