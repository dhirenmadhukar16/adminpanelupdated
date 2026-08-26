import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class StoreExpensesTab extends StatefulWidget {
  final String storeId;
  const StoreExpensesTab({super.key, required this.storeId});

  @override
  State<StoreExpensesTab> createState() => _StoreExpensesTabState();
}

class _StoreExpensesTabState extends State<StoreExpensesTab> {
  bool loading = true;
  List expenses = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final response = await ApiClient.dio
          .get('/api/admin-panel/stores/${widget.storeId}/expenses');
      if (mounted) {
        setState(() {
          expenses = response.data;
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

  Future<void> _deleteExpense(String id) async {
    try {
      await ApiClient.dio
          .delete('/api/admin-panel/stores/${widget.storeId}/expenses/$id');
      loadExpenses();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Ledger & Expenses',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _AddExpenseDialog(
                        storeId: widget.storeId, onSuccess: loadExpenses),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Expense'),
              )
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.softShadow,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final ex = expenses[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt, color: AppTheme.warning),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex['category'] ?? 'Expense',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy)),
                          Text(ex['description'] ?? 'No description',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.mutedText)),
                        ],
                      ),
                    ),
                    Text('₹${ex['amount'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.error)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _deleteExpense(ex['id']),
                    )
                  ],
                );
              },
            ),
          ),
          if (expenses.isEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No expenses recorded.',
                    style: TextStyle(color: AppTheme.mutedText))),
        ],
      ),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final String storeId;
  final VoidCallback onSuccess;
  const _AddExpenseDialog({required this.storeId, required this.onSuccess});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Utilities';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio
          .post('/api/admin-panel/stores/${widget.storeId}/expenses', data: {
        'category': _category,
        'description': _descCtrl.text,
        'amount': double.parse(_amountCtrl.text),
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
      title: const Text('Log Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Utilities', 'Maintenance', 'Rent', 'Supplies', 'Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _category = val!),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2),
        ],
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
