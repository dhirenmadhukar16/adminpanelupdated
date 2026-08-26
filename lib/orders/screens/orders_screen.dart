import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool loading = true;
  String? error;
  List orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-panel/orders');

      setState(() {
        orders = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color statusColor(String? status) {
    if (status == 'DELIVERED') return Colors.green;
    if (status == 'CANCELLED') return Colors.red;
    if (status == 'OUT_FOR_DELIVERY') return Colors.orange;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadOrders, icon: const Icon(Icons.refresh)),
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
              : orders.isEmpty
                  ? const Center(
                      child: Text("No orders found.",
                          style: TextStyle(color: AppTheme.mutedText)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final o = orders[index];
                          final status = o['status']?.toString();

                          return Card(
                            color: status == 'DELIVERED'
                                ? const Color(0xFFECFDF5)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: status == 'DELIVERED'
                                    ? Colors.green.shade400
                                    : Colors.transparent,
                                width: status == 'DELIVERED' ? 1.5 : 0,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    statusColor(status).withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: statusColor(status),
                                ),
                              ),
                              title: Text(
                                o['orderNumber'] ?? 'Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'DELIVERED'
                                      ? Colors.green.shade900
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                  '${o['customerName'] ?? ''} • ${o['storeName'] ?? ''}'),
                              trailing: status == 'DELIVERED'
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : Chip(
                                      label: Text(
                                        status ?? 'UNKNOWN',
                                        style: TextStyle(
                                            color: statusColor(status),
                                            fontSize: 10),
                                      ),
                                      backgroundColor: statusColor(status)
                                          .withValues(alpha: 0.1),
                                      side: BorderSide.none,
                                    ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailScreen(order: o)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
