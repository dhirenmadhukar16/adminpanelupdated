import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final searchController = TextEditingController();
  bool loading = false;
  String? error;
  List results = [];

  Future<void> search() async {
    final keyword = searchController.text.trim();
    if (keyword.isEmpty) return;

    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get(
        '/api/admin-panel/search',
        queryParameters: {'keyword': keyword},
      );

      setState(() => results = response.data as List);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  IconData iconFor(String? type) {
    switch (type) {
      case 'CUSTOMER':
        return Icons.person;
      case 'RIDER':
        return Icons.delivery_dining;
      case 'STORE':
        return Icons.storefront;
      case 'ORDER':
        return Icons.receipt_long;
      case 'PICKUP_BILL':
        return Icons.assignment;
      case 'GARMENT':
        return Icons.checkroom;
      case 'CUSTOMER_BOOKING':
        return Icons.calendar_month;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Universal Search',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText:
                    'Search customer, order, rider, store, QR, pickup bill...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final r = results[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: Icon(
                          iconFor(r['type']),
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        r['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${r['type'] ?? ''} | ${r['subtitle'] ?? ''}\n${r['extraInfo'] ?? ''}',
                      ),
                      trailing: Chip(label: Text(r['status'] ?? '-')),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
