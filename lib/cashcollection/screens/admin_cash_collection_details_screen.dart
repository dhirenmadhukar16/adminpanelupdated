import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_cash_collection.dart';
import '../providers/admin_cash_collection_provider.dart';

class AdminCashCollectionDetailsScreen
    extends ConsumerStatefulWidget {
  final String collectionId;

  const AdminCashCollectionDetailsScreen({
    super.key,
    required this.collectionId,
  });

  @override
  ConsumerState<AdminCashCollectionDetailsScreen>
      createState() =>
          _AdminCashCollectionDetailsScreenState();
}

class _AdminCashCollectionDetailsScreenState
    extends ConsumerState<
        AdminCashCollectionDetailsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      ref
          .read(adminCashCollectionProvider)
          .loadCollectionById(
            widget.collectionId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        ref.watch(adminCashCollectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cash Collection Details',
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(
    AdminCashCollectionNotifier provider,
  ) {
    if (provider.isDetailsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(
                        adminCashCollectionProvider,
                      )
                      .loadCollectionById(
                        widget.collectionId,
                      );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final collection =
        provider.selectedCollection;

    if (collection == null) {
      return const Center(
        child: Text(
          'Cash collection not found.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return ref
            .read(
              adminCashCollectionProvider,
            )
            .loadCollectionById(
              widget.collectionId,
            );
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(collection),
          const SizedBox(height: 16),
          _buildFinancialCard(collection),
          const SizedBox(height: 16),
          _buildReconciliationCard(collection),
          const SizedBox(height: 16),
          _buildMetaCard(collection),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AdminCashCollection collection,
  ) {
    final status =
        collection.reconciliationStatus ??
            collection.status ??
            'PENDING';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                _initial(collection.storeName),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.storeName ??
                        'Store',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(
                      collection.collectionDate,
                    ),
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _statusChip(status),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    AdminCashCollection collection,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _amountRow(
              'Opening Cash',
              collection.openingCash,
            ),

            _amountRow(
              'Cash Sales',
              collection.cashSales,
            ),

            _amountRow(
              'Cash Refunds',
              collection.cashRefunds,
            ),

            _amountRow(
              'Expected Cash',
              collection.expectedCash,
              bold: true,
            ),

            const Divider(height: 20),

            _amountRow(
              'Online Collection',
              collection.onlineCollection,
            ),

            _amountRow(
              'Total Collection',
              collection.totalCollection,
              bold: true,
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _countBox(
                    'Cash Orders',
                    collection.cashOrderCount,
                    Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _countBox(
                    'Online Orders',
                    collection.onlineOrderCount,
                    Icons.credit_card_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationCard(
    AdminCashCollection collection,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Reconciliation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

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
                bold: true,
                valueColor:
                    _differenceColor(
                  collection.cashDifference!,
                ),
              ),

            const SizedBox(height: 10),

            if (collection.reconciledBy !=
                null)
              _textRow(
                'Reconciled By',
                collection.reconciledBy!,
              ),

            if (collection.reconciledAt !=
                null)
              _textRow(
                'Reconciled At',
                _formatDateTime(
                  collection.reconciledAt!,
                ),
              ),

            if (collection.remarks != null &&
                collection.remarks!
                    .trim()
                    .isNotEmpty)
              _textRow(
                'Remarks',
                collection.remarks!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(
    AdminCashCollection collection,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _textRow(
              'Collection ID',
              collection.id,
            ),

            _textRow(
              'Store ID',
              collection.storeId,
            ),

            _textRow(
              'Date',
              _formatDate(
                collection.collectionDate,
              ),
            ),

            _textRow(
              'Status',
              collection.status ??
                  'N/A',
            ),

            _textRow(
              'Reconciliation Status',
              collection
                      .reconciliationStatus ??
                  'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
    String label,
    double amount, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBox(
    String title,
    int count,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 11,
              ),
            ),
          ),
          Text(
            count.toString(),
            style:
                const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _initial(String? name) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    return name
        .trim()
        .substring(0, 1)
        .toUpperCase();
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final d = _formatDate(date);

    final h =
        date.hour.toString().padLeft(2, '0');

    final m =
        date.minute.toString().padLeft(2, '0');

    return '$d $h:$m';
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

      default:
        return Colors.deepPurple;
    }
  }
}