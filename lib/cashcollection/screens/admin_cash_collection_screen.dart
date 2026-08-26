import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_cash_collection.dart';
import '../providers/admin_cash_collection_provider.dart';
import 'admin_cash_collection_details_screen.dart';
import '../../stores/screens/stores_screen.dart' show storesListProvider;

class AdminCashCollectionScreen extends ConsumerStatefulWidget {
  const AdminCashCollectionScreen({
    super.key,
  });

  @override
  ConsumerState<AdminCashCollectionScreen> createState() =>
      _AdminCashCollectionScreenState();
}

class _AdminCashCollectionScreenState
    extends ConsumerState<AdminCashCollectionScreen> {
  String? _selectedStoreId;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final provider = ref.read(adminCashCollectionProvider);

      _selectedDate = provider.selectedDate;
      _selectedStoreId = provider.selectedStoreId;

      provider.loadCollections(
        date: _selectedDate,
        storeId: _selectedStoreId,
      );
    });
  }

  // ============================================================
  // APPLY FILTER
  // ============================================================

  Future<void> _applyFilter() async {
    await ref.read(adminCashCollectionProvider).loadCollections(
          date: _selectedDate,
          storeId: _selectedStoreId,
        );
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  // ============================================================
  // CLEAR FILTER
  // ============================================================

  Future<void> _clearFilters() async {
    if (!mounted) return;

    setState(() {
      _selectedStoreId = null;
      _selectedDate = DateTime.now();
    });

    await ref.read(adminCashCollectionProvider).loadCollections(
          date: _selectedDate,
          storeId: null,
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(adminCashCollectionProvider);

    final collections = provider.collections;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cash Collection',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: provider.isLoading ? null : _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_outlined,
            ),
            tooltip: 'Clear Filters',
          ),
          IconButton(
            onPressed: provider.isLoading ? null : _applyFilter,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _applyFilter,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // FILTER
            // ==================================================

            _buildFilterCard(
              provider,
              ref.watch(storesListProvider),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // LOADING
            // ==================================================

            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 32,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // ==================================================
            // ERROR
            // ==================================================

            if (!provider.isLoading &&
                provider.error != null &&
                collections.isEmpty)
              _buildError(provider),

            // ==================================================
            // DATA
            // ==================================================

            if (!provider.isLoading && provider.error == null) ...[
              _buildOverview(
                collections,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Store-wise Collection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _resultCount(
                    collections.length,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (collections.isEmpty)
                _buildEmptyState()
              else
                ...collections.map(
                  (collection) => _collectionCard(
                    context,
                    collection,
                  ),
                ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard(
    AdminCashCollectionNotifier provider,
    AsyncValue<List<dynamic>> storesAsync,
  ) {
    final storeOptions = _buildStoreOptions(storesAsync);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Cash Collection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // STORE
            // --------------------------------------------------

            const Text(
              'Store',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField<String?>(
              initialValue: _isStoreValueValid(
                storeOptions,
              )
                  ? _selectedStoreId
                  : null,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.storefront_outlined,
                ),
                hintText: 'Select Store',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Stores'),
                ),
                ...storeOptions.map(
                  (store) => DropdownMenuItem<String?>(
                    value: store.id,
                    child: Text(
                      store.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: provider.isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedStoreId = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------

            const Text(
              'Collection Date',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            InkWell(
              onTap: provider.isLoading ? null : _selectDate,
              borderRadius: BorderRadius.circular(
                12,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(
                          _selectedDate,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // APPLY FILTER
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _applyFilter,
                icon: const Icon(
                  Icons.filter_alt_outlined,
                ),
                label: const Text(
                  'Apply Filter',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // ACTIVE FILTER
            // --------------------------------------------------

            _buildActiveFilterText(
              storeOptions,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STORE OPTIONS
  // ============================================================

  List<_StoreOption> _buildStoreOptions(
    AsyncValue<List<dynamic>> storesAsync,
  ) {
    final rawStores = storesAsync.asData?.value ?? const [];

    final Map<String, _StoreOption> stores = {};

    for (final store in rawStores) {
      final id = (store['storeId'] ?? store['id'])?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      stores.putIfAbsent(
        id,
        () => _StoreOption(
          id: id,
          name: store['storeName']?.toString() ?? id,
        ),
      );
    }

    final result = stores.values.toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return result;
  }

  bool _isStoreValueValid(
    List<_StoreOption> options,
  ) {
    if (_selectedStoreId == null) {
      return true;
    }

    return options.any(
      (store) => store.id == _selectedStoreId,
    );
  }

  // ============================================================
  // ACTIVE FILTER TEXT
  // ============================================================

  Widget _buildActiveFilterText(
    List<_StoreOption> stores,
  ) {
    String storeName = 'All Stores';

    if (_selectedStoreId != null) {
      for (final store in stores) {
        if (store.id == _selectedStoreId) {
          storeName = store.name;
          break;
        }
      }

      if (storeName == 'All Stores') {
        storeName = _selectedStoreId!;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Showing: $storeName • '
        '${_formatDate(_selectedDate)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview(
    List<AdminCashCollection> collections,
  ) {
    double cash = 0;
    double online = 0;
    double refunds = 0;
    double expected = 0;
    double total = 0;

    int cashOrders = 0;
    int onlineOrders = 0;

    for (final item in collections) {
      cash += item.cashSales;
      online += item.onlineCollection;
      refunds += item.cashRefunds;
      expected += item.expectedCash;
      total += item.totalCollection;

      cashOrders += item.cashOrderCount;
      onlineOrders += item.onlineOrderCount;
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finance Overview',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            _summaryRow(
              'Cash Collection',
              cash,
            ),
            _summaryRow(
              'Online Collection',
              online,
            ),
            _summaryRow(
              'Cash Refunds',
              refunds,
            ),
            _summaryRow(
              'Expected Cash',
              expected,
            ),
            const Divider(
              height: 20,
            ),
            _summaryRow(
              'Total Collection',
              total,
              bold: true,
            ),
            const SizedBox(
              height: 10,
            ),
            _countRow(
              'Cash Orders',
              cashOrders,
            ),
            _countRow(
              'Online Orders',
              onlineOrders,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COLLECTION CARD
  // ============================================================

  Widget _collectionCard(
    BuildContext context,
    AdminCashCollection collection,
  ) {
    final status =
        collection.reconciliationStatus ?? collection.status ?? 'PENDING';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          12,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCashCollectionDetailsScreen(
                collectionId: collection.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      _initial(
                        collection.storeName,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.storeName ?? 'Store',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          _formatDate(
                            collection.collectionDate,
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(
                    status,
                  ),
                ],
              ),
              const Divider(
                height: 20,
              ),
              _amountRow(
                'Cash Collection',
                collection.cashSales,
              ),
              _amountRow(
                'Online Collection',
                collection.onlineCollection,
              ),
              _amountRow(
                'Cash Refunds',
                collection.cashRefunds,
              ),
              _amountRow(
                'Expected Cash',
                collection.expectedCash,
              ),
              if (collection.declaredCash != null)
                _amountRow(
                  'Declared Cash',
                  collection.declaredCash!,
                ),
              if (collection.cashDifference != null)
                _amountRow(
                  'Difference',
                  collection.cashDifference!,
                  valueColor: _differenceColor(
                    collection.cashDifference!,
                  ),
                ),
              const Divider(
                height: 20,
              ),
              _amountRow(
                'Total Collection',
                collection.totalCollection,
                bold: true,
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Expanded(
                    child: _countBadge(
                      icon: Icons.payments_outlined,
                      label: 'Cash Orders',
                      value: collection.cashOrderCount,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: _countBadge(
                      icon: Icons.credit_card_outlined,
                      label: 'Online Orders',
                      value: collection.onlineOrderCount,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AMOUNT ROW
  // ============================================================

  Widget _amountRow(
    String title,
    double amount, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            _money(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _money(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNT ROW
  // ============================================================

  Widget _countRow(
    String title,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNT BADGE
  // ============================================================

  Widget _countBadge({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(
            width: 6,
          ),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT COUNT
  // ============================================================

  Widget _resultCount(
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        '$count store${count == 1 ? '' : 's'}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    String status,
  ) {
    final color = _statusColor(status);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 110,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          40,
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'No collections found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'There is no cash collection '
              'for the selected store and date.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
    AdminCashCollectionNotifier provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              provider.error ?? 'Unable to load cash collection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            ElevatedButton(
              onPressed: _applyFilter,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _money(
    double value,
  ) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _initial(
    String? name,
  ) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    return name.trim().substring(0, 1).toUpperCase();
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _differenceColor(
    double difference,
  ) {
    if (difference == 0) {
      return Colors.green;
    }

    if (difference < 0) {
      return Colors.red;
    }

    return Colors.orange;
  }

  Color _statusColor(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'MATCHED':
      case 'RECONCILED':
        return Colors.green;

      case 'SHORT':
        return Colors.red;

      case 'OVER':
        return Colors.orange;

      case 'PENDING':
      case 'OPEN':
      default:
        return Colors.deepPurple;
    }
  }
}

// ============================================================
// STORE OPTION
// ============================================================

class _StoreOption {
  final String id;
  final String name;

  const _StoreOption({
    required this.id,
    required this.name,
  });
}
