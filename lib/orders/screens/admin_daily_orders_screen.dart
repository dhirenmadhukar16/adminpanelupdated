import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminDailyOrdersScreen extends StatefulWidget {
  const AdminDailyOrdersScreen({super.key});

  @override
  State<AdminDailyOrdersScreen> createState() => _AdminDailyOrdersScreenState();
}

class _AdminDailyOrdersScreenState extends State<AdminDailyOrdersScreen> {
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedStoreId;
  List<Map<String, dynamic>> _stores = const [];
  Map<String, dynamic>? _dailyData;
  bool _loading = true;
  String? _error;

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  void _refreshView() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStores(), _loadOrders()]);
  }

  Future<void> _loadStores() async {
    try {
      final response = await ApiClient.dio.get('/api/admin-panel/stores/stats');
      final data = response.data;
      if (!mounted || data is! List) return;
      setState(() {
        _stores = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      // Daily orders can still be displayed for all stores.
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final query = <String, dynamic>{
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        if (_selectedStoreId != null) 'storeId': _selectedStoreId,
      };
      final response = await ApiClient.dio.get(
        '/api/admin-panel/orders/daily',
        queryParameters: query,
      );

      if (!mounted) return;
      setState(() {
        _dailyData = Map<String, dynamic>.from(response.data as Map);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _selectedDate = date);
    await _loadOrders();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final raw = _dailyData?['orders'];
    if (raw is! List) return const [];
    final orders = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final search = _searchController.text.trim().toLowerCase();
    if (search.isEmpty) return orders;
    return orders.where((order) {
      return [
        order['orderNumber'],
        order['customerName'],
        order['customerPhone'],
        order['customerAddress'],
        order['storeName'],
      ].any(
          (value) => value?.toString().toLowerCase().contains(search) ?? false);
    }).toList();
  }

  String _storeId(Map<String, dynamic> store) =>
      (store['storeId'] ?? store['id'] ?? '').toString();

  String _storeName(Map<String, dynamic> store) =>
      (store['storeName'] ?? store['name'] ?? 'Unnamed store').toString();

  String _formatDateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '-' : _dateTimeFormat.format(parsed.toLocal());
  }

  String _money(dynamic value) {
    final number = value is num ? value : num.tryParse('$value') ?? 0;
    return _moneyFormat.format(number);
  }

  int _intValue(dynamic value) =>
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
            if (_dailyData != null) _summaryCards(),
            if (_dailyData != null) const SizedBox(height: 20),
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
              'Daily Store Orders',
              style: TextStyle(
                fontSize: 28,
                color: AppTheme.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Customer, garment, payment and delivery details by day',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadOrders,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(_dateFormat.format(_selectedDate)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
        ),
        SizedBox(
          width: 250,
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedStoreId,
            decoration: const InputDecoration(
              labelText: 'Store',
              prefixIcon: Icon(Icons.storefront_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All stores'),
              ),
              ..._stores.where((store) => _storeId(store).isNotEmpty).map(
                    (store) => DropdownMenuItem<String?>(
                      value: _storeId(store),
                      child: Text(
                        _storeName(store),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            ],
            onChanged: (value) {
              setState(() => _selectedStoreId = value);
              _loadOrders();
            },
          ),
        ),
        SizedBox(
          width: 310,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search orders or customers',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCards() {
    final data = _dailyData!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summary('Orders', '${_intValue(data['totalOrders'])}',
            Icons.receipt_long_rounded, Colors.blue),
        _summary('Pieces', '${_intValue(data['totalPieces'])}',
            Icons.checkroom_rounded, Colors.purple),
        _summary('Urgent', '${_intValue(data['urgentOrders'])}',
            Icons.bolt_rounded, Colors.orange),
        _summary('Total', _money(data['totalAmount']),
            Icons.currency_rupee_rounded, AppTheme.primary),
        _summary('Paid', _money(data['paidAmount']), Icons.check_circle_rounded,
            Colors.green),
        _summary('Pending', _money(data['pendingAmount']),
            Icons.schedule_rounded, Colors.redAccent),
      ],
    );
  }

  Widget _summary(String label, String value, IconData icon, Color color) {
    return Container(
      width: 170,
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
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.mutedText, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
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
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
          ],
        ),
      );
    }

    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found for this date.'));
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
              columnSpacing: 26,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 110,
              columns: const [
                DataColumn(label: Text('Order')),
                DataColumn(label: Text('Store')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Items / Service')),
                DataColumn(label: Text('Due date')),
                DataColumn(label: Text('Pcs')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Order status')),
              ],
              rows: orders.map(_orderRow).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _orderRow(Map<String, dynamic> order) {
    final urgent = order['urgent'] == true;
    return DataRow(
      cells: [
        DataCell(_twoLines(
          order['orderNumber']?.toString() ?? '-',
          _formatDateTime(order['orderDate']),
          leading: urgent ? Icons.bolt_rounded : null,
          leadingColor: Colors.orange,
        )),
        DataCell(_limitedText(order['storeName']?.toString() ?? '-', 160)),
        DataCell(_twoLines(
          order['customerName']?.toString() ?? '-',
          order['customerPhone']?.toString() ?? '-',
        )),
        DataCell(
            _limitedText(order['customerAddress']?.toString() ?? '-', 230)),
        DataCell(_limitedText(_itemSummary(order['items']), 260)),
        DataCell(_twoLines(
          _formatDateTime(order['dueDate']),
          urgent ? 'URGENT · 24 hours' : 'NORMAL · 72 hours',
          subtitleColor: urgent ? Colors.orange.shade800 : null,
        )),
        DataCell(Text('${_intValue(order['pieces'])}')),
        DataCell(_twoLines(
          _money(order['amount']),
          'Paid ${_money(order['paidAmount'])}',
        )),
        DataCell(_statusChip(order['paymentStatus']?.toString() ?? '-')),
        DataCell(_statusChip(order['orderStatus']?.toString() ?? '-')),
      ],
    );
  }

  String _itemSummary(dynamic rawItems) {
    if (rawItems is! List || rawItems.isEmpty) return '-';
    return rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final quantity = _intValue(item['quantity']);
      final name = item['itemName'] ?? 'Item';
      final service = item['serviceType'] ?? '-';
      final variant = item['variantName']?.toString();
      return '$quantity× $name · $service${variant == null || variant.isEmpty ? '' : ' · $variant'}';
    }).join('\n');
  }

  Widget _twoLines(
    String title,
    String subtitle, {
    IconData? leading,
    Color? leadingColor,
    Color? subtitleColor,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 16, color: leadingColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtitleColor ?? AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _limitedText(String value, double width) {
    return SizedBox(
      width: width,
      child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'PAID' || 'SUCCESS' || 'DELIVERED' || 'COMPLETED' => Colors.green,
      'FAILED' || 'CANCELLED' => Colors.red,
      'PENDING' || 'REQUESTED' => Colors.orange,
      _ => Colors.blue,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized.replaceAll('_', ' '),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w700),
      ),
    );
  }
}
