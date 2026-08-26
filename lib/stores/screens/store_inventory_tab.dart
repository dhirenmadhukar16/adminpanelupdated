import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class StoreInventoryTab extends StatefulWidget {
  final String storeId;
  const StoreInventoryTab({super.key, required this.storeId});

  @override
  State<StoreInventoryTab> createState() => _StoreInventoryTabState();
}

class _StoreInventoryTabState extends State<StoreInventoryTab> {
  bool loading = true;
  List inventory = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadInventory();
  }

  Future<void> loadInventory() async {
    try {
      final response = await ApiClient.dio
          .get('/api/admin-panel/stores/${widget.storeId}/inventory');
      if (mounted) {
        setState(() {
          inventory = response.data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await ApiClient.dio
          .delete('/api/admin-panel/stores/${widget.storeId}/inventory/$id');
      loadInventory();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Inventory',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _AddInventoryDialog(
                        storeId: widget.storeId, onSuccess: loadInventory),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: inventory.isEmpty
                ? const Center(
                    child: Text('No inventory items found for this store.'))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      itemCount: inventory.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final item = inventory[index];
                        final isLow = (item['quantity'] ?? 0) <=
                            (item['minimumThreshold'] ?? 10);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppTheme.primary),
                          ),
                          title: Text(item['itemName'] ?? 'Unknown Item',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy)),
                          subtitle:
                              Text('Category: ${item['category'] ?? '-'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['quantity'] ?? 0} ${item['unit'] ?? ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isLow ? Colors.red : AppTheme.navy,
                                    ),
                                  ),
                                  if (isLow)
                                    const Text('Low Stock',
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                onPressed: () => _deleteItem(item['id']),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          )
        ],
      ),
    );
  }
}

class _AddInventoryDialog extends StatefulWidget {
  final String storeId;
  final VoidCallback onSuccess;
  const _AddInventoryDialog({required this.storeId, required this.onSuccess});

  @override
  State<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<_AddInventoryDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _threshCtrl = TextEditingController();
  String _category = 'Detergent';
  String _unit = 'Liters';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty ||
        _qtyCtrl.text.isEmpty ||
        _threshCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio
          .post('/api/admin-panel/stores/${widget.storeId}/inventory', data: {
        'itemName': _nameCtrl.text,
        'category': _category,
        'quantity': int.parse(_qtyCtrl.text),
        'minimumThreshold': int.parse(_threshCtrl.text),
        'unit': _unit,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Detergent', 'Softener', 'Packaging', 'Supplies', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _qtyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: ['Liters', 'Kg', 'Pieces', 'Boxes']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _threshCtrl,
                decoration: const InputDecoration(
                    labelText: 'Minimum Threshold (Alert)'),
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
              : const Text('Add'),
        ),
      ],
    );
  }
}
