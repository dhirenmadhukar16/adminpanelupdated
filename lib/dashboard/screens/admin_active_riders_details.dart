import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminActiveRidersDetails extends StatefulWidget {
  const AdminActiveRidersDetails({super.key});

  @override
  State<AdminActiveRidersDetails> createState() => _AdminActiveRidersDetailsState();
}

class _AdminActiveRidersDetailsState extends State<AdminActiveRidersDetails> {
  bool loading = true;
  String? error;
  List riders = [];

  @override
  void initState() {
    super.initState();
    loadRiders();
  }

  Future<void> loadRiders() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-panel/riders/stats');

      setState(() {
        riders = response.data as List;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Active Riders & Performance', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.navy),
        elevation: 1,
        actions: [
          IconButton(onPressed: loadRiders, icon: const Icon(Icons.refresh, color: AppTheme.navy)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : riders.isEmpty
          ? const Center(child: Text('No active riders found.', style: TextStyle(color: AppTheme.mutedText)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currently Online Fleet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: riders.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final rider = riders[index];
                        return _buildRiderRow(
                          rider['riderName']?.toString() ?? 'Unknown Rider',
                          rider['overallRides']?.toString() ?? '0',
                          rider['todayRides']?.toString() ?? '0',
                          '₹${rider['tipsEarned'] ?? 0}',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRiderRow(String name, String overallRides, String todayRides, String tips) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leading: const CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryLight,
        child: Icon(Icons.person, color: AppTheme.primary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 16)),
      subtitle: Text('Overall Rides: $overallRides • Today: $todayRides', style: const TextStyle(color: AppTheme.mutedText)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Tips Earned', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
          Text(tips, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
        ],
      ),
    );
  }
}
