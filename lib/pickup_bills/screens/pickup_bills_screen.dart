import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class PickupBillsScreen extends StatefulWidget {
  const PickupBillsScreen({super.key});

  @override
  State<PickupBillsScreen> createState() => _PickupBillsScreenState();
}

class _PickupBillsScreenState extends State<PickupBillsScreen> {
  bool loading = true;
  String? error;
  List pickupBills = [];

  @override
  void initState() {
    super.initState();
    loadPickupBills();
  }

  Future<void> loadPickupBills() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-panel/pickup-bills');

      setState(() {
        pickupBills = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color statusColor(String? status) {
    if (status == 'VERIFIED_BY_STORE') return Colors.green;
    if (status == 'SENT_TO_STORE_FOR_VERIFICATION') return Colors.orange;
    if (status == 'CONVERTED_TO_ORDER') return Colors.blue;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Pickup Bills',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: loadPickupBills,
            icon: const Icon(Icons.refresh),
          ),
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
                    itemCount: pickupBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final b = pickupBills[index];
                      final status = b['status']?.toString();

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                statusColor(status).withValues(alpha: 0.15),
                            child: Icon(
                              Icons.assignment,
                              color: statusColor(status),
                            ),
                          ),
                          title: Text(
                            b['billNumber'] ?? 'Pickup Bill',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${b['customerName'] ?? ''} | Rider: ${b['riderName'] ?? ''}\nStore: ${b['storeName'] ?? ''}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${b['totalAmount'] ?? 0}',
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
