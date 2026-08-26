import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool loading = true;
  String? error;
  List settings = [];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-settings');

      setState(() {
        settings = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveSetting(String key, String value, String description) async {
    await ApiClient.dio.post(
      '/api/admin-settings',
      data: {
        'settingKey': key,
        'settingValue': value,
        'description': description,
      },
    );

    await loadSettings();
  }

  void openSettingDialog([Map? setting]) {
    final keyController = TextEditingController(
      text: setting?['settingKey'] ?? '',
    );
    final valueController = TextEditingController(
      text: setting?['settingValue'] ?? '',
    );
    final descController = TextEditingController(
      text: setting?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(setting == null ? 'Add Setting' : 'Update Setting'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Setting Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Setting Value',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await saveSetting(
                keyController.text.trim(),
                valueController.text.trim(),
                descController.text.trim(),
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String category(String key) {
    if (key.contains('GST') || key.contains('TAX') || key.contains('INVOICE')) {
      return 'Finance';
    }
    if (key.contains('PICKUP') || key.contains('DELIVERY')) {
      return 'Booking';
    }
    if (key.contains('SUPPORT')) {
      return 'Support';
    }
    if (key.contains('TRUCK') || key.contains('GPS')) {
      return 'Logistics';
    }
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'System Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadSettings, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => openSettingDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Setting'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView.separated(
                itemCount: settings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final s = settings[index];
                  final key = s['settingKey']?.toString() ?? '';

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: Icon(Icons.settings, color: AppTheme.primary),
                      ),
                      title: Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${s['description'] ?? ''}\nCategory: ${category(key)}',
                      ),
                      trailing: SizedBox(
                        width: 260,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                s['settingValue']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => openSettingDialog(s),
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
