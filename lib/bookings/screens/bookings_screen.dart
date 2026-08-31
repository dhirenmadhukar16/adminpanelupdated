import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool loading = true;
  String? error;
  List bookings = [];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-panel/bookings');

      setState(() {
        bookings = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color statusColor(String? status) {
    if (status == 'REQUESTED') return Colors.orange;
    if (status == 'RIDER_ASSIGNED') return Colors.blue;
    if (status == 'PICKUP_BILL_CREATED') return Colors.green;
    if (status == 'CANCELLED') return Colors.red;
    return AppTheme.primary;
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

  String formatAmount(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String formatPaymentMode(dynamic value) {
    final mode = value?.toString().trim() ?? '';
    if (mode.isEmpty) return 'Not selected';
    return mode.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Bookings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadBookings, icon: const Icon(Icons.refresh)),
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
                  child: ListView.separated(
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final b = bookings[index];
                      final status = b['status']?.toString();
                      final paymentStatus =
                          b['paymentStatus']?.toString() ?? 'UNPAID';
                      final paymentColor =
                          paymentStatusColor(paymentStatus);

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                statusColor(status).withValues(alpha: 0.15),
                            child: Icon(
                              Icons.calendar_month,
                              color: statusColor(status),
                            ),
                          ),
                          title: Text(
                            b['customerName'] ?? 'Customer Booking',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b['customerPhone'] ?? ''}\n'
                                  '${b['pickupDate'] ?? ''} | ${b['pickupTimeSlot'] ?? ''}\n'
                                  'Store: ${b['storeName'] ?? 'Not assigned'} | '
                                  'Rider: ${b['riderName'] ?? 'Not assigned'}',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: paymentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        paymentStatus.replaceAll('_', ' '),
                                        style: TextStyle(
                                          color: paymentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Received: ${formatAmount(b['amountPaid'])}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Mode: ${formatPaymentMode(b['paymentMode'])}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatAmount(b['estimatedAmount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(status ?? ''),
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
