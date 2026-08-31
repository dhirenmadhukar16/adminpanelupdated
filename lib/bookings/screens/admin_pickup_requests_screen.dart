import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminPickupRequestsScreen extends StatefulWidget {
  const AdminPickupRequestsScreen({super.key});

  @override
  State<AdminPickupRequestsScreen> createState() => _AdminPickupRequestsScreenState();
}

class _AdminPickupRequestsScreenState extends State<AdminPickupRequestsScreen> {
  bool loading = true;
  String? error;
  List requests = [];
  List stores = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final futures = await Future.wait([
        ApiClient.dio.get('/api/customer-bookings/unassigned'),
        ApiClient.dio.get('/api/admin/stores'),
      ]);

      setState(() {
        requests = futures[0].data as List;
        stores = futures[1].data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> assignStore(String bookingId, String storeId) async {
    try {
      await ApiClient.dio.patch('/api/customer-bookings/$bookingId/assign-store', data: {
        'storeId': storeId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store assigned successfully')),
      );
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign store: $e')),
      );
    }
  }

  String formatAmount(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  Color paymentStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _showAssignDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign to Store'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return ListTile(
                  leading: const Icon(Icons.storefront, color: AppTheme.primary),
                  title: Text(store['name'] ?? ''),
                  subtitle: Text(store['address'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    assignStore(bookingId, store['id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Pickup Requests',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : requests.isEmpty
                  ? const Center(child: Text('No unassigned pickup requests.'))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final r = requests[index];
                          final id = r['id']?.toString() ?? '';
                          final paymentStatus =
                              r['paymentStatus']?.toString() ?? 'UNPAID';
                          final paymentColor =
                              paymentStatusColor(paymentStatus);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppTheme.surface,
                                    radius: 24,
                                    child: Icon(Icons.shopping_basket_rounded, color: AppTheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['customerName'] ?? 'Customer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Date: ${r['pickupDate']} | Time: ${r['pickupTimeSlot']}'),
                                        Text('Address: ${r['pickupAddress']}'),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: paymentColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                paymentStatus.replaceAll(
                                                  '_',
                                                  ' ',
                                                ),
                                                style: TextStyle(
                                                  color: paymentColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Received: ${formatAmount(r['amountPaid'])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Mode: ${(r['paymentMode'] ?? 'Not selected').toString().replaceAll('_', ' ')}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (r['specialInstructions'] != null && r['specialInstructions'].toString().isNotEmpty)
                                          Text('Note: ${r['specialInstructions']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Est: ${formatAmount(r['estimatedAmount'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAssignDialog(id),
                                        icon: const Icon(Icons.assignment_ind),
                                        label: const Text('Assign Store'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
