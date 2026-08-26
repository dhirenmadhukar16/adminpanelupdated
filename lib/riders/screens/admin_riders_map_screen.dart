import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'add_edit_rider_screen.dart';
import 'rider_detail_screen.dart';

// Provider for Live Riders
final liveRidersProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/riders/stats');
    return response.data as List<dynamic>;
  } catch (e) {
    print('Error fetching riders: $e');
    return [];
  }
});

class AdminRidersMapScreen extends ConsumerStatefulWidget {
  const AdminRidersMapScreen({super.key});

  @override
  ConsumerState<AdminRidersMapScreen> createState() =>
      _AdminRidersMapScreenState();
}

class _AdminRidersMapScreenState extends ConsumerState<AdminRidersMapScreen> {
  StompClient? stompClient;
  Map<String, Map<String, double>> liveLocations = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initStomp();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(liveRidersProvider),
    );
  }

  void _initStomp() {
    stompClient = StompClient(
      config: StompConfig(
        // url: 'wss://https://whitefoxbackendpro.onrender.com/ws-whitefox/websocket',
        url: 'wss://whitefoxbackendpro.onrender.com/ws-whitefox/websocket',
        onConnect: (StompFrame frame) {
          stompClient?.subscribe(
            destination: '/topic/location',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = json.decode(frame.body!);
                if (mounted) {
                  setState(() {
                    liveLocations[data['entityId'].toString()] = {
                      'latitude': (data['latitude'] as num).toDouble(),
                      'longitude': (data['longitude'] as num).toDouble(),
                    };
                  });
                }
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => print(error.toString()),
      ),
    );
    stompClient?.activate();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    stompClient?.deactivate();
    super.dispose();
  }

  String _riderId(dynamic rider) =>
      (rider['riderId'] ?? rider['id'] ?? '').toString();

  String _riderName(dynamic rider) =>
      (rider['riderName'] ?? rider['name'] ?? 'Unknown').toString();

  double _distance(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(liveRidersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar for Rider List
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fleet Live Tracking',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.navy)),
                      IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppTheme.mutedText),
                          onPressed: () => ref.invalidate(liveRidersProvider)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: AppTheme.primaryLight.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ridersAsync.value?.length ?? 0} Total',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy)),
                      Text(
                          '${ridersAsync.value?.where((r) => r['status'] != 'OFFLINE').length ?? 0} Online',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                Expanded(
                  child: ridersAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                          child: Text('Error: $err',
                              style: const TextStyle(color: Colors.red))),
                      data: (riders) {
                        return ListView.separated(
                          itemCount: riders.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            final r = riders[index];
                            final status = r['status'] ?? 'OFFLINE';
                            final isOnline = status != 'OFFLINE';
                            final todayDistanceKm =
                                _distance(r['todayDistanceKm']);
                            final totalDistanceKm =
                                _distance(r['totalDistanceKm']);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              leading: Stack(
                                children: [
                                  const CircleAvatar(
                                      backgroundColor: AppTheme.primary,
                                      child: Icon(Icons.person,
                                          color: Colors.white)),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                          color: isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2)),
                                    ),
                                  )
                                ],
                              ),
                              title: Text(_riderName(r),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.navy,
                                      fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(r['riderCode'] ?? _riderId(r),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mutedText)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.route_rounded,
                                          size: 13, color: AppTheme.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Today: ${todayDistanceKm.toStringAsFixed(2)} km',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.mutedText,
                                              ),
                                            ),
                                            Text(
                                              'Total: ${totalDistanceKm.toStringAsFixed(2)} km',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.navy,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isOnline &&
                                      (status == 'ON_PICKUP' ||
                                          status == 'ON_DELIVERY'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delivery_dining,
                                              size: 12,
                                              color: AppTheme.primary),
                                          const SizedBox(width: 4),
                                          Text('Status: $status',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.mutedText),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RiderDetailScreen(riderId: _riderId(r)),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }),
                ),
              ],
            ),
          ),
          // Main Map Area
          Expanded(
            child: Stack(
              children: [
                // In a real app, this would be a GoogleMap widget.
                // Since this is a web/desktop Flutter port that might not have maps configured yet, we will use a visual placeholder that mimics a map.
                Container(
                  color: const Color(
                      0xFFF1F5F9), // Map background color placeholder
                  child: Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    opacity: const AlwaysStoppedAnimation(.2),
                  ),
                ),

                // Overlaying mock map markers
                ridersAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (riders) {
                      return Stack(
                        children: riders.map<Widget>((r) {
                          final status = r['status'] ?? 'OFFLINE';
                          final isOnline = status != 'OFFLINE';
                          if (!isOnline) return const SizedBox();

                          // Mock positions for demo if real coordinates are null, overridden by live locations
                          double lat = r['latitude'] ?? 19.0760;
                          double lng = r['longitude'] ?? 72.8777;

                          final live = liveLocations[_riderId(r)];
                          if (live != null) {
                            lat = live['latitude']!;
                            lng = live['longitude']!;
                          }

                          double top = (lat - 19.0) * 1000;
                          double left = (lng - 72.8) * 1000;

                          return Positioned(
                            top: top.clamp(100, 800),
                            left: left.clamp(100, 800),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4)
                                      ]),
                                  child: Text(_riderName(r),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                                const Icon(Icons.location_on,
                                    color: AppTheme.primary, size: 32),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),

                // Map controls
                Positioned(
                  top: 24,
                  right: 24,
                  child: Column(
                    children: [
                      _buildMapButton(Icons.add),
                      const SizedBox(height: 8),
                      _buildMapButton(Icons.remove),
                      const SizedBox(height: 8),
                      _buildMapButton(Icons.my_location),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppTheme.softShadow),
      child:
          IconButton(icon: Icon(icon, color: AppTheme.navy), onPressed: () {}),
    );
  }
}
