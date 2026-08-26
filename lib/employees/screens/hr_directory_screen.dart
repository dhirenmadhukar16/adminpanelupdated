import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class HRDirectoryScreen extends StatefulWidget {
  const HRDirectoryScreen({super.key});

  @override
  State<HRDirectoryScreen> createState() => _HRDirectoryScreenState();
}

class _HRDirectoryScreenState extends State<HRDirectoryScreen> {
  bool loading = true;
  List leaves = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadLeaves();
  }

  Future<void> loadLeaves() async {
    try {
      final response =
          await ApiClient.dio.get('/api/admin-panel/hroperations/leaves');
      if (mounted) {
        setState(() {
          leaves = response.data;
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Human Resources & Leave Management',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leave Requests Queue',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: leaves.length,
                        separatorBuilder: (_, __) => const Divider(height: 32),
                        itemBuilder: (context, index) {
                          final leave = leaves[index];
                          return Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryLight
                                    .withValues(alpha: 0.1),
                                child: Text((leave['employeeName'] ?? 'E')[0],
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        leave['employeeName'] ??
                                            'Unknown Employee',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.navy)),
                                    Text(
                                        leave['reason'] ?? 'No reason provided',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.mutedText)),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(leave['status'] ?? 'PENDING',
                                    style: const TextStyle(
                                        fontSize: 10, color: AppTheme.warning)),
                                backgroundColor:
                                    AppTheme.warning.withValues(alpha: 0.1),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                  icon: const Icon(Icons.check,
                                      color: AppTheme.success),
                                  onPressed: () {}),
                              IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppTheme.error),
                                  onPressed: () {}),
                            ],
                          );
                        },
                      ),
                    ),
                    if (leaves.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No leave requests pending.',
                              style: TextStyle(color: AppTheme.mutedText)),
                        ),
                      ),
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
