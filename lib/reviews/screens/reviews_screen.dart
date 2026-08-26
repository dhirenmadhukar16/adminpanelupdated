import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool loading = true;
  String? error;
  List reviews = [];

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final response = await ApiClient.dio.get('/api/admin-panel/reviews');

      setState(() {
        reviews = response.data as List;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: loadReviews, icon: const Icon(Icons.refresh)),
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
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final r = reviews[index];

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: Icon(Icons.star, color: AppTheme.primary),
                      ),
                      title: Text(
                        '${r['customerName'] ?? 'Customer'} • ${r['orderNumber'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Store: ${r['storeName'] ?? '-'} | Rider: ${r['riderName'] ?? '-'}\n'
                        'Feedback: ${r['feedback'] ?? '-'}',
                      ),
                      trailing: Text(
                        '⭐ ${r['overallRating'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
