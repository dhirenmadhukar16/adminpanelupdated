import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class GarmentsScreen extends StatefulWidget {
  const GarmentsScreen({super.key});

  @override
  State<GarmentsScreen> createState() => _GarmentsScreenState();
}

class _GarmentsScreenState extends State<GarmentsScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get(
        '/api/admin-panel/garments/stats',
      );

      setState(() {
        stats = Map<String, dynamic>.from(response.data);
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String v(String key) => '${stats[key] ?? 0}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Garments',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadStats, icon: const Icon(Icons.refresh)),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _card('Total Garments', v('totalGarments'),
                          Icons.checkroom),
                      _card('At Store', v('atStore'), Icons.storefront),
                      _card('Sent To HQ', v('sentToHq'), Icons.local_shipping),
                      _card('Received At HQ', v('receivedAtHq'), Icons.factory),
                      _card(
                        'Washing / Processing',
                        v('washing'),
                        Icons.local_laundry_service,
                      ),
                      _card('Ironing', v('ironing'), Icons.iron),
                      _card('Packing', v('packing'), Icons.inventory_2),
                      _card('Ready', v('ready'), Icons.check_circle),
                      _card('Delivered', v('delivered'), Icons.done_all),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.25),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
