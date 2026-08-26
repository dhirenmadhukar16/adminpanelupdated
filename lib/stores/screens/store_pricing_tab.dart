import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class StorePricingTab extends StatefulWidget {
  final String storeId;

  const StorePricingTab({super.key, required this.storeId});

  @override
  State<StorePricingTab> createState() => _StorePricingTabState();
}

class _StorePricingTabState extends State<StorePricingTab> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _pricingList = [];
  String? _selectedMainCategory;

  @override
  void initState() {
    super.initState();
    _fetchPricing();
  }

  Future<void> _fetchPricing() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await ApiClient.dio
          .get('/api/store-ops/stores/${widget.storeId}/pricing');

      if (mounted) {
        final data = response.data as List;
        final mainCats = <String>{};
        for (var item in data) {
          final cat =
              item['mainCategoryName'] ?? item['serviceType'] ?? 'General';
          mainCats.add(cat);
        }
        setState(() {
          _pricingList = data;
          _isLoading = false;
          if (_selectedMainCategory == null && mainCats.isNotEmpty) {
            _selectedMainCategory = mainCats.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePrice(
    String serviceId,
    double basePrice, {
    List<Map<String, dynamic>> variantPrices = const [],
  }) async {
    try {
      await ApiClient.dio.post(
        '/api/store-ops/stores/${widget.storeId}/pricing',
        data: {
          'serviceId': serviceId,
          'customPrice': basePrice,
          if (variantPrices.isNotEmpty) 'variantPrices': variantPrices,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Prices updated successfully!'),
              backgroundColor: Colors.green),
        );
        _fetchPricing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update price: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditPriceDialog(Map<String, dynamic> pricingItem) {
    final List variants = (pricingItem['variants'] as List?) ?? [];
    final bool hasVariants = variants.isNotEmpty;

    // Base price controller (used when no variants, or as fallback)
    final TextEditingController baseController = TextEditingController(
      text: (pricingItem['storeCustomPrice'] ?? pricingItem['globalPrice'] ?? 0)
          .toString(),
    );

    // Per-variant controllers — pre-filled with customPrice if set, else global price
    final Map<String, TextEditingController> variantControllers = {
      for (final v in variants)
        (v['id'] as String): TextEditingController(
          text: (v['customPrice'] ?? v['price'] ?? 0).toString(),
        ),
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Price: ${pricingItem['itemName']}'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb chip
                  if ((pricingItem['subCategoryName'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Chip(
                        label: Text(
                            '${pricingItem['mainCategoryName']} › ${pricingItem['subCategoryName']}'),
                        backgroundColor:
                            AppTheme.primaryLight.withValues(alpha: 0.1),
                      ),
                    ),
                  Text(
                    'Global Base Price: ₹${pricingItem['globalPrice']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  if (hasVariants) ...[
                    // Section header
                    const Text(
                      'Set Custom Price Per Variant',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Variant price rows
                    ...variants.map((v) {
                      final vId = v['id'] as String;
                      final globalVariantPrice = v['price'];
                      final hasCustom = v['customPrice'] != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            // Variant label
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v['variantName'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Global: ₹$globalVariantPrice',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Custom price input
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: variantControllers[vId],
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: hasCustom
                                      ? AppTheme.primary
                                      : Colors.black87,
                                  fontWeight: hasCustom
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Store Price',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.currency_rupee,
                                      size: 16),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  isDense: true,
                                  helperText:
                                      hasCustom ? 'Custom ✓' : 'Using global',
                                  helperStyle: TextStyle(
                                    fontSize: 10,
                                    color:
                                        hasCustom ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 20),
                    const Text(
                      'Base Service Price (fallback)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Base / single price field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: baseController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: hasVariants
                                ? 'Custom Base Price (₹)'
                                : 'Custom Store Price (₹)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                      if (hasVariants) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final baseVal = baseController.text.trim();
                              if (baseVal.isNotEmpty) {
                                for (final ctrl in variantControllers.values) {
                                  ctrl.text = baseVal;
                                }
                              }
                            },
                            icon: const Icon(Icons.copy_all, size: 18),
                            label: const Text('Apply to All'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final baseVal = double.tryParse(baseController.text.trim());
                if (baseVal == null) return;

                // Collect variant prices
                final variantPriceList = <Map<String, dynamic>>[];
                for (final v in variants) {
                  final vId = v['id'] as String;
                  final ctrl = variantControllers[vId];
                  final price = double.tryParse(ctrl?.text.trim() ?? '');
                  if (price != null) {
                    variantPriceList
                        .add({'variantId': vId, 'customPrice': price});
                  }
                }

                Navigator.pop(ctx);
                _updatePrice(
                  pricingItem['serviceId'],
                  baseVal,
                  variantPrices: variantPriceList,
                );
              },
              child: const Text('Save All Prices'),
            ),
          ],
        );
      },
    );
  }

  List<String> get _mainCategories {
    final cats = <String>{};
    for (var item in _pricingList) {
      final cat = item['mainCategoryName'] ?? item['serviceType'] ?? 'General';
      cats.add(cat);
    }
    return cats.toList();
  }

  List<dynamic> _itemsForCategory(String mainCat) {
    return _pricingList.where((item) {
      final cat = item['mainCategoryName'] ?? item['serviceType'] ?? 'General';
      return cat == mainCat;
    }).toList();
  }

  Map<String, List<dynamic>> _groupBySubCategory(List<dynamic> items) {
    final Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      final sub = (item['subCategoryName'] ?? '').toString().isEmpty
          ? 'General'
          : item['subCategoryName'];
      grouped.putIfAbsent(sub, () => []);
      grouped[sub]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPricing,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_pricingList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_laundry_service_outlined,
                size: 64, color: AppTheme.mutedText),
            SizedBox(height: 16),
            Text('No services found in global catalog.',
                style: TextStyle(color: AppTheme.mutedText)),
            SizedBox(height: 8),
            Text('Add services via the Global Services & Pricing panel.',
                style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
          ],
        ),
      );
    }

    final mainCategories = _mainCategories;

    return RefreshIndicator(
      onRefresh: _fetchPricing,
      child: Column(
        children: [
          // Main Category Tabs
          if (mainCategories.length > 1)
            Container(
              color: Colors.white,
              child: Row(
                children: mainCategories.map((cat) {
                  final isSelected = cat == _selectedMainCategory;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMainCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          cat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Services List
          Expanded(
            child: Builder(
              builder: (context) {
                final catItems = _itemsForCategory(
                    _selectedMainCategory ?? mainCategories.first);
                final grouped = _groupBySubCategory(catItems);

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final subCat = grouped.keys.elementAt(index);
                    final items = grouped[subCat]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-category header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                subCat,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items
                        ...items.map((item) {
                          final hasCustomPrice =
                              item['storeCustomPrice'] != null;
                          final currentPrice = hasCustomPrice
                              ? item['storeCustomPrice']
                              : item['globalPrice'];
                          final variants =
                              item['variants'] as List<dynamic>? ?? [];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.local_laundry_service_outlined,
                                        color: AppTheme.primary,
                                        size: 22),
                                  ),
                                  title: Text(
                                    item['itemName'] ?? 'Unknown Service',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (hasCustomPrice)
                                        Text(
                                          'Global: ₹${item['globalPrice']} (Custom override active)',
                                          style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11),
                                        ),
                                      if (variants.isNotEmpty)
                                        Text(
                                          '${variants.length} variant(s)',
                                          style: const TextStyle(
                                              color: AppTheme.mutedText,
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹$currentPrice',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: hasCustomPrice
                                              ? Colors.green
                                              : AppTheme.navy,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: AppTheme.primary),
                                        tooltip: 'Edit Store Price',
                                        onPressed: () =>
                                            _showEditPriceDialog(item),
                                      ),
                                    ],
                                  ),
                                ),
                                // Show variants inline if any
                                if (variants.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24, right: 24, bottom: 12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: variants.map<Widget>((v) {
                                        return Chip(
                                          label: Text(
                                              '${v['variantName']}: ₹${v['price']}'),
                                          backgroundColor: AppTheme.primaryLight
                                              .withValues(alpha: 0.08),
                                          labelStyle: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.navy),
                                          side: BorderSide(
                                              color: AppTheme.primaryLight
                                                  .withValues(alpha: 0.3)),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
