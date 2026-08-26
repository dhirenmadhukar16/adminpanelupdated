import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'add_edit_rider_screen.dart';
import 'rider_detail_screen.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  bool loading = true;
  String? error;
  List riders = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadRiders();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadRiders(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadRiders({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          loading = true;
          error = null;
        });
      }

      final response = await ApiClient.dio.get('/api/admin-panel/riders/stats');

      if (mounted) {
        setState(() {
          riders = response.data as List;
          error = null;
        });
      }
    } catch (e) {
      if (showLoading && mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (showLoading && mounted) setState(() => loading = false);
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'BUSY':
      case 'ON_PICKUP':
      case 'ON_DELIVERY':
        return Colors.orange;
      case 'OFFLINE':
        return Colors.grey;
      case 'PENDING_APPROVAL':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    if (error != null)
      return Center(
          child: Text(error!, style: const TextStyle(color: AppTheme.error)));

    final activeRiders =
        riders.where((r) => r['status'] != 'PENDING_APPROVAL').toList();
    final pendingRiders =
        riders.where((r) => r['status'] == 'PENDING_APPROVAL').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live Fleet Tracking',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.navy,
                          fontWeight: FontWeight.bold)),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Active Fleet'),
                          Tab(text: 'Pending Approvals'),
                        ],
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.mutedText,
                        indicatorColor: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGrid(activeRiders, false),
                    _buildGrid(pendingRiders, true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List riderList, bool isPending) {
    if (riderList.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending approvals' : 'No active riders',
          style: const TextStyle(color: AppTheme.mutedText, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.4,
      ),
      itemCount: riderList.length,
      itemBuilder: (context, index) {
        final r = riderList[index];
        final status = r['status']?.toString();
        final todayDistanceKm =
            (r['todayDistanceKm'] as num?)?.toDouble() ?? 0.0;
        final totalDistanceKm =
            (r['totalDistanceKm'] as num?)?.toDouble() ?? todayDistanceKm;
        final isOnline = status == 'AVAILABLE' ||
            status == 'ON_PICKUP' ||
            status == 'ON_DELIVERY';

        return InkWell(
          onTap: () {
            if (!isPending) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RiderDetailScreen(riderId: r['riderId'] ?? r['id']),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              statusColor(status).withValues(alpha: 0.1),
                          child: Icon(Icons.delivery_dining,
                              color: statusColor(status)),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppTheme.success
                                  : AppTheme.mutedText,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['riderName'] ?? 'Rider',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            r['storeName'] ?? 'No Store Assigned',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            status ?? 'UNKNOWN',
                            style: TextStyle(
                                fontSize: 12,
                                color: statusColor(status),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (!isPending)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditRiderScreen(
                                    rider: r,
                                    onSaved: () => loadRiders()),
                              ),
                            );
                          } else if (value == 'deactivate') {
                            try {
                              await ApiClient.dio
                                  .patch('/api/admin/riders//deactivate');
                              loadRiders();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ')));
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit Profile')),
                          const PopupMenuItem(
                              value: 'deactivate',
                              child: Text('Deactivate',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isPending) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _telemetryWidget(Icons.battery_charging_full, '86%'),
                      _telemetryWidget(
                          Icons.speed, isOnline ? '24 km/h' : '0 km/h'),
                      _telemetryWidget(
                        Icons.route,
                        '${totalDistanceKm.toStringAsFixed(2)} km',
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(' Deliveries',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w600)),
                      Text(' Pickups',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w600)),
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.primaryLight),
                    ],
                  ),
                ] else ...[
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showApproveDialog(r),
                      child: const Text('Approve & Assign Store'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showApproveDialog(Map rider) async {
    try {
      final res = await ApiClient.dio.get('/api/admin-panel/stores/stats');
      final stores = res.data as List;
      if (!mounted) return;

      String? selectedStoreId = stores.isNotEmpty ? stores.first['id'] : null;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Approve Rider'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign  to a store:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStoreId,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: stores
                      .map((s) => DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['name'] ?? 'Unknown Store'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedStoreId = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStoreId == null) return;
                  Navigator.pop(context);
                  try {
                    await ApiClient.dio.patch(
                        '/api/admin-panel/riders//approve',
                        data: {'storeId': selectedStoreId});
                    loadRiders();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error approving: ')));
                  }
                },
                child: const Text('Approve'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading stores: ')));
    }
  }

  Widget _telemetryWidget(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedText),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
