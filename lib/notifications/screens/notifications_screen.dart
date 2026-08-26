import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  String? error;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/notifications');

      setState(() {
        notifications = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createNotification() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final receiverTypeController = TextEditingController(text: 'ALL');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Notification'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: receiverTypeController,
                decoration: const InputDecoration(
                  labelText: 'Receiver Type: ALL / CUSTOMER / STORE / RIDER',
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
              await ApiClient.dio.post(
                '/api/notifications',
                data: {
                  'title': titleController.text.trim(),
                  'message': messageController.text.trim(),
                  'senderType': 'ADMIN',
                  'senderId': null,
                  'receiverType': receiverTypeController.text.trim(),
                  'receiverId': null,
                  'notificationType': 'INFO',
                },
              );

              if (mounted) Navigator.pop(context);
              await loadNotifications();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Color typeColor(String? type) {
    switch (type) {
      case 'SUCCESS':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: createNotification,
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final n = notifications[index];
                      final type = n['notificationType']?.toString();

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                typeColor(type).withValues(alpha: 0.15),
                            child: Icon(
                              Icons.notifications,
                              color: typeColor(type),
                            ),
                          ),
                          title: Text(
                            n['title'] ?? 'Notification',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${n['message'] ?? ''}\n'
                            'To: ${n['receiverType'] ?? '-'} | From: ${n['senderType'] ?? '-'} | ${n['createdAt'] ?? '-'}',
                          ),
                          trailing: Chip(
                            label:
                                Text(n['isRead'] == true ? 'READ' : 'UNREAD'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
