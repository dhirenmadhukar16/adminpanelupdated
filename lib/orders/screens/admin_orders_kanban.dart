import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'order_detail_screen.dart';
import 'assign_rider_dialog.dart';

// State providers for filters
final selectedKanbanDateRangeProvider =
    StateProvider<DateTimeRange?>((ref) => null);
final selectedKanbanCategoryProvider = StateProvider<String?>((ref) => null);

// Provider for Kanban Data
final kanbanProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final dateRange = ref.watch(selectedKanbanDateRangeProvider);
  final category = ref.watch(selectedKanbanCategoryProvider);

  Map<String, dynamic> queryParams = {};
  if (dateRange != null) {
    queryParams['startDate'] = dateRange.start.toIso8601String().split('T')[0];
    queryParams['endDate'] = dateRange.end.toIso8601String().split('T')[0];
  }
  if (category != null && category != 'All') {
    queryParams['category'] = category;
  }

  final response = await ApiClient.dio
      .get('/api/admin-panel/orders/kanban', queryParameters: queryParams);
  final map = response.data as Map<String, dynamic>;
  return map.map((key, value) => MapEntry(key, value as List<dynamic>));
});

class AdminOrdersKanban extends ConsumerStatefulWidget {
  const AdminOrdersKanban({super.key});

  @override
  ConsumerState<AdminOrdersKanban> createState() => _AdminOrdersKanbanState();
}

class _AdminOrdersKanbanState extends ConsumerState<AdminOrdersKanban> {
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await ApiClient.dio.patch('/api/admin-panel/orders/$orderId/status',
          data: {'status': newStatus});
      ref.refresh(kanbanProvider);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    }
  }

  void _handleOrderAction(String action, dynamic order) {
    if (action == 'view') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: order['id']),
        ),
      );
    } else if (action == 'edit') {
      // Not yet implemented
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Edit coming soon')));
    } else if (action == 'assign') {
      showDialog(
        context: context,
        builder: (context) => AssignRiderDialog(orderId: order['id']),
      ).then((_) => ref.refresh(kanbanProvider));
    } else if (action == 'cancel') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ApiClient.dio.patch(
                      '/api/admin-panel/orders/${order['id']}/cancel',
                      data: {});
                  ref.refresh(kanbanProvider);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order Cancelled')));
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kanbanAsync = ref.watch(kanbanProvider);
    final selectedCategory = ref.watch(selectedKanbanCategoryProvider);
    final selectedDateRange = ref.watch(selectedKanbanDateRangeProvider);

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
                const Text('Orders Kanban Board',
                    style: TextStyle(
                        fontSize: 28,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory ?? 'All',
                      items: ['All', 'Dry Cleaning', 'Wash & Fold', 'Ironing']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => ref
                          .read(selectedKanbanCategoryProvider.notifier)
                          .state = val,
                      underline: Container(),
                      icon: const Icon(Icons.filter_list,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(selectedDateRange == null
                          ? 'Select Date'
                          : '${selectedDateRange.start.toLocal().toString().split(' ')[0]} - ${selectedDateRange.end.toLocal().toString().split(' ')[0]}'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          foregroundColor: AppTheme.primary,
                          elevation: 0),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          ref
                              .read(selectedKanbanDateRangeProvider.notifier)
                              .state = range;
                        }
                      },
                    ),
                    if (selectedDateRange != null)
                      IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => ref
                              .read(selectedKanbanDateRangeProvider.notifier)
                              .state = null),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(kanbanProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh Pipeline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: kanbanAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error loading kanban: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (columns) {
                  final orderedKeys = [
                    'Created',
                    'Pickup Assigned',
                    'Picked',
                    'Out for Delivery',
                    'Delivered'
                  ];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: orderedKeys.map((status) {
                        return _buildDragTargetColumn(
                            status, columns[status] ?? []);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragTargetColumn(String title, List<dynamic> items) {
    // return DragTarget<Map<String, dynamic>>(
    //   onWillAcceptWithDetails: (data) => true,
    //   onAcceptWithDetails: (data) {
    //     // Handle drop event here
    //     _updateOrderStatus(data['id'], title);
    //   },
    //   builder: (context, candidateData, rejectedData) {
    return DragTarget<Map<String, dynamic>>(
  onWillAcceptWithDetails: (details) => true,

  onAcceptWithDetails: (details) {
    final orderData = details.data;

    _updateOrderStatus(
      orderData['id'].toString(),
      title,
    );
  },

  builder: (context, candidateData, rejectedData) {
        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? AppTheme.primaryLight.withValues(alpha: 0.1)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                            fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Text('${items.length}',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Draggable<Map<String, dynamic>>(
                      data: {'id': item['id'], 'customer': item['customer']},
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.8,
                          child: SizedBox(
                            width: 280,
                            child: _buildKanbanCard(item),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildKanbanCard(item),
                      ),
                      child: _buildKanbanCard(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppTheme.navy.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                        item['orderNumber'] ??
                            item['id']?.toString().substring(0, 8) ??
                            'ORD',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 20, color: AppTheme.mutedText),
                onSelected: (value) => _handleOrderAction(value, item),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                      value: 'view', child: Text('View Full Details')),
                  const PopupMenuItem<String>(
                      value: 'edit', child: Text('Edit Order')),
                  const PopupMenuItem<String>(
                      value: 'assign', child: Text('Assign Rider')),
                  const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel Order',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF8FAFC),
                child: Icon(Icons.person, size: 16, color: AppTheme.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item['customer'] ?? 'Customer Name',
                    style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildOrderTags(item),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checkroom,
                        size: 16, color: AppTheme.mutedText),
                    const SizedBox(width: 6),
                    Text('${item['items'] ?? 0} Items',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy)),
                  ],
                ),
                Text('₹${item['amount'] ?? 0}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildOrderTags(dynamic item) {
    List<Widget> tags = [];

    if (item['isUrgent'] == true) {
      tags.add(_buildTag('URGENT', Colors.red));
    }

    if (item['deliveryDate'] != null) {
      try {
        DateTime deliveryDate = DateTime.parse(item['deliveryDate']);
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        if (today.isAfter(deliveryDate)) {
          tags.add(_buildTag('OVERDUE', Colors.orange));
        } else if (today.isAtSameMomentAs(deliveryDate)) {
          tags.add(_buildTag('LATE', Colors.deepOrangeAccent));
        } else {
          // If difference is >= 1 days and it's almost done
          if (deliveryDate.difference(today).inDays >= 1) {
            tags.add(_buildTag('ADVANCED', Colors.blue));
          }
        }
      } catch (e) {
        // ignore parsing error
      }
    }

    return tags;
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
