import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class StoreMachinesTab extends StatefulWidget {
  final String storeId;
  const StoreMachinesTab({super.key, required this.storeId});

  @override
  State<StoreMachinesTab> createState() => _StoreMachinesTabState();
}

class _StoreMachinesTabState extends State<StoreMachinesTab> {
  bool loading = true;
  List machines = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadMachines();
  }

  Future<void> loadMachines() async {
    try {
      final response = await ApiClient.dio
          .get('/api/admin-panel/stores/${widget.storeId}/machines');
      if (mounted) {
        setState(() {
          machines = response.data;
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

  Future<void> _deleteMachine(String id) async {
    try {
      await ApiClient.dio
          .delete('/api/admin-panel/stores/${widget.storeId}/machines/$id');
      loadMachines();
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
              const Text('Active Equipment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _AddMachineDialog(
                        storeId: widget.storeId, onSuccess: loadMachines),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Machine'),
              )
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: machines.map((m) => _buildMachineCard(m)).toList(),
          ),
          if (machines.isEmpty)
            const Text('No machines found. Click Add Machine to begin.',
                style: TextStyle(color: AppTheme.mutedText)),
        ],
      ),
    );
  }

  Widget _buildMachineCard(dynamic m) {
    final status = m['status'] ?? 'ACTIVE';
    final isBroken = status == 'BROKEN';
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isBroken ? AppTheme.error : const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_laundry_service,
                  color: isBroken ? AppTheme.error : AppTheme.primary,
                  size: 32),
              const Spacer(),
              Chip(
                label: Text(status,
                    style: TextStyle(
                        fontSize: 10,
                        color: isBroken ? AppTheme.error : AppTheme.success)),
                backgroundColor: (isBroken ? AppTheme.error : AppTheme.success)
                    .withValues(alpha: 0.1),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () => _deleteMachine(m['id']),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(m['name'] ?? 'Unnamed Machine',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('Type: ${m['machineType'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 13, color: AppTheme.mutedText)),
        ],
      ),
    );
  }
}

class _AddMachineDialog extends StatefulWidget {
  final String storeId;
  final VoidCallback onSuccess;
  const _AddMachineDialog({required this.storeId, required this.onSuccess});

  @override
  State<_AddMachineDialog> createState() => _AddMachineDialogState();
}

class _AddMachineDialogState extends State<_AddMachineDialog> {
  final _nameCtrl = TextEditingController();
  String _machineType = 'Washer';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio
          .post('/api/admin-panel/stores/${widget.storeId}/machines', data: {
        'name': _nameCtrl.text,
        'machineType': _machineType,
        'status': 'ACTIVE',
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
      title: const Text('Add Machine'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Machine Name (e.g. W1, D1)')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _machineType,
            decoration: const InputDecoration(labelText: 'Machine Type'),
            items: ['Washer', 'Dryer', 'Iron']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _machineType = val!),
          ),
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
