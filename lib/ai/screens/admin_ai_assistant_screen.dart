import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class AdminAiAssistantScreen extends StatefulWidget {
  const AdminAiAssistantScreen({super.key});

  @override
  State<AdminAiAssistantScreen> createState() => _AdminAiAssistantScreenState();
}

class _AdminAiAssistantScreenState extends State<AdminAiAssistantScreen> {
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello Devansh! I am WhiteFox AI, your operational copilot. How can I assist you with your business today?'},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final query = _controller.text;
    
    setState(() {
      _messages.add({'role': 'user', 'text': query});
    });
    
    _controller.clear();
    
    // Simulating thinking...
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;

    if (query.toLowerCase().contains('report') || query.toLowerCase().contains('revenue')) {
      try {
        final response = await ApiClient.dio.get('/api/admin-panel/finance/settlements');
        final settlements = response.data as List<dynamic>;
        double totalRev = 0;
        for (var s in settlements) {
          totalRev += (s['totalRevenue'] ?? 0);
        }
        
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'I analyzed the real-time database. 📊\n\nBased on all verified settlements across the franchise network, the total aggregated revenue is ₹${totalRev.toStringAsFixed(0)}.\n\nAll data is pulled dynamically from the live PostgreSQL database.'
          });
        });
      } catch (e) {
        setState(() {
          _messages.add({'role': 'ai', 'text': 'Error querying database: $e'});
        });
      }
    } else {
       setState(() {
         _messages.add({'role': 'ai', 'text': 'I am the AI Copilot configured for read-only database queries. I can analyze revenue and reports but I cannot modify data.'});
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: AppTheme.primary, size: 32),
                SizedBox(width: 16),
                Text('WhiteFox AI Copilot', style: TextStyle(fontSize: 28, color: AppTheme.navy, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Automate tasks, run predictive analytics, and generate reports instantly.', style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(32),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isUser ? AppTheme.primary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                                  bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isUser ? Colors.white : AppTheme.navy,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Ask me anything (e.g., "Generate a report for Bandra store...").',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.send, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
