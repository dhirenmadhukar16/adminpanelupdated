import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final rolesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/roles');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _CreateRoleDialog(
              onSuccess: () => ref.refresh(rolesProvider),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Role',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Roles & Permissions',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Role Management (from PostgreSQL)',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: rolesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty)
                    return const Center(
                        child: Text(
                            'No custom roles defined. Click "Create Role" to add.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final role = data[index];
                      return ListTile(
                        leading: const Icon(Icons.admin_panel_settings,
                            color: AppTheme.primary, size: 32),
                        title: Text(role['roleName'] ?? 'Unknown Role',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(role['description'] ?? 'No description'),
                        trailing: Switch(
                          value: role['isActive'] ?? true,
                          onChanged: (val) {},
                          activeThumbColor: AppTheme.primary,
                        ),
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
}

class _CreateRoleDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CreateRoleDialog({required this.onSuccess});

  @override
  State<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<_CreateRoleDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _canManageStores = false;
  bool _canManageRiders = false;
  bool _canManageOrders = false;
  bool _canManageSettings = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin-panel/roles', data: {
        'roleName': _nameCtrl.text,
        'description': _descCtrl.text,
        'canManageStores': _canManageStores,
        'canManageRiders': _canManageRiders,
        'canManageOrders': _canManageOrders,
        'canManageSettings': _canManageSettings,
        'isActive': true,
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
      title: const Text('Create Role'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Role Name')),
              const SizedBox(height: 16),
              TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              CheckboxListTile(
                  title: const Text('Manage Stores'),
                  value: _canManageStores,
                  onChanged: (v) => setState(() => _canManageStores = v!)),
              CheckboxListTile(
                  title: const Text('Manage Riders'),
                  value: _canManageRiders,
                  onChanged: (v) => setState(() => _canManageRiders = v!)),
              CheckboxListTile(
                  title: const Text('Manage Orders'),
                  value: _canManageOrders,
                  onChanged: (v) => setState(() => _canManageOrders = v!)),
              CheckboxListTile(
                  title: const Text('Manage Settings'),
                  value: _canManageSettings,
                  onChanged: (v) => setState(() => _canManageSettings = v!)),
            ],
          ),
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
              : const Text('Create'),
        ),
      ],
    );
  }
}
