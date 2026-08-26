import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'add_truck_driver_screen.dart';
import 'admin_truck_details_screen.dart';

final adminTrucksProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.dio.get('/api/truck-logistics/trucks');
    return res.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminTrucksScreen extends ConsumerWidget {
  const AdminTrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trucksAsync = ref.watch(adminTrucksProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Truck Fleet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: () => ref.refresh(adminTrucksProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTruckDriverScreen()));
          if (added == true) {
            ref.refresh(adminTrucksProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Truck & Driver', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: trucksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trucks) {
          if (trucks.isEmpty) {
            return const Center(
              child: Text('No trucks found. Add a truck to begin.', style: TextStyle(color: AppTheme.mutedText)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminTrucksProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: trucks.length,
              itemBuilder: (context, index) {
                final truck = trucks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTruckDetailsScreen(truck: truck)));
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.local_shipping, color: AppTheme.primary, size: 32),
                      title: Text(truck['truckNumber'] ?? 'Unknown Truck', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Driver: ${truck['driverName'] ?? 'Unassigned'} • Phone: ${truck['driverPhone'] ?? 'N/A'}'),
                      trailing: Chip(
                        label: Text(truck['status'] ?? 'UNKNOWN', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: truck['status'] == 'AVAILABLE' ? Colors.green : (truck['status'] == 'ON_TRIP' ? Colors.orange : Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
