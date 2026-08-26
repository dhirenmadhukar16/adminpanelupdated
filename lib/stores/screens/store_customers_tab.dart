import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

final storeCustomersProvider = FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/stores/$storeId/customers');
    return response.data as List<dynamic>;
  } catch (e) {
    print('Error fetching store customers: $e');
    return [];
  }
});

class StoreCustomersTab extends ConsumerStatefulWidget {
  final String storeId;

  const StoreCustomersTab({super.key, required this.storeId});

  @override
  ConsumerState<StoreCustomersTab> createState() => _StoreCustomersTabState();
}

class _StoreCustomersTabState extends ConsumerState<StoreCustomersTab> {
  void _showCustomerHistory(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerHistorySheet(storeId: widget.storeId, customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(storeCustomersProvider(widget.storeId));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Customers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primary), onPressed: () => ref.refresh(storeCustomersProvider(widget.storeId))),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers found for this store.'));
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        onTap: () => _showCustomerHistory(customer),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person, color: AppTheme.primary),
                        ),
                        title: Text(customer['name'] ?? 'Unknown Customer', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                        subtitle: Text('Email:  • Phone: '),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedText),
                      );
                    },
                  ),
                );
              }
            ),
          )
        ],
      ),
    );
  }
}

class _CustomerHistorySheet extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic> customer;
  
  const _CustomerHistorySheet({required this.storeId, required this.customer});

  @override
  State<_CustomerHistorySheet> createState() => _CustomerHistorySheetState();
}

class _CustomerHistorySheetState extends State<_CustomerHistorySheet> {
  List<dynamic> orders = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiClient.dio.get('/api/admin-panel/stores/${widget.storeId}/customers/${widget.customer['id']}/orders');
      if (mounted) {
        setState(() {
          orders = response.data as List<dynamic>;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer['name'] ?? 'Customer',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                      Text(
                        widget.customer['phoneNumber'] ?? '-',
                        style: const TextStyle(color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)))
                    : orders.isEmpty
                        ? const Center(child: Text('No orders found for this customer at this store.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final dateStr = order['createdAt'];
                              final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
                              final formattedDate = date != null ? DateFormat('MMM d, yyyy').format(date) : '-';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order['orderNumber'] ?? 'Unknown Order',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '₹',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text('Status: '),
                                      Text('Date: $formattedDate'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
