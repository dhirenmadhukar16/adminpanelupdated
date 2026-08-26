import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final marketingProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response =
        await ApiClient.dio.get('/api/admin-panel/marketing/campaigns');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminMarketingScreen extends ConsumerWidget {
  const AdminMarketingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketingAsync = ref.watch(marketingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _CreateCampaignDialog(
              onSuccess: () => ref.refresh(marketingProvider),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Campaign',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marketing Campaigns',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Campaigns & Promotions (from PostgreSQL)',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: marketingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) {
                  if (data.isEmpty)
                    return const Center(
                        child: Text(
                            'No active campaigns found. Click "Create Campaign" to start.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final camp = data[index];
                      return ListTile(
                        leading: const Icon(Icons.campaign,
                            color: AppTheme.primary, size: 32),
                        title: Text(camp['name'] ?? 'Unnamed',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Channel: ${camp['channel']} • Target: ${camp['targetCount']} users'),
                        trailing: Chip(
                          label: Text(camp['status'] ?? 'DRAFT',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: camp['status'] == 'SENT'
                              ? Colors.green
                              : (camp['status'] == 'SCHEDULED'
                                  ? Colors.orange
                                  : Colors.grey),
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

class _CreateCampaignDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CreateCampaignDialog({required this.onSuccess});

  @override
  State<_CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends State<_CreateCampaignDialog> {
  final _nameCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _channel = 'EMAIL';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin-panel/marketing/campaigns', data: {
        'name': _nameCtrl.text,
        'channel': _channel,
        'content': _contentCtrl.text,
        'targetCount': 1000,
        'status': 'SCHEDULED'
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
      title: const Text('Create Campaign'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Campaign Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Channel'),
              items: ['EMAIL', 'SMS', 'PUSH']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _channel = val!),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Content Body')),
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
              : const Text('Schedule'),
        ),
      ],
    );
  }
}
