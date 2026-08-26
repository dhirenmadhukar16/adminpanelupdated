import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'store_orders_tab.dart';
import 'store_analytics_tab.dart';
import 'store_pricing_tab.dart';
import 'store_customers_tab.dart';
import 'store_employees_tab.dart';
import 'store_expenses_tab.dart';
import 'store_finance_tab.dart';
import 'store_inventory_tab.dart';
import 'store_machines_tab.dart';
import 'store_reports_tab.dart';
import 'add_edit_store_screen.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  final _passwordController = TextEditingController();

  Future<void> _showResetPasswordDialog(
      BuildContext context, String storeId) async {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Store Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = _passwordController.text.trim();
                if (newPassword.isEmpty) return;

                Navigator.pop(context);
                try {
                  await ApiClient.dio.patch(
                      '/api/admin/stores/$storeId/reset-password',
                      data: {
                        'newPassword': newPassword,
                      });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                        content: Text('Password reset successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to reset password: $e')),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId = widget.store['storeId']?.toString() ??
        widget.store['id']?.toString() ??
        '';

    return DefaultTabController(
      length: 10,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Store Details',
              style:
                  TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: AppTheme.mutedText),
              onSelected: (value) {
                if (value == 'reset_password') {
                  _showResetPasswordDialog(context, storeId);
                } else if (value == 'edit_store') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditStoreScreen(
                        store: widget.store,
                        onSaved: () {
                          // refresh if needed, but we might need a callback to parent
                          // For now, it will just pop and show the updated list if they go back.
                        },
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_store',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Edit Store'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Reset Password'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.mutedText),
                onPressed: () {}),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Top Section (Blue Header + Charts)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blue Store Identity Card
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF1E3A8A)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.storefront,
                                    color: AppTheme.primary, size: 32),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        widget.store['storeName'] ??
                                            widget.store['name'] ??
                                            'Unknown Store',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${widget.store['address'] ?? '123 Main St'}, ${widget.store['city'] ?? ''}',
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    if (widget.store['loginEmail'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.login,
                                              color: Colors.white70, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                              'Login ID: ${widget.store['loginEmail']}',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Text('STORE_ACTIVE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              )
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              _buildSplitStat(
                                  'Revenue',
                                  '₹${widget.store['totalRevenue'] ?? 0}',
                                  'Online: ₹${widget.store['onlineRevenue'] ?? 0} • Walk-in: ₹${widget.store['walkInRevenue'] ?? 0}'),
                              const SizedBox(width: 32),
                              _buildSplitStat(
                                  'Orders',
                                  '${widget.store['totalOrders'] ?? 0}',
                                  'Online: ${widget.store['onlineOrders'] ?? 0} • Walk-in: ${widget.store['walkInOrders'] ?? 0}'),
                              const SizedBox(width: 32),
                              _buildHeaderStat('Employees',
                                  '${widget.store['totalEmployees'] ?? 0}'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const TabBar(
                isScrollable: true,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.mutedText,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Orders'),
                  Tab(text: 'Customers'),
                  Tab(text: 'Services & Pricing'),
                  Tab(text: 'Employees'),
                  Tab(text: 'Inventory'),
                  Tab(text: 'Machines'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Finance'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  StoreOrdersTab(storeId: storeId),
                  StoreCustomersTab(storeId: storeId),
                  StorePricingTab(storeId: storeId),
                  StoreEmployeesTab(storeId: storeId),
                  StoreInventoryTab(storeId: storeId),
                  StoreMachinesTab(storeId: storeId),
                  StoreExpensesTab(storeId: storeId),
                  StoreFinanceTab(storeId: storeId),
                  StoreAnalyticsTab(storeId: storeId),
                  StoreReportsTab(storeId: storeId),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSplitStat(String label, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.white70)),
        )
      ],
    );
  }
}
