import '../discounts/screens/discount_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitefox_admin_panel/navigation/providers/navigation_provider.dart';

// Import Screens
import '../dashboard/screens/admin_dashboard_screen.dart';
import '../stores/screens/stores_screen.dart';
import '../finance/screens/admin_finance_erp.dart';
import '../warehouse/screens/admin_warehouse_screen.dart';
import '../employees/screens/hr_directory_screen.dart';
import '../employees/screens/hr_directory_screen.dart';
import '../settings/screens/pricing_catalog_screen.dart';
import '../riders/screens/admin_riders_map_screen.dart';
import '../orders/screens/admin_orders_kanban.dart';
import '../customers/screens/admin_customers_crm.dart';
import '../ai/screens/admin_ai_assistant_screen.dart';
import '../core/theme/app_theme.dart';

import '../analytics/screens/admin_analytics_screen.dart';
import '../garments/screens/admin_garments_screen.dart';
import '../trucks/screens/admin_trucks_screen.dart';
import '../employees/screens/admin_payroll_screen.dart';
import '../marketing/screens/admin_marketing_screen.dart';
import '../reports/screens/admin_reports_screen.dart';
import '../settings/screens/admin_roles_screen.dart';
import '../audit/screens/admin_audit_screen.dart';
import '../support/screens/admin_support_screen.dart';
import '../auth/screens/admin_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cashcollection/screens/admin_cash_collection_screen.dart';
import '../bookings/screens/admin_pickup_requests_screen.dart';
import '../orders/screens/admin_daily_orders_screen.dart';
import '../customers/screens/admin_customer_activity_screen.dart';
import '../riders/screens/admin_rider_cash_screen.dart';
import '../packages/screens/admin_packages_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Overview',
      'icon': Icons.dashboard_rounded,
      'screen': const AdminDashboardScreen()
    },
    {
      'title': 'Stores',
      'icon': Icons.storefront_rounded,
      'screen': const StoresScreen()
    },
    {
      'title': 'Customers',
      'icon': Icons.people_alt_rounded,
      'screen': const AdminCustomersCRM()
    },
    {
      'title': 'Store Discounts',
      'icon': Icons.local_offer_outlined,
      'screen': const DiscountHistoryScreen(adminMode: true)
    },
    {
      'title': 'Customer Activity',
      'icon': Icons.insights_rounded,
      'screen': const AdminCustomerActivityScreen()
    },
    {
      'title': 'Riders',
      'icon': Icons.electric_moped_rounded,
      'screen': const AdminRidersMapScreen()
    },
    {
      'title': 'Orders',
      'icon': Icons.receipt_long_rounded,
      'screen': const AdminOrdersKanban()
    },
    {
      'title': 'Daily Orders',
      'icon': Icons.today_rounded,
      'screen': const AdminDailyOrdersScreen()
    },
    {
      'title': 'Services & Pricing',
      'icon': Icons.checkroom_rounded,
      'screen': const AdminGarmentsScreen()
    },
    {
      'title': 'Customer Packages',
      'icon': Icons.inventory_2_rounded,
      'screen': const AdminPackagesScreen()
    },
    {
      'title': 'Trucks',
      'icon': Icons.local_shipping_rounded,
      'screen': const AdminTrucksScreen()
    },
    {
      'title': 'Cash Collection',
      'icon': Icons.payments_rounded,
      'screen': const AdminCashCollectionScreen()
    },
    {
      'title': 'Rider Cash',
      'icon': Icons.account_balance_wallet_rounded,
      'screen': const AdminRiderCashScreen()
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Elegant Dark Navy Sidebar
          Container(
            width: 260,
            color: const Color(0xFF0F172A), // Deep Navy from UI
            child: Column(
              children: [
                // Header Logo
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.dry_cleaning,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WhiteFox',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text('Admin Panel',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Menu
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => ref
                                .read(navigationIndexProvider.notifier)
                                .setIndex(index),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.5))
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 20,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Profile Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('Super Admin',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout,
                            color: Colors.white54, size: 20),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminLoginScreen()),
                            );
                          }
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _menuItems[selectedIndex]['screen'] as Widget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text('$title Module Coming Soon',
            style: const TextStyle(fontSize: 24, color: AppTheme.mutedText)),
      ),
    );
  }
}
