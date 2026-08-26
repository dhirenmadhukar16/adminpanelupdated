import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final serviceCategoriesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin/catalog/categories');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final serviceCatalogProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin/catalog');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminGarmentsScreen extends ConsumerWidget {
  const AdminGarmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final catalogAsync = ref.watch(serviceCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addCat',
            onPressed: () {
              final cats =
                  ref.read(serviceCategoriesProvider).asData?.value ?? [];
              showDialog(
                context: context,
                builder: (context) => _CreateCategoryDialog(
                  categories: cats,
                  onSuccess: () => ref.refresh(serviceCategoriesProvider),
                ),
              );
            },
            backgroundColor: AppTheme.navy,
            icon: const Icon(Icons.category, color: Colors.white),
            label: const Text('Add Category',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'addSer',
            onPressed: () {
              final cats =
                  ref.read(serviceCategoriesProvider).asData?.value ?? [];
              if (cats.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please add a category first.')));
                return;
              }
              showDialog(
                context: context,
                builder: (context) => _CreateServiceDialog(
                  categories: cats,
                  onSuccess: () => ref.refresh(serviceCatalogProvider),
                ),
              );
            },
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Service',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Global Services & Pricing Catalog',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Master catalog of services and garments, grouped by categories. Prices updated here sync to all stores instantly.',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            Expanded(
              child: categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Error loading categories: $err')),
                  data: (categories) {
                    if (categories.isEmpty)
                      return const Center(
                          child: Text(
                              'No categories found. Start by adding one!'));

                    return catalogAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) =>
                            Center(child: Text('Error loading catalog: $err')),
                        data: (catalog) {
                          final mainCategories = categories
                              .where((c) => c['parentId'] == null)
                              .toList();

                          return ListView.builder(
                            itemCount: mainCategories.length,
                            itemBuilder: (context, index) {
                              final mainCat = mainCategories[index];
                              final subCats = categories
                                  .where((c) =>
                                      c['parentId'] != null &&
                                      c['parentId'] == mainCat['id'])
                                  .toList();

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                        color: Colors.grey.shade200)),
                                child: ExpansionTile(
                                  title: Text(mainCat['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppTheme.navy)),
                                  children: [
                                    if (subCats.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                            'No sub-categories. Services should be under sub-categories.',
                                            style: TextStyle(
                                                color: AppTheme.mutedText)),
                                      ),
                                    ...subCats.map((subCat) {
                                      final catServices = catalog
                                          .where((s) =>
                                              s['categoryId'] == subCat['id'])
                                          .toList();

                                      return Container(
                                        decoration: BoxDecoration(
                                            border: Border(
                                                top: BorderSide(
                                                    color:
                                                        Colors.grey.shade200))),
                                        child: ExpansionTile(
                                          title: Text(subCat['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.navy)),
                                          children: [
                                            if (catServices.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                    'No services found in this sub-category.',
                                                    style: TextStyle(
                                                        color: AppTheme
                                                            .mutedText)),
                                              ),
                                            ...catServices.map((srv) {
                                              final variants = srv['variants']
                                                      as List<dynamic>? ??
                                                  [];
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 8),
                                                leading: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .primaryLight
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  child: srv['thumbnailUrl'] != null &&
                                                          srv['thumbnailUrl']
                                                              .isNotEmpty
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8),
                                                          child: Image.network(srv['thumbnailUrl'],
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => const Icon(
                                                                  Icons.image,
                                                                  color: AppTheme
                                                                      .primaryLight)))
                                                      : const Icon(
                                                          Icons.local_laundry_service,
                                                          color: AppTheme.primaryLight),
                                                ),
                                                title: Text(srv['itemName'],
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                subtitle: Text(
                                                    'Base Price: ₹${srv['price']} • Variants: ${(srv['variants'] as List? ?? []).length}'),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: AppTheme.navy),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          _EditServiceDialog(
                                                        categories: categories,
                                                        item: srv,
                                                        onSuccess: () =>
                                                            ref.refresh(
                                                                serviceCatalogProvider),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            })
                                          ],
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              );
                            },
                          );
                        });
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  final List<dynamic> categories;
  final VoidCallback onSuccess;
  const _CreateCategoryDialog(
      {required this.categories, required this.onSuccess});

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _nameCtrl = TextEditingController();
  String? _parentId;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin/catalog/categories',
          data: {'name': _nameCtrl.text, 'parentId': _parentId});
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainCats =
        widget.categories.where((c) => c['parentId'] == null).toList();
    return AlertDialog(
      title: const Text('Add Category'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category Name (e.g. Dry Clean, Male)')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _parentId,
              decoration: const InputDecoration(
                  labelText: 'Parent Category (Leave blank for Main Category)'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('None (Make it a Main Category)')),
                ...mainCats.map((c) => DropdownMenuItem<String>(
                    value: c['id'], child: Text(c['name'])))
              ],
              onChanged: (val) => setState(() => _parentId = val),
            ),
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
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  final List<dynamic> categories;
  final VoidCallback onSuccess;
  const _CreateServiceDialog(
      {required this.categories, required this.onSuccess});

  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  String? _categoryId;
  final _itemNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _thumbnailCtrl = TextEditingController();
  bool _isLoading = false;
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    final subCats =
        widget.categories.where((c) => c['parentId'] != null).toList();
    if (subCats.isNotEmpty) {
      _categoryId = subCats.first['id'];
    }
  }

  Future<void> _submit() async {
    if (_categoryId == null ||
        _itemNameCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin/catalog', data: {
        'categoryId': _categoryId,
        'itemName': _itemNameCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'minPrice': double.tryParse(_minPriceCtrl.text),
        'maxPrice': double.tryParse(_maxPriceCtrl.text),
        'thumbnailUrl':
            _thumbnailCtrl.text.isEmpty ? null : _thumbnailCtrl.text,
        'variants': _variants
            .map((v) => {
                  'variantName': v['name'],
                  'price': v['price'],
                  'minPrice': v['minPrice'],
                  'maxPrice': v['maxPrice']
                })
            .toList()
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCats =
        widget.categories.where((c) => c['parentId'] != null).toList();

    return AlertDialog(
      title: const Text('Create Global Service'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Sub-Category'),
                items: subCats.map((c) {
                  final parent = widget.categories.firstWhere(
                      (p) => p['id'] == c['parentId'],
                      orElse: () => {'name': ''});
                  return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text("${parent['name']} > ${c['name']}"));
                }).toList(),
                onChanged: (val) => setState(() => _categoryId = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _itemNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Item Name (e.g. Shirt, Blanket)')),
              const SizedBox(height: 16),
              TextField(
                  controller: _priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Base Price (â‚¹)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _minPriceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Min Price (â‚¹)'),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _maxPriceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Max Price (â‚¹)'),
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _thumbnailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Thumbnail Image URL (Optional)')),
              const SizedBox(height: 24),
              const Text('Variants',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.navy)),
              const SizedBox(height: 8),
              const Text(
                  'Add variants like Premium, Normal, Express if needed. If none are added, just the base price is used.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
              const SizedBox(height: 16),
              ..._variants.asMap().entries.map((entry) {
                int idx = entry.key;
                var variant = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: TextFormField(
                                  initialValue: variant['name'],
                                  decoration: const InputDecoration(
                                      labelText: 'Variant Name',
                                      border: OutlineInputBorder()),
                                  onChanged: (v) => variant['name'] = v)),
                          const SizedBox(width: 8),
                          Expanded(
                              flex: 1,
                              child: TextFormField(
                                  initialValue: variant['price'].toString(),
                                  decoration: const InputDecoration(
                                      labelText: 'Price (₹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['price'] =
                                      double.tryParse(v) ?? 0)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _variants.removeAt(idx)))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  initialValue:
                                      variant['minPrice']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Min Price (₹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['minPrice'] =
                                      double.tryParse(v))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  initialValue:
                                      variant['maxPrice']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Max Price (₹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['maxPrice'] =
                                      double.tryParse(v))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _variants.add({
                      'name': '',
                      'price': 0.0,
                      'minPrice': null,
                      'maxPrice': null
                    })),
                icon: const Icon(Icons.add),
                label: const Text('Add Variant'),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading || subCats.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _EditServiceDialog extends StatefulWidget {
  final List<dynamic> categories;
  final Map<String, dynamic> item;
  final VoidCallback onSuccess;
  const _EditServiceDialog(
      {required this.categories, required this.item, required this.onSuccess});

  @override
  State<_EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<_EditServiceDialog> {
  String? _categoryId;
  late TextEditingController _itemNameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;
  late TextEditingController _thumbnailCtrl;
  bool _isLoading = false;
  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.item['categoryId'];
    _itemNameCtrl = TextEditingController(text: widget.item['itemName']);
    _priceCtrl = TextEditingController(text: widget.item['price'].toString());
    _minPriceCtrl =
        TextEditingController(text: widget.item['minPrice']?.toString() ?? '');
    _maxPriceCtrl =
        TextEditingController(text: widget.item['maxPrice']?.toString() ?? '');
    _thumbnailCtrl =
        TextEditingController(text: widget.item['thumbnailUrl'] ?? '');

    if (widget.item['variants'] != null) {
      _variants = List<Map<String, dynamic>>.from(
          (widget.item['variants'] as List).map((v) => {
                'id': v['id'],
                'name': v['variantName'],
                'price': v['price'],
                'minPrice': v['minPrice'],
                'maxPrice': v['maxPrice']
              }));
    }
  }

  Future<void> _submit() async {
    if (_categoryId == null ||
        _itemNameCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.put('/api/admin/catalog/${widget.item['id']}', data: {
        'categoryId': _categoryId,
        'itemName': _itemNameCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'minPrice': double.tryParse(_minPriceCtrl.text),
        'maxPrice': double.tryParse(_maxPriceCtrl.text),
        'thumbnailUrl':
            _thumbnailCtrl.text.isEmpty ? null : _thumbnailCtrl.text,
        'active': widget.item['active'] ?? true,
        'variants': _variants
            .map((v) => {
                  'id':
                      v['id'], // Optional, backend might ignore if updating all
                  'variantName': v['name'],
                  'price': v['price'],
                  'minPrice': v['minPrice'],
                  'maxPrice': v['maxPrice']
                })
            .toList()
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Delete Service'),
              content:
                  const Text('Are you sure you want to delete this service?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.delete('/api/admin/catalog/${widget.item['id']}');
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCats =
        widget.categories.where((c) => c['parentId'] != null).toList();

    return AlertDialog(
      title: const Text('Edit Global Service'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Sub-Category'),
                items: subCats.map((c) {
                  final parent = widget.categories.firstWhere(
                      (p) => p['id'] == c['parentId'],
                      orElse: () => {'name': ''});
                  return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text("${parent['name']} > ${c['name']}"));
                }).toList(),
                onChanged: (val) => setState(() => _categoryId = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _itemNameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name')),
              const SizedBox(height: 16),
              TextField(
                  controller: _priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Base Price (â‚¹)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _minPriceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Min Price (â‚¹)'),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _maxPriceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Max Price (â‚¹)'),
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _thumbnailCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Thumbnail Image URL')),
              const SizedBox(height: 24),
              const Text('Variants',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.navy)),
              const SizedBox(height: 8),
              ..._variants.asMap().entries.map((entry) {
                int idx = entry.key;
                var variant = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: TextFormField(
                                  initialValue: variant['name'],
                                  decoration: const InputDecoration(
                                      labelText: 'Variant Name',
                                      border: OutlineInputBorder()),
                                  onChanged: (v) => variant['name'] = v)),
                          const SizedBox(width: 8),
                          Expanded(
                              flex: 1,
                              child: TextFormField(
                                  initialValue: variant['price'].toString(),
                                  decoration: const InputDecoration(
                                      labelText: 'Price (â‚¹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['price'] =
                                      double.tryParse(v) ?? 0)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _variants.removeAt(idx)))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  initialValue:
                                      variant['minPrice']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Min Price (â‚¹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['minPrice'] =
                                      double.tryParse(v))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  initialValue:
                                      variant['maxPrice']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Max Price (â‚¹)',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => variant['maxPrice'] =
                                      double.tryParse(v))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _variants.add({
                      'name': '',
                      'price': 0.0,
                      'minPrice': null,
                      'maxPrice': null
                    })),
                icon: const Icon(Icons.add),
                label: const Text('Add Variant'),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _delete,
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
