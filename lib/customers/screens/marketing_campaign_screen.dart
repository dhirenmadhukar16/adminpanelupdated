import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class MarketingCampaignScreen extends StatefulWidget {
  final List<String> customerIds;
  const MarketingCampaignScreen({super.key, required this.customerIds});

  @override
  State<MarketingCampaignScreen> createState() =>
      _MarketingCampaignScreenState();
}

class _MarketingCampaignScreenState extends State<MarketingCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      // Create a notification for each selected customer
      for (final id in widget.customerIds) {
        await ApiClient.dio.post('/api/notifications', data: {
          'title': _titleCtrl.text,
          'message': _messageCtrl.text,
          'senderType': 'ADMIN',
          'senderId': '00000000-0000-0000-0000-000000000000', // Mock Admin UUID
          'receiverType': 'CUSTOMER',
          'receiverId': id,
          'notificationType': 'MARKETING',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Campaign sent to ${widget.customerIds.length} customers!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Campaign',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppTheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Sending to ${widget.customerIds.length} selected customers',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: 'Campaign Title',
                  prefixIcon: const Icon(Icons.title, color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 5,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: 'Campaign Message',
                  prefixIcon:
                      const Icon(Icons.message, color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _sending || widget.customerIds.isEmpty
                      ? null
                      : _sendCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(
                    _sending ? 'Sending...' : 'Send Campaign',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
