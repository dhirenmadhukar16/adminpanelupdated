import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GarmentsTimelineScreen extends StatelessWidget {
  const GarmentsTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'title': 'Pickup', 'status': 'done', 'time': '10:00 AM'},
      {'title': 'Store Arrival', 'status': 'done', 'time': '11:15 AM'},
      {'title': 'Sorting & Tagging', 'status': 'done', 'time': '11:45 AM'},
      {'title': 'Washing', 'status': 'active', 'time': 'In Progress...'},
      {'title': 'Drying', 'status': 'pending', 'time': ''},
      {'title': 'Ironing', 'status': 'pending', 'time': ''},
      {'title': 'Quality Check', 'status': 'pending', 'time': ''},
      {'title': 'Packing', 'status': 'pending', 'time': ''},
      {'title': 'Ready for Dispatch', 'status': 'pending', 'time': ''},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Garment Manufacturing Workflow',
                style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Batch: #B-49201 | Items: 45',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: ListView.builder(
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    final isDone = stage['status'] == 'done';
                    final isActive = stage['status'] == 'active';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.success
                                    : (isActive
                                        ? AppTheme.warning
                                        : Colors.grey.shade200),
                                shape: BoxShape.circle,
                                border: isActive
                                    ? Border.all(
                                        color: AppTheme.warning
                                            .withValues(alpha: 0.3),
                                        width: 4)
                                    : null,
                              ),
                              child: Icon(
                                isDone
                                    ? Icons.check
                                    : (isActive ? Icons.sync : Icons.circle),
                                color: isDone || isActive
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 16,
                              ),
                            ),
                            if (index < stages.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: isDone
                                    ? AppTheme.success
                                    : Colors.grey.shade200,
                              ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage['title']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isActive || isDone
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isDone || isActive
                                        ? AppTheme.navy
                                        : AppTheme.mutedText,
                                  ),
                                ),
                                if (stage['time']!.isNotEmpty)
                                  Text(
                                    stage['time']!,
                                    style: TextStyle(
                                      color: isActive
                                          ? AppTheme.warning
                                          : AppTheme.mutedText,
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
