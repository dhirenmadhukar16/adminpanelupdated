import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiderDetailScreen extends StatefulWidget {
  final String riderId;

  const RiderDetailScreen({super.key, required this.riderId});

  @override
  State<RiderDetailScreen> createState() => _RiderDetailScreenState();
}

class _RiderDetailScreenState extends State<RiderDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? riderData;

  @override
  void initState() {
    super.initState();
    loadRiderDetails();
  }

  Future<void> loadRiderDetails() async {
    try {
      final response =
          await ApiClient.dio.get('/api/admin-panel/riders/${widget.riderId}');
      setState(() {
        riderData = response.data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final passwordController = TextEditingController();

    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Rider Password'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter new password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, passwordController.text);
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (newPassword != null && mounted) {
      try {
        await ApiClient.dio.patch(
          '/api/admin-panel/riders/${widget.riderId}/reset-password',
          data: {'newPassword': newPassword},
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to reset password: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: loadRiderDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final r = riderData!;
    final lat = r['latitude'] as double?;
    final lng = r['longitude'] as double?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(r['riderName'] ?? 'Rider Details',
            style: const TextStyle(
                color: AppTheme.navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppTheme.mutedText),
              onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['riderName'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${r['riderCode'] ?? 'N/A'} • Status: ${r['status'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vehicle: ${r['vehicleNumber'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Login ID & Contact
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                      Icons.email, 'Login ID', r['loginEmail'] ?? 'Not set'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(Icons.phone, 'Phone', r['phone'] ?? 'N/A'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(Icons.local_shipping, 'Total Deliveries',
                      '${r['totalDeliveries'] ?? 0}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(Icons.shopping_bag, 'Total Pickups',
                      '${r['totalPickups'] ?? 0}'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Map and History Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Location Map
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (lat != null && lng != null)
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 14.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.motorcycle,
                                      color: AppTheme.primary,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Center(
                            child: Text('Location not available',
                                style: TextStyle(color: Colors.grey))),
                  ),
                ),

                const SizedBox(width: 24),

                // History List
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 400,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Activity',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: (r['recentActivity'] as List).isEmpty
                              ? const Center(
                                  child: Text('No recent activity',
                                      style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount:
                                      (r['recentActivity'] as List).length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        (r['recentActivity'] as List)[index];
                                    return ListTile(
                                      leading: const Icon(Icons.history,
                                          color: AppTheme.primary),
                                      title: Text(item.toString()),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
