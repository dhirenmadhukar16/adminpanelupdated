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
                          subtitle: Text(
                            '${b['customerPhone'] ?? ''}\n${b['pickupDate'] ?? ''} | ${b['pickupTimeSlot'] ?? ''}\nStore: ${b['storeName'] ?? 'Not assigned'} | Rider: ${b['riderName'] ?? 'Not assigned'}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${b['estimatedAmount'] ?? 0}',
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
