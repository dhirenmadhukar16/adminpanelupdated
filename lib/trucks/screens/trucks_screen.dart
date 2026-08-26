import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class TrucksScreen extends StatefulWidget {
  const TrucksScreen({super.key});

  @override
  State<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends State<TrucksScreen> {
  bool loading = true;
  String? error;

  Map<String, dynamic> stats = {};
  List liveTrucks = [];

  @override
  void initState() {
    super.initState();
    loadTrucks();
  }

  Future<void> loadTrucks() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final statsRes = await ApiClient.dio.get('/api/admin-panel/trucks/stats');
      final liveRes = await ApiClient.dio.get(
        '/api/truck-logistics/trucks/live',
      );

      setState(() {
        stats = Map<String, dynamic>.from(statsRes.data);
        liveTrucks = liveRes.data as List;
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
          'Truck Logistics',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadTrucks, icon: const Icon(Icons.refresh)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _card(
                            'Total Trucks',
                            v('totalTrucks'),
                            Icons.local_shipping,
                          ),
                          _card(
                            'Available',
                            v('availableTrucks'),
                            Icons.check_circle,
                          ),
                          _card('On Trip', v('onTripTrucks'), Icons.route),
                          _card('Maintenance', v('maintenanceTrucks'),
                              Icons.build),
                          _card('Total Trips', v('totalTrips'), Icons.map),
                          _card('Active Trips', v('activeTrips'),
                              Icons.timelapse),
                          _card(
                            'Completed Trips',
                            v('completedTrips'),
                            Icons.done_all,
                          ),
                          _card(
                            'Manifests',
                            v('totalManifests'),
                            Icons.inventory_2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Live Trucks',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      ...liveTrucks.map((t) {
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.primaryLight,
                              child: Icon(
                                Icons.local_shipping,
                                color: AppTheme.primary,
                              ),
                            ),
                            title: Text(
                              t['truckNumber'] ?? 'Truck',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              'Driver: ${t['driverName'] ?? ''} | ${t['driverPhone'] ?? ''}\n'
                              'Trip: ${t['tripNumber'] ?? 'No active trip'} | '
                              'Location: ${t['latitude'] ?? '-'}, ${t['longitude'] ?? '-'}',
                            ),
                            trailing:
                                Chip(label: Text(t['status'] ?? 'UNKNOWN')),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      width: 240,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(title, style: const TextStyle(color: AppTheme.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
