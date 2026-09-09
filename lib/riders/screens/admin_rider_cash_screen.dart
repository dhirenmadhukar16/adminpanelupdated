import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminRiderCashScreen extends StatefulWidget {
  const AdminRiderCashScreen({super.key});

  @override
  State<AdminRiderCashScreen> createState() => _AdminRiderCashScreenState();
}

class _AdminRiderCashScreenState extends State<AdminRiderCashScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _transactions = [];
  String? _storeId;
  String? _riderId;

  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _date = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final params = <String, dynamic>{};
      if (_storeId != null) params['storeId'] = _storeId;
      if (_riderId != null) params['riderId'] = _riderId;

      final summaryParams = <String, dynamic>{};
      if (_storeId != null) summaryParams['storeId'] = _storeId;

      final responses = await Future.wait([
        ApiClient.dio.get('/api/admin/rider-cash/summary',
            queryParameters: summaryParams),
        ApiClient.dio
            .get('/api/admin/rider-cash/transactions', queryParameters: params),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = Map<String, dynamic>.from(responses[0].data as Map);
        _transactions = (responses[1].data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return (data['message'] ?? data['error'] ?? error.message).toString();
      }
      return data?.toString() ?? error.message ?? 'Request failed';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> get _riders =>
      ((_summary['riders'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<Map<String, String>> get _stores {
    final result = <String, String>{};
    for (final rider in _riders) {
      final id = rider['storeId']?.toString();
      if (id != null) {
        result[id] = rider['storeName']?.toString() ??
            rider['storeCode']?.toString() ??
            'Store';
      }
    }
    for (final row in _transactions) {
      final id = row['storeId']?.toString();
      if (id != null) {
        result[id] = row['storeName']?.toString() ??
            row['storeCode']?.toString() ??
            'Store';
      }
    }
    return result.entries.map((e) => {'id': e.key, 'name': e.value}).toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  Future<void> _clearFilters() async {
    setState(() {
      _storeId = null;
      _riderId = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rider Cash Control',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      _overview(),
                      const SizedBox(height: 20),
                      _filters(),
                      const SizedBox(height: 24),
                      _title('Rider-wise outstanding', _riders.length),
                      const SizedBox(height: 12),
                      _riderTable(),
                      const SizedBox(height: 24),
                      _title('Ledger transactions', _transactions.length),
                      const SizedBox(height: 12),
                      _transactionTable(),
                    ],
                  ),
                ),
    );
  }

  Widget _overview() => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth < 760
            ? constraints.maxWidth
            : (constraints.maxWidth - 48) / 4;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          _metric('Total collected', _summary['totalCollected'],
              Icons.payments_outlined, Colors.blue, width),
          _metric('Total deposited', _summary['totalDeposited'],
              Icons.account_balance_outlined, Colors.green, width),
          _metric('Outstanding', _summary['totalOutstanding'],
              Icons.warning_amber_rounded, Colors.orange, width),
          _metric('Riders with ledger', _summary['riderCount'],
              Icons.delivery_dining, Colors.purple, width,
              money: false),
        ]);
      });

  Widget _metric(
          String title, dynamic value, IconData icon, Color color, double width,
          {bool money = true}) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 12)
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 5),
                Text(money ? _money.format(_number(value)) : '${value ?? 0}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ])),
        ]),
      );

  Widget _filters() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(builder: (context, constraints) {
          final vertical = constraints.maxWidth < 680;
          final controls = <Widget>[
            DropdownButtonFormField<String?>(
              value: _storeId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Store', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All stores')),
                ..._stores.map((s) => DropdownMenuItem<String?>(
                    value: s['id'], child: Text(s['name']!))),
              ],
              onChanged: (value) => setState(() {
                _storeId = value;
                _riderId = null;
              }),
            ),
            DropdownButtonFormField<String?>(
              value: _riderId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Rider', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All riders')),
                ..._riders.map((r) => DropdownMenuItem<String?>(
                    value: r['riderId']?.toString(),
                    child: Text(r['riderName']?.toString() ?? 'Rider'))),
              ],
              onChanged: (value) => setState(() => _riderId = value),
            ),
            FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Apply')),
            OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear')),
          ];
          if (vertical) {
            return Column(
              children: controls
                  .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(width: double.infinity, child: e)))
                  .toList(),
            );
          }
          return Row(children: [
            Expanded(child: controls[0]),
            const SizedBox(width: 12),
            Expanded(child: controls[1]),
            const SizedBox(width: 12),
            controls[2],
            const SizedBox(width: 8),
            controls[3],
          ]);
        }),
      );

  Widget _title(String text, int count) => Row(children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800))),
        Chip(label: Text('$count records')),
      ]);

  Widget _riderTable() {
    if (_riders.isEmpty) return _empty('No rider cash balances found.');
    return _table(DataTable(
      columns: const [
        DataColumn(label: Text('Rider')),
        DataColumn(label: Text('Store')),
        DataColumn(label: Text('Collected'), numeric: true),
        DataColumn(label: Text('Deposited'), numeric: true),
        DataColumn(label: Text('Outstanding'), numeric: true),
        DataColumn(label: Text('Last activity')),
      ],
      rows: _riders.map((r) {
        final outstanding = _number(r['outstandingBalance']);
        final last =
            DateTime.tryParse(r['lastTransactionAt']?.toString() ?? '');
        return DataRow(cells: [
          DataCell(Text('${r['riderName'] ?? '-'}\n${r['riderPhone'] ?? ''}')),
          DataCell(Text(r['storeName']?.toString() ?? '-')),
          DataCell(Text(_money.format(_number(r['totalCollected'])))),
          DataCell(Text(_money.format(_number(r['totalDeposited'])))),
          DataCell(Text(_money.format(outstanding),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: outstanding > 0
                      ? Colors.orange.shade800
                      : Colors.green))),
          DataCell(Text(last == null ? '-' : _date.format(last.toLocal()))),
        ]);
      }).toList(),
    ));
  }

  Widget _transactionTable() {
    if (_transactions.isEmpty)
      return _empty('No rider cash transactions found.');
    return _table(DataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Rider')),
        DataColumn(label: Text('Store')),
        DataColumn(label: Text('Order')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Amount'), numeric: true),
      ],
      rows: _transactions.map((r) {
        final created = DateTime.tryParse(r['createdAt']?.toString() ?? '');
        final type = r['transactionType']?.toString() ?? '-';
        return DataRow(cells: [
          DataCell(
              Text(created == null ? '-' : _date.format(created.toLocal()))),
          DataCell(Text(r['riderName']?.toString() ?? '-')),
          DataCell(Text(r['storeName']?.toString() ?? '-')),
          DataCell(Text(r['orderNumber']?.toString() ?? '-')),
          DataCell(
              Text('${r['customerName'] ?? '-'}\n${r['customerPhone'] ?? ''}')),
          DataCell(_typeChip(type)),
          DataCell(Text(_money.format(_number(r['amount'])),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ]);
      }).toList(),
    ));
  }

  Widget _typeChip(String type) {
    final color = type == 'CASH_DEPOSITED'
        ? Colors.green
        : type == 'CASH_COLLECTED'
            ? Colors.orange
            : Colors.blueGrey;
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .12),
      label: Text(type.replaceAll('_', ' '), style: TextStyle(color: color)),
    );
  }

  Widget _table(DataTable table) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        ),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
      );

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 52, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
}
