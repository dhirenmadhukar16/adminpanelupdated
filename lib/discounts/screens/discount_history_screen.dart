import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

class DiscountHistoryScreen extends StatefulWidget {
  final bool adminMode;

  const DiscountHistoryScreen({
    super.key,
    this.adminMode = false,
  });

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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String money(dynamic value) => _amount(value).toStringAsFixed(2);

  DateTime? _createdAt(Map<String, dynamic> row) {
    return DateTime.tryParse(row['createdAt']?.toString() ?? '');
  }

  Future<void> _load() async {
    if (!mounted) return;

    final phone = _phone.text.trim();

    if (phone.isNotEmpty && !RegExp(r'^(\+?91[ -]?)?\d{10}$').hasMatch(phone)) {
      setState(() {
        _busy = false;
        _error = 'Enter a 10-digit phone number (optional +91).';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      String path = '/api/discounts/admin/history';

      if (!widget.adminMode) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getString('storeId');

        if (id == null || id.isEmpty) {
          throw StateError('Please sign in again.');
        }

        path = '/api/discounts/stores/$id/history';
      }

      final response = await ApiClient.dio.get(
        path,
        queryParameters: {
          if (phone.isNotEmpty) 'phone': phone,
        },
      );

      if (response.data is! List) {
        throw const FormatException('Invalid discount history response.');
      }

      final rows = (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      // Newest entries first, so each order's latest discount is counted.
      rows.sort((a, b) {
        final first = _createdAt(a);
        final second = _createdAt(b);

        if (first == null && second == null) return 0;
        if (first == null) return 1;
        if (second == null) return -1;

        return second.compareTo(first);
      });

      if (!mounted) return;

      setState(() {
        _rows = rows;

        if (!_rows.any(
          (row) => row['storeId']?.toString() == _store,
        )) {
          _store = null;
        }
      });
    } catch (e) {
      String message = 'Unable to load discount history. '
          'Check connection and backend deployment.';

      if (e is StateError) {
        message = e.message.toString();
      } else if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        message = (data['message'] ?? data['detail'] ?? message).toString();
      }

      if (mounted) {
        setState(() => _error = message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _historyCard(Map<String, dynamic> row) {
    final date = row['createdAt']?.toString().replaceFirst('T', ' ') ?? '—';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${row['customerName'] ?? 'Customer'} • '
              'Phone ending ${row['phoneLast4'] ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${row['orderNumber'] ?? 'Order'} • '
              '${row['storeName'] ?? 'Store'}',
            ),
            Text('Date: $date'),
            Text(
              'Original: Rs. ${money(row['originalAmount'])} | '
              'Final: Rs. ${money(row['finalAmount'])}',
            ),
            Text(
              'Discount: Rs. ${money(row['previousDiscount'])} → '
              'Rs. ${money(row['discountAmount'])}',
            ),
            Text('Reason: ${row['reason'] ?? '—'}'),
            Text('Applied by: ${row['appliedBy'] ?? '—'}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stores = <String, String>{};

    for (final row in _rows) {
      final storeId = row['storeId']?.toString();

      if (storeId != null && storeId.isNotEmpty) {
        stores[storeId] = row['storeName']?.toString() ?? 'Store';
      }
    }

    final rows = _rows.where((row) {
      return _store == null || row['storeId']?.toString() == _store;
    }).toList();

    // Count only the newest event per order in the current-discount total.
    // All events remain visible in the history list.
    final latest = <String, Map<String, dynamic>>{};

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final orderId = row['orderId']?.toString();
      final key =
          orderId == null || orderId.isEmpty ? 'missing-order-$index' : orderId;

      latest.putIfAbsent(key, () => row);
    }

    final currentTotal = latest.values.fold<double>(
      0.0,
      (total, row) => total + _amount(row['discountAmount']),
    );

    final summary = <String, double>{};

    for (final row in latest.values) {
      final storeId = row['storeId']?.toString();

      if (storeId == null || storeId.isEmpty) continue;

      summary[storeId] =
          (summary[storeId] ?? 0.0) + _amount(row['discountAmount']);
    }

    Widget content;

    if (_busy) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (rows.isEmpty) {
      content = const Center(
        child: Text('No discount history found.'),
      );
    } else {
      content = ListView(
        children: [
          if (widget.adminMode)
            ...summary.entries.map(
              (entry) => ListTile(
                leading: const Icon(Icons.store),
                title: Text(stores[entry.key] ?? 'Store'),
                trailing: Text(
                  'Rs. ${entry.value.toStringAsFixed(2)}',
                ),
              ),
            ),
          ...rows.map(_historyCard),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.adminMode ? 'Store Discounts' : 'Discounted Customers',
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Search by customer phone',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!_busy) _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _busy ? null : _load,
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _phone.clear();
                          _load();
                        },
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          if (widget.adminMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _store,
                      hint: const Text('All stores'),
                      isExpanded: true,
                      items: stores.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (value) {
                              setState(() => _store = value);
                            },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Show all stores',
                    onPressed: _busy || _store == null
                        ? null
                        : () => setState(() => _store = null),
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),
          if (!_busy && _error == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${latest.length} orders • '
                'Current discounts: Rs. ${currentTotal.toStringAsFixed(2)} • '
                '${rows.length} history entries',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
