import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'admin_customer_detail_screen.dart';

final crmProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin/customers');
    return response.data as List<dynamic>;
  } catch (e) {
    print('Error fetching customers: $e');
    return [];
  }
});

class AdminCustomersCRM extends ConsumerStatefulWidget {
  const AdminCustomersCRM({super.key});

  @override
  ConsumerState<AdminCustomersCRM> createState() => _AdminCustomersCRMState();
}

class _AdminCustomersCRMState extends ConsumerState<AdminCustomersCRM> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  List<dynamic> _filterCustomers(List<dynamic> customers) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return customers;

    final digits = query.replaceAll(RegExp(r'\D'), '');
    return customers.where((raw) {
      if (raw is! Map) return false;
      final customer = Map<String, dynamic>.from(raw);

      if (digits.isNotEmpty) {
        final last4 = customer['phoneLast4']?.toString() ?? '';
        final displayedPhone = customer['phone']?.toString() ?? '';
        return last4 == digits || displayedPhone.endsWith(digits);
      }

      return [
        customer['name'],
        customer['email'],
        customer['customerCode']
      ].any(
          (value) => value?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final crmAsync = ref.watch(crmProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer CRM',
                    style: TextStyle(
                        fontSize: 28,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.primary),
                      onPressed: () => ref.refresh(crmProvider),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search name, email or last 4 digits',
                          prefixIcon:
                              Icon(Icons.search, color: AppTheme.mutedText),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('Customer',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 2,
                              child: Text('Contact',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('LTV',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('Risk Score',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: crmAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(
                              child: Text('Error: $err',
                                  style: const TextStyle(color: Colors.red))),
                          data: (customers) {
                            final visibleCustomers =
                                _filterCustomers(customers);
                            if (visibleCustomers.isEmpty) {
                              return const Center(
                                  child: Text('No matching customers found.'));
                            }
                            return ListView.separated(
                              itemCount: visibleCustomers.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final c = visibleCustomers[index];

                                // Use real CRM metrics
                                final ltvVal = c['lifetimeValue'] ?? 0;
                                final risk = c['riskScore'] ?? 'Low';
                                final status = (c['active'] == true)
                                    ? 'Active'
                                    : 'Inactive';

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AdminCustomerDetailScreen(
                                                    customer: c as Map<String,
                                                        dynamic>)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                  backgroundColor: AppTheme
                                                      .primaryLight
                                                      .withValues(alpha: 0.2),
                                                  child: Text(
                                                      c['name'] != null
                                                          ? c['name'][0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                          color:
                                                              AppTheme.primary,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              const SizedBox(width: 16),
                                              Text(c['name'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme.navy)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(c['email'] ?? 'No email',
                                                  style: const TextStyle(
                                                      color: AppTheme.navy,
                                                      fontSize: 13)),
                                              Text(
                                                  c['phone']?.toString() ??
                                                      'Phone unavailable',
                                                  style: const TextStyle(
                                                      color: AppTheme.mutedText,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('₹$ltvVal',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildRiskBadge(risk),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(status,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: status == 'Active'
                                                      ? AppTheme.primary
                                                      : Colors.grey)),
                                        ),
                                        SizedBox(
                                          width: 48,
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                color: AppTheme.mutedText),
                                            onSelected: (value) {
                                              if (value == 'view') {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AdminCustomerDetailScreen(
                                                                customer: c as Map<
                                                                    String,
                                                                    dynamic>)));
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                  value: 'view',
                                                  child: Text(
                                                      'View Full Profile')),
                                              const PopupMenuItem(
                                                  value: 'contact',
                                                  child:
                                                      Text('Contact Customer')),
                                              const PopupMenuItem(
                                                  value: 'block',
                                                  child: Text('Block Customer',
                                                      style: TextStyle(
                                                          color: Colors.red))),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String risk) {
    Color color;
    if (risk == 'Low') {
      color = Colors.green;
    } else if (risk == 'Medium')
      color = Colors.orange;
    else
      color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(risk,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
