import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final inventoryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response =
        await ApiClient.dio.get('/api/admin-panel/warehouse/inventory');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminWarehouseScreen extends ConsumerWidget {
  const AdminWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _AddInventoryDialog(
              onSuccess: () => ref.refresh(inventoryProvider),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Inventory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Central Warehouse & Supply Chain',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Inventory Management (from PostgreSQL)',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty)
                    return const Center(
                        child: Text(
                            'No inventory records found. Click "Add Inventory" to start.'));
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final stock = item['currentStock'] as num;
                      final minThreshold = item['minimumThreshold'] as num;
                      final status =
                          stock < minThreshold ? 'Low Stock' : 'Healthy';
                      final color = stock < minThreshold
                          ? AppTheme.warning
                          : AppTheme.success;

                      return _buildInventoryCard(
                        item['itemName'] ?? 'Unknown',
                        '${item['currentStock']} ${item['unit']}',
                        status,
                        color,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(
      String title, String amount, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          Text(amount,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _AddInventoryDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddInventoryDialog({required this.onSuccess});

  @override
  State<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<_AddInventoryDialog> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty ||
        _unitCtrl.text.isEmpty ||
        _stockCtrl.text.isEmpty ||
        _minCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin-panel/warehouse/inventory', data: {
        'itemName': _nameCtrl.text,
        'unit': _unitCtrl.text,
        'currentStock': double.tryParse(_stockCtrl.text) ?? 0,
        'minimumThreshold': double.tryParse(_minCtrl.text) ?? 0,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name (e.g. Detergent)')),
            const SizedBox(height: 16),
            TextField(
                controller: _unitCtrl,
                decoration:
                    const InputDecoration(labelText: 'Unit (e.g. L, Boxes)')),
            const SizedBox(height: 16),
            TextField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Current Stock'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(
                controller: _minCtrl,
                decoration: const InputDecoration(
                    labelText: 'Minimum Threshold (for alerts)'),
                keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add Item'),
        ),
      ],
    );
  }
}
