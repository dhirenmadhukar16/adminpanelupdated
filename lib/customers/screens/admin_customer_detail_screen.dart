import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const AdminCustomerDetailScreen({super.key, required this.customer});

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Customer Profile',
            style:
                TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.navy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryLight,
                    child:
                        Icon(Icons.person, size: 40, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer['name'] ?? 'Unknown Customer',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy)),
                        const SizedBox(height: 8),
                        Text(widget.customer['email'] ?? 'No email',
                            style: const TextStyle(color: AppTheme.mutedText)),
                        Text(widget.customer['phone'] ?? 'No phone',
                            style: const TextStyle(color: AppTheme.mutedText)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showSpecialOfferDialog(context);
                    },
                    icon: const Icon(Icons.local_offer, size: 18),
                    label: const Text('Send Special Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FutureBuilder for history
            FutureBuilder<dynamic>(
              future: ApiClient.dio
                  .get('/api/admin/customers/${widget.customer['id']}/orders')
                  .then((r) => r.data),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red))));
                }

                final data = snapshot.data as Map<String, dynamic>? ?? {};
                final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
                final onlineOrders =
                    data['onlineOrders'] as List<dynamic>? ?? [];
                final walkInOrders =
                    data['walkInOrders'] as List<dynamic>? ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Combined Metrics Row
                    Row(
                      children: [
                        Expanded(
                            child: _buildMetricCard(
                                'Total Orders (Combined)',
                                '${metrics['totalOrders'] ?? widget.customer['totalOrders'] ?? 0}',
                                Icons.shopping_bag,
                                Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildMetricCard(
                                'Total Spent (Combined)',
                                '₹${metrics['totalSpent'] ?? widget.customer['lifetimeValue'] ?? 0}',
                                Icons.account_balance_wallet,
                                Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildMetricCard(
                                'Reward Points',
                                '${metrics['rewardPoints'] ?? widget.customer['rewardPoints'] ?? 0}',
                                Icons.star,
                                Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Separated Metrics Row
                    Row(
                      children: [
                        Expanded(
                            child: _buildSmallMetricCard(
                                'Online Orders',
                                '${metrics['totalOnlineOrders'] ?? 0}',
                                Colors.blueAccent)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSmallMetricCard(
                                'Walk-in Orders',
                                '${metrics['totalWalkInOrders'] ?? 0}',
                                Colors.purpleAccent)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSmallMetricCard(
                                'Online Spent',
                                '₹${metrics['totalOnlineSpent'] ?? 0}',
                                Colors.teal)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSmallMetricCard(
                                'Walk-in Spent',
                                '₹${metrics['totalWalkInSpent'] ?? 0}',
                                Colors.indigo)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Order History section
                    const Text('Order History',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy)),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: AppTheme.mutedText,
                            indicatorColor: AppTheme.primary,
                            tabs: const [
                              Tab(text: 'Online Orders'),
                              Tab(text: 'Walk-in Orders'),
                            ],
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: 400, // Fixed height for tab content
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOrderList(onlineOrders, 'Online'),
                                _buildOrderList(walkInOrders, 'Walk-in'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String type) {
    if (orders.isEmpty) {
      return Center(child: Text('No $type orders found.'));
    }
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        final order = orders[index];
        final createdAtStr = order['createdAt'];
        String dateStr = 'Unknown';
        if (createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr);
            dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
          } catch (_) {}
        }

        final id = (order['orderNumber'] ?? order['id'].toString()).toString();
        final displayId =
            id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
        final amount = order['estimatedAmount'] ?? order['totalAmount'] ?? 0;

        return _buildOrderRow(
            displayId, dateStr, order['status'] ?? 'Unknown', '₹$amount');
      },
    );
  }

  Widget _buildOrderRow(String id, String date, String status, String amount) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.receipt_long, color: AppTheme.primary),
      ),
      title: Text(id,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.navy)),
      subtitle: Text(date, style: const TextStyle(color: AppTheme.mutedText)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16)),
          Text(status,
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSpecialOfferDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Send Special Offer'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      decoration: InputDecoration(
                          labelText: 'Offer Title (e.g. 20% Off)',
                          border: OutlineInputBorder())),
                  SizedBox(height: 16),
                  TextField(
                      decoration: InputDecoration(
                          labelText: 'Message Body',
                          border: OutlineInputBorder()),
                      maxLines: 3),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Offer sent successfully!')));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white),
                    child: const Text('Send via SMS/Email')),
              ],
            ));
  }
}
