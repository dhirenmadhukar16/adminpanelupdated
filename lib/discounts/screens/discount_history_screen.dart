import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class DiscountHistoryScreen extends StatefulWidget {
  final bool adminMode;
  const DiscountHistoryScreen({super.key, this.adminMode = false});
  @override
  State<DiscountHistoryScreen> createState() => _DiscountHistoryScreenState();
}
class _DiscountHistoryScreenState extends State<DiscountHistoryScreen> {
  final _phone = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  String? _store;
  bool _busy = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _phone.dispose(); super.dispose(); }
  Future<void> _load() async {
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^(\+?91[ -]?)?\d{10}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a 10-digit phone number (optional +91).'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      String path = '/api/discounts/admin/history';
      if (!widget.adminMode) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getString('storeId');
        if (id == null || id.isEmpty) throw StateError('Please sign in again.');
        path = '/api/discounts/stores/$id/history';
      }
      final r = await ApiClient.dio.get(path,
          queryParameters: {if (phone.isNotEmpty) 'phone': phone});
      final rows = (r.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() {
        _rows = rows;
        if (!_rows.any((r) => r['storeId']?.toString() == _store)) _store = null;
      });
    } catch (e) {
      String message = 'Unable to load discount history. Check connection and backend deployment.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        message = (data['message'] ?? data['detail'] ?? message).toString();
      }
      if (mounted) setState(() => _error = message);
    } finally { if (mounted) setState(() => _busy = false); }
  }
  String money(dynamic n) => (n is num ? n : 0).toStringAsFixed(2);
  @override
  Widget build(BuildContext context) {
    final stores = <String, String>{};
    for (final r in _rows) { stores[r['storeId'].toString()] = r['storeName']?.toString() ?? 'Store'; }
    final rows = _rows.where((r) => _store == null || r['storeId'].toString() == _store).toList();
    // Newest record for each order defines its current discount; revisions are not added twice.
    final latest = <String, Map<String, dynamic>>{};
    for (final r in rows) { latest.putIfAbsent(r['orderId'].toString(), () => r); }
    final currentTotal = latest.values.fold<double>(0, (n, r) => n + (r['discountAmount'] as num).toDouble());
    final summary = <String, double>{};
    for (final r in latest.values) {
      final id = r['storeId'].toString();
      summary[id] = (summary[id] ?? 0) + (r['discountAmount'] as num).toDouble();
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.adminMode ? 'Store Discounts' : 'Discounted Customers'),
          actions: [IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: TextField(controller: _phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Search by customer phone', border: OutlineInputBorder()),
              onSubmitted: (_) { if (!_busy) _load(); })),
          const SizedBox(width: 8),
          IconButton(onPressed: _busy ? null : _load, tooltip: 'Search', icon: const Icon(Icons.search)),
          IconButton(onPressed: _busy ? null : () { _phone.clear(); _load(); },
              tooltip: 'Clear search', icon: const Icon(Icons.clear)),
        ])),
        if (widget.adminMode) Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(value: _store, hint: const Text('All stores'), isExpanded: true,
            items: [const DropdownMenuItem<String>(value: null, child: Text('All stores')),
              ...stores.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))],
            onChanged: _busy ? null : (v) => setState(() => _store = v))),
        if (!_busy && _error == null) Padding(padding: const EdgeInsets.all(12),
            child: Text('${latest.length} orders • Current discounts: Rs. ${currentTotal.toStringAsFixed(2)} • ${rows.length} history entries')),
        Expanded(child: _busy ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!))
          : rows.isEmpty ? const Center(child: Text('No discount history found.'))
          : ListView(children: [
              if (widget.adminMode) ...summary.entries.map((e) => ListTile(
                leading: const Icon(Icons.store), title: Text(stores[e.key] ?? 'Store'),
                trailing: Text('Rs. ${e.value.toStringAsFixed(2)}'))),
              ...rows.map((r) => Card(margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r['customerName'] ?? 'Customer'} • Phone ending ${r['phoneLast4'] ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${r['orderNumber']} • ${r['storeName']}'),
                    Text('Date: ${r['createdAt'].toString().replaceFirst('T', ' ')}'),
                    Text('Original: Rs. ${money(r['originalAmount'])} | Final: Rs. ${money(r['finalAmount'])}'),
                    Text('Discount: Rs. ${money(r['previousDiscount'])} → Rs. ${money(r['discountAmount'])}'),
                    Text('Reason: ${r['reason']}'),
                    Text('Applied by: ${r['appliedBy']}'),
                  ]))),
            ])),
      ]),
    );
  }
}
