import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await ApiClient.dio.get('/api/admin-panel/orders');

      final loadedOrders = (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        orders = loadedOrders;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> openOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID is missing. Please refresh and try again.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: orderId),
      ),
    );

    if (mounted) await loadOrders();
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
          IconButton(
            onPressed: loading ? null : loadOrders,
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders found.',
                        style: TextStyle(color: AppTheme.mutedText),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final order = orders[index];
                          final status = order['status']?.toString();
                          final delivered = status == 'DELIVERED';

                          return Card(
                            color: delivered ? const Color(0xFFECFDF5) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: delivered
                                    ? Colors.green.shade400
                                    : Colors.transparent,
                                width: delivered ? 1.5 : 0,
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
                                order['orderNumber']?.toString() ?? 'Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: delivered
                                      ? Colors.green.shade900
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${order['customerName'] ?? ''} • '
                                '${order['storeName'] ?? ''}',
                              ),
                              trailing: delivered
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : Chip(
                                      label: Text(
                                        status ?? 'UNKNOWN',
                                        style: TextStyle(
                                          color: statusColor(status),
                                          fontSize: 10,
                                        ),
                                      ),
                                      backgroundColor: statusColor(status)
                                          .withValues(alpha: 0.1),
                                      side: BorderSide.none,
                                    ),
                              onTap: () => openOrder(order),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
