import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'marketing_campaign_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool loading = true;
  String? error;
  List customers = [];
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      setState(() {
        loading = true;
        error = null;
        selectedIds.clear();
      });

      final response = await ApiClient.dio.get(
        '/api/admin-panel/customers/stats',
      );

      setState(() {
        customers = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedIds.length == customers.length) {
        selectedIds.clear();
      } else {
        selectedIds = customers.map((c) => c['id'].toString()).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    if (error != null)
      return Center(
          child: Text(error!, style: const TextStyle(color: AppTheme.error)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer Relationship Management',
                    style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold)),
                if (customers.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _selectAll,
                    icon: Icon(
                      selectedIds.length == customers.length
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(selectedIds.length == customers.length
                        ? 'Deselect All'
                        : 'Select All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.navy,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 1.3,
                ),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final c = customers[index];
                  final id = c['id']?.toString() ?? '';
                  final isSelected = selectedIds.contains(id);

                  return InkWell(
                    onTap: () => _toggleSelection(id),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.primaryLight
                                        .withValues(alpha: 0.1),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white)
                                    : Text(
                                        (c['customerName'] ?? 'C')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['customerName'] ?? 'Customer',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      c['phone'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mutedText),
                                    ),
                                    Text(
                                      c['email'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mutedText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _kpiMini('Orders', '${c['totalOrders'] ?? 0}'),
                              _kpiMini(
                                  'Bookings', '${c['totalBookings'] ?? 0}'),
                              _kpiMini('LTV Spend', '₹${c['totalSpend'] ?? 0}',
                                  highlight: true),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarketingCampaignScreen(
                        customerIds: selectedIds.toList()),
                  ),
                );
              },
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.campaign, color: Colors.white),
              label: Text('Send Campaign (${selectedIds.length})',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _kpiMini(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: highlight ? AppTheme.primary : AppTheme.navy,
          ),
        ),
      ],
    );
  }
}
