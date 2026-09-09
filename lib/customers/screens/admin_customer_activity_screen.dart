import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminCustomerActivityScreen extends StatefulWidget {
  const AdminCustomerActivityScreen({super.key});

  @override
  State<AdminCustomerActivityScreen> createState() =>
      _AdminCustomerActivityScreenState();
}

class _AdminCustomerActivityScreenState
    extends State<AdminCustomerActivityScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _stores = const [];
  String? _selectedStoreId;
  String _status = 'ALL';
  int _inactiveDays = 7;
  bool _loading = true;
  String? _error;

  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_rebuild);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStores(), _loadActivity()]);
  }

  Future<void> _loadStores() async {
    try {
      final response = await ApiClient.dio.get('/api/admin-panel/stores/stats');
      if (!mounted || response.data is! List) return;
      setState(() {
        _stores = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      // The all-store activity dashboard remains usable.
    }
  }

  Future<void> _loadActivity() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await ApiClient.dio.get(
        '/api/admin-panel/customers/activity',
        queryParameters: {
          'inactiveDays': _inactiveDays,
          if (_selectedStoreId != null) 'storeId': _selectedStoreId,
        },
      );
      if (!mounted) return;
      setState(() {
        _dashboard = Map<String, dynamic>.from(response.data as Map);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _storeId(Map<String, dynamic> store) =>
      (store['storeId'] ?? store['id'] ?? '').toString();

  String _storeName(Map<String, dynamic> store) =>
      (store['storeName'] ?? store['name'] ?? 'Unnamed store').toString();

  List<Map<String, dynamic>> get _customers {
    final raw = _dashboard?['customers'];
    if (raw is! List) return const [];
    final query = _searchController.text.trim().toLowerCase();
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((customer) {
      if (_status != 'ALL' && customer['activityStatus'] != _status) {
        return false;
      }
      return _matchesCustomer(customer, query);
    }).toList();
  }

  bool _matchesCustomer(Map<String, dynamic> customer, String query) {
    if (query.isEmpty) return true;

    final digits = query.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      final last4 = customer['phoneLast4']?.toString() ?? '';
      final displayedPhone = customer['phone']?.toString() ?? '';
      return last4 == digits || displayedPhone.endsWith(digits);
    }

    return [
      customer['customerName'],
      customer['email'],
      customer['lastStoreName'],
    ].any((value) => value?.toString().toLowerCase().contains(query) ?? false);
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? 'Never' : _dateTimeFormat.format(parsed.toLocal());
  }

  String _money(dynamic value) {
    final number = value is num ? value : num.tryParse('$value') ?? 0;
    return _moneyFormat.format(number);
  }

  int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 24),
            _filters(),
            const SizedBox(height: 20),
            if (_dashboard != null) _summary(),
            if (_dashboard != null) const SizedBox(height: 20),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Activity',
              style: TextStyle(
                fontSize: 28,
                color: AppTheme.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track active and passive customers using order history',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadActivity,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 225,
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedStoreId,
            decoration: const InputDecoration(
              labelText: 'Store',
              prefixIcon: Icon(Icons.storefront_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All stores')),
              ..._stores.where((store) => _storeId(store).isNotEmpty).map(
                    (store) => DropdownMenuItem<String?>(
                      value: _storeId(store),
                      child: Text(_storeName(store),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
            ],
            onChanged: (value) {
              setState(() => _selectedStoreId = value);
              _loadActivity();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<int>(
            initialValue: _inactiveDays,
            decoration: const InputDecoration(
              labelText: 'Inactive after',
              prefixIcon: Icon(Icons.timelapse_rounded),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 14, child: Text('14 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 60, child: Text('60 days')),
              DropdownMenuItem(value: 90, child: Text('90 days')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _inactiveDays = value);
              _loadActivity();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Activity status',
              prefixIcon: Icon(Icons.filter_alt_rounded),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All customers')),
              DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
              DropdownMenuItem(value: 'PASSIVE', child: Text('Passive')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'ALL'),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search name, email or last 4 digits',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    final data = _dashboard!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
            'Total', data['totalCustomers'], Icons.people_rounded, Colors.blue),
        _summaryCard('Active', data['activeCustomers'],
            Icons.person_pin_circle_rounded, Colors.green),
        _summaryCard('Passive', data['passiveCustomers'],
            Icons.person_off_rounded, Colors.orange),
        _summaryCard('Never ordered', data['neverOrderedCustomers'],
            Icons.remove_shopping_cart_rounded, Colors.red),
        _summaryCard('New in $_inactiveDays days', data['newCustomers'],
            Icons.person_add_alt_1_rounded, Colors.purple),
      ],
    );
  }

  Widget _summaryCard(
      String title, dynamic value, IconData icon, MaterialColor color) {
    return Container(
      width: 185,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedText)),
                Text('${_int(value)}',
                    style: const TextStyle(
                        fontSize: 20,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadActivity, child: const Text('Retry')),
          ],
        ),
      );
    }

    final customers = _customers;
    if (customers.isEmpty) {
      return const Center(child: Text('No matching customers found.'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 28,
              dataRowMinHeight: 68,
              dataRowMaxHeight: 90,
              columns: const [
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Mobile')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Last activity')),
                DataColumn(label: Text('Inactive')),
                DataColumn(label: Text('Orders / bookings')),
                DataColumn(label: Text('Paid amount')),
                DataColumn(label: Text('Last store')),
                DataColumn(label: Text('Address')),
              ],
              rows: customers.map(_row).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(Map<String, dynamic> customer) {
    final active = customer['activityStatus'] == 'ACTIVE';
    final never = customer['neverOrdered'] == true;
    return DataRow(cells: [
      DataCell(
          _twoLines(customer['customerName'] ?? '-', customer['email'] ?? '-')),
      DataCell(SelectableText(customer['phone']?.toString() ?? '-')),
      DataCell(_activityChip(active ? 'ACTIVE' : 'PASSIVE', active)),
      DataCell(_twoLines(
        _date(customer['lastActivityAt']),
        never ? 'Never ordered' : 'Latest booking/order',
      )),
      DataCell(Text(never
          ? '-'
          : '${_int(customer['daysInactive'])} day${_int(customer['daysInactive']) == 1 ? '' : 's'}')),
      DataCell(_twoLines(
        '${_int(customer['totalOrders'])} orders',
        '${_int(customer['totalBookings'])} bookings',
      )),
      DataCell(Text(_money(customer['totalSpend']),
          style: const TextStyle(fontWeight: FontWeight.w700))),
      DataCell(_limited(customer['lastStoreName'] ?? 'Not assigned', 170)),
      DataCell(_limited(customer['address'] ?? '-', 240)),
    ]);
  }

  Widget _twoLines(dynamic title, dynamic subtitle) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$subtitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
        ],
      ),
    );
  }

  Widget _limited(dynamic value, double width) {
    return SizedBox(
      width: width,
      child: Text('$value', maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _activityChip(String label, bool active) {
    final color = active ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color.shade700, fontWeight: FontWeight.w800)),
    );
  }
}
