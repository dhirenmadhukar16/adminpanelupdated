import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'assign_rider_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? orderData;

  @override
  void initState() {
    super.initState();
    loadOrderDetails();
  }

  Future<void> loadOrderDetails() async {
    try {
      final response = await ApiClient.dio.get('/api/orders/${widget.orderId}');
      setState(() {
        orderData = response.data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: loadOrderDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final o = orderData!;
    final customerName = o['customerName'] ?? 'Unknown Customer';
    final customerPhone = o['customerPhone'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Order ${o['orderNumber'] ?? 'Details'}'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Status',
                          style: TextStyle(color: AppTheme.mutedText)),
                      const SizedBox(height: 8),
                      Text(
                        o['status'] ?? 'UNKNOWN',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(color: AppTheme.mutedText)),
                      const SizedBox(height: 8),
                      Text(
                        '\$${o['totalAmount'] ?? '0.00'}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(height: 32),
                        _detailRow(Icons.person, 'Name', customerName),
                        const SizedBox(height: 16),
                        _detailRow(Icons.phone, 'Phone', customerPhone),
                        const SizedBox(height: 16),
                        _detailRow(Icons.location_on, 'Address',
                            o['deliveryAddress'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assignment',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(height: 32),
                        _detailRow(
                            Icons.store, 'Store', o['storeName'] ?? 'N/A'),
                        const SizedBox(height: 16),
                        _detailRow(Icons.delivery_dining, 'Delivery Rider',
                            o['deliveryRiderName'] ?? 'Unassigned'),
                        const SizedBox(height: 24),
                        if (o['status'] != 'DELIVERED' &&
                            o['status'] != 'CANCELLED')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (_) => AssignRiderDialog(
                                      orderId: widget.orderId),
                                );
                                if (result == true) {
                                  loadOrderDetails();
                                }
                              },
                              icon: const Icon(Icons.delivery_dining, size: 20),
                              label: Text(o['deliveryRiderName'] != null
                                  ? 'Reassign Delivery Rider'
                                  : 'Assign Delivery Rider'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Garments / Items List
            if (o['items'] != null && (o['items'] as List).isNotEmpty) ...[
              const Text('Garment Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (o['items'] as List).length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = o['items'][index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      title: Text(
                        item['itemName'] ?? 'Unknown Item',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item['serviceType'] ?? ''} | Qty: ${item['quantity'] ?? 1}',
                      ),
                      trailing: Text(
                        '\$${item['totalPrice'] ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.mutedText, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
