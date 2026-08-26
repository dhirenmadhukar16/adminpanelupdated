import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class HqScreen extends StatefulWidget {
  const HqScreen({super.key});

  @override
  State<HqScreen> createState() => _HqScreenState();
}

class _HqScreenState extends State<HqScreen> {
  bool loading = true;
  String? error;

  List delayed = [];
  List todayDispatch = [];
  List tomorrowDispatch = [];

  @override
  void initState() {
    super.initState();
    loadHq();
  }

  Future<void> loadHq() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final delayedRes = await ApiClient.dio.get('/api/hq/garments/delayed');
      final todayRes = await ApiClient.dio.get('/api/hq/dispatch/today');
      final tomorrowRes = await ApiClient.dio.get('/api/hq/dispatch/tomorrow');

      setState(() {
        delayed = delayedRes.data as List;
        todayDispatch = todayRes.data as List;
        tomorrowDispatch = tomorrowRes.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'HQ Operations',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadHq, icon: const Icon(Icons.refresh)),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _summaryCard(
                            'Delayed Garments',
                            delayed.length.toString(),
                            Icons.warning_amber,
                            Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _summaryCard(
                            'Today Dispatch',
                            todayDispatch.length.toString(),
                            Icons.today,
                            AppTheme.primary,
                          ),
                          const SizedBox(width: 16),
                          _summaryCard(
                            'Tomorrow Dispatch',
                            tomorrowDispatch.length.toString(),
                            Icons.event,
                            Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _section('Delayed Garments', delayed),
                      const SizedBox(height: 24),
                      _section('Today Dispatch', todayDispatch),
                      const SizedBox(height: 24),
                      _section('Tomorrow Dispatch', tomorrowDispatch),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(title, style: const TextStyle(color: AppTheme.mutedText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No data found'),
              )
            else
              ...items.map((g) {
                return ListTile(
                  leading: const Icon(Icons.checkroom, color: AppTheme.primary),
                  title: Text(g['itemName'] ?? 'Garment'),
                  subtitle: Text(
                    'Order: ${g['orderNumber'] ?? ''} | Store: ${g['storeName'] ?? ''}\n'
                    'Service: ${g['serviceType'] ?? ''} | Status: ${g['status'] ?? ''}',
                  ),
                  trailing: Text(g['outingQrCode'] ?? g['storeQrCode'] ?? ''),
                );
              }),
          ],
        ),
      ),
    );
  }
}
