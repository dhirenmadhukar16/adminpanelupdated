import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final truckTripsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, truckId) async {
  try {
    final res =
        await ApiClient.dio.get('/api/truck-logistics/trucks/$truckId/trips');
    return res.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final tripGarmentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, tripId) async {
  try {
    final res =
        await ApiClient.dio.get('/api/truck-logistics/trips/$tripId/garments');
    return res.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminTruckDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> truck;

  const AdminTruckDetailsScreen({super.key, required this.truck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckId = truck['id'] ?? '';
    final tripsAsync = ref.watch(truckTripsProvider(truckId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(truck['truckNumber'] ?? 'Truck Details',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDriverProfileCard(context),
            const SizedBox(height: 24),
            const Text('Live Location',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy)),
            const SizedBox(height: 12),
            _buildLiveMap(),
            const SizedBox(height: 24),
            const Text('Trip History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy)),
            const SizedBox(height: 12),
            tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load trips: $e'),
              data: (trips) {
                if (trips.isEmpty) {
                  return const Text('No trips recorded for this truck yet.',
                      style: TextStyle(color: AppTheme.mutedText));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: ExpansionTile(
                        leading:
                            const Icon(Icons.route, color: AppTheme.primary),
                        title: Text(
                            'Trip ${trip['id'].toString().substring(0, 8)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${trip['status']}'),
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final garmentsAsync =
                                  ref.watch(tripGarmentsProvider(trip['id']));
                              return garmentsAsync.when(
                                loading: () => const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator()),
                                error: (e, _) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text('Failed to load garments: $e')),
                                data: (garments) {
                                  if (garments.isEmpty) {
                                    return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                            'No garments loaded on this trip.'));
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: garments.length,
                                    itemBuilder: (context, gIndex) {
                                      final g = garments[gIndex];
                                      return ListTile(
                                        leading: const Icon(Icons.checkroom,
                                            color: AppTheme.primary),
                                        title: Text(
                                            g['itemName'] ?? 'Unknown Item'),
                                        subtitle: Text(
                                            '${g['storeName']} • ${g['status']}'),
                                        trailing: Text(g['storeQrCode'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Driver Profile Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppTheme.primary, size: 35),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(truck['driverName'] ?? 'Unknown Driver',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(truck['truckNumber'] ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMap() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(28.7041, 77.1025), // Mock position (Delhi)
          zoom: 12,
        ),
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
