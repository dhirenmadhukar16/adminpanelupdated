import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'add_edit_store_screen.dart';
import 'store_detail_screen.dart';

final storesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.dio.get('/api/admin-panel/stores/stats');
  return response.data as List<dynamic>;
});

class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stores',
                    style: TextStyle(
                        fontSize: 28,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddEditStoreScreen(
                              onSaved: () => ref.refresh(storesListProvider))),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Store',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 2,
                              child: Text('Manager',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('Today\'s Orders',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('Revenue',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          Expanded(
                              flex: 1,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mutedText))),
                          SizedBox(width: 48), // For actions
                        ],
                      ),
                    ),
                    // Table Body
                    Expanded(
                      child: storesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                            child: Text('Error: $err',
                                style: const TextStyle(color: Colors.red))),
                        data: (stores) {
                          if (stores.isEmpty)
                            return const Center(
                                child: Text('No stores found.'));
                          return ListView.separated(
                            itemCount: stores.length,
                            separatorBuilder: (context, index) => const Divider(
                                height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final s = stores[index];
                              return InkWell(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            StoreDetailScreen(store: s))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                  Icons.storefront,
                                                  color: AppTheme.primary),
                                            ),
                                            const SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    s['storeName'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: AppTheme.navy)),
                                                Text(s['city'] ?? 'Location',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .mutedText)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('John Smith',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme
                                                    .navy)), // Placeholder manager
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text('${s['totalOrders'] ?? 0}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.navy)),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                            '₹${s['totalRevenue'] ?? 0}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary)),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: const Text('Active',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: const Icon(Icons.more_vert,
                                              color: AppTheme.mutedText),
                                          onPressed: () {},
                                        ),
                                      )
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
