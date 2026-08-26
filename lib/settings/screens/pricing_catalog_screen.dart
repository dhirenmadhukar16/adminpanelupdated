import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class PricingCatalogScreen extends StatefulWidget {
  const PricingCatalogScreen({super.key});

  @override
  State<PricingCatalogScreen> createState() => _PricingCatalogScreenState();
}

class _PricingCatalogScreenState extends State<PricingCatalogScreen> {
  bool loading = true;
  List categories = [];
  List services = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final catRes = await ApiClient.dio.get('/api/admin/catalog/categories');
      final servRes = await ApiClient.dio.get('/api/admin/catalog');
      if (mounted) {
        setState(() {
          categories = catRes.data;
          services = servRes.data;
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

    final mainCategories =
        categories.where((c) => c['parentId'] == null).toList();

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
                const Text('Service Catalog',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.category, size: 16),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddServiceDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Service'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: mainCategories.length,
                itemBuilder: (context, i) {
                  final mainCat = mainCategories[i];
                  final subCats = categories
                      .where((c) => c['parentId'] == mainCat['id'])
                      .toList();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(mainCat['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: subCats.map((subCat) {
                        final catServices = services
                            .where((s) => s['categoryId'] == subCat['id'])
                            .toList();
                        return ExpansionTile(
                          title: Text(subCat['name']),
                          children: catServices.map((srv) {
                            return ListTile(
                              leading: const Icon(Icons.local_laundry_service,
                                  color: AppTheme.primary),
                              title: Text(srv['itemName']),
                              subtitle: Text('Base Price: ₹${srv['price']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditServiceDialog(srv),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    String? parentId;
    final mainCategories =
        categories.where((c) => c['parentId'] == null).toList();

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Add Category'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Category Name')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: parentId,
                        decoration: const InputDecoration(
                            labelText: 'Parent Category (Optional)'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('None (Main Category)')),
                          ...mainCategories.map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name'])))
                        ],
                        onChanged: (v) => setDialogState(() => parentId = v),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await ApiClient.dio
                              .post('/api/admin/catalog/categories', data: {
                            'name': nameCtrl.text,
                            'parentId': parentId
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            loadData();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: const Text('Save'),
                    )
                  ],
                )));
  }

  void _showEditServiceDialog(Map<String, dynamic> srv) {
    final nameCtrl = TextEditingController(text: srv['itemName']);
    final priceCtrl =
        TextEditingController(text: srv['price']?.toString() ?? '');
    final minPriceCtrl =
        TextEditingController(text: srv['minPrice']?.toString() ?? '');
    final maxPriceCtrl =
        TextEditingController(text: srv['maxPrice']?.toString() ?? '');
    String? categoryId = srv['categoryId']?.toString();
    final subCats = categories.where((c) => c['parentId'] != null).toList();

    List<Map<String, dynamic>> variants = List<Map<String, dynamic>>.from(
        (srv['variants'] as List<dynamic>? ?? []).map((v) => {
              'id': v['id'],
              'variantName': v['variantName'],
              'price': v['price'],
              'minPrice': v['minPrice'],
              'maxPrice': v['maxPrice'],
            }));

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Edit Service'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: categoryId,
                            decoration: const InputDecoration(
                                labelText: 'Sub Category'),
                            items: subCats
                                .map((c) => DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text(c['name'])))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => categoryId = v),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Service Name')),
                          const SizedBox(height: 16),
                          TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Base Price')),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: TextField(
                                      controller: minPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Min Price'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextField(
                                      controller: maxPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Max Price'))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Variants',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...variants.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var v = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                              initialValue: v['variantName'],
                                              decoration: const InputDecoration(
                                                  labelText: 'Variant Name'),
                                              onChanged: (val) =>
                                                  v['variantName'] = val)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                              initialValue:
                                                  v['price']?.toString() ?? '',
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Price'),
                                              onChanged: (val) => v['price'] =
                                                  double.tryParse(val) ?? 0)),
                                      IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => setDialogState(
                                              () => variants.removeAt(idx)))
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: TextFormField(
                                              initialValue:
                                                  v['minPrice']?.toString() ??
                                                      '',
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Min Price'),
                                              onChanged: (val) =>
                                                  v['minPrice'] =
                                                      double.tryParse(val))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: TextFormField(
                                              initialValue:
                                                  v['maxPrice']?.toString() ??
                                                      '',
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Max Price'),
                                              onChanged: (val) =>
                                                  v['maxPrice'] =
                                                      double.tryParse(val))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setDialogState(() => variants.add({
                                  'variantName': '',
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
                      onPressed: () async {
                        try {
                          await ApiClient.dio
                              .put('/api/admin/catalog/${srv['id']}', data: {
                            'categoryId': categoryId,
                            'itemName': nameCtrl.text,
                            'price': double.tryParse(priceCtrl.text) ?? 0,
                            'minPrice': double.tryParse(minPriceCtrl.text),
                            'maxPrice': double.tryParse(maxPriceCtrl.text),
                            'variants': variants
                                .map((v) => {
                                      'id': v['id'],
                                      'variantName': v['variantName'],
                                      'price': v['price'],
                                      'minPrice': v['minPrice'],
                                      'maxPrice': v['maxPrice']
                                    })
                                .toList()
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            loadData();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: const Text('Save'),
                    )
                  ],
                )));
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minPriceCtrl = TextEditingController();
    final maxPriceCtrl = TextEditingController();
    String? categoryId;
    final subCats = categories.where((c) => c['parentId'] != null).toList();

    List<Map<String, dynamic>> variants = [];

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Add Service with Variants'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: categoryId,
                            decoration: const InputDecoration(
                                labelText: 'Sub Category'),
                            items: subCats
                                .map((c) => DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text(c['name'])))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => categoryId = v),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Service Name (e.g. Shirt)')),
                          const SizedBox(height: 16),
                          TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Base Price')),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: TextField(
                                      controller: minPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Min Price'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextField(
                                      controller: maxPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Max Price'))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Variants',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...variants.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var v = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                              initialValue: v['variantName'],
                                              decoration: const InputDecoration(
                                                  labelText: 'Variant Name'),
                                              onChanged: (val) =>
                                                  v['variantName'] = val)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                              initialValue:
                                                  v['price'].toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Price'),
                                              onChanged: (val) => v['price'] =
                                                  double.tryParse(val) ?? 0)),
                                      IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => setDialogState(
                                              () => variants.removeAt(idx)))
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: TextFormField(
                                              initialValue:
                                                  v['minPrice']?.toString() ??
                                                      '',
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Min Price'),
                                              onChanged: (val) =>
                                                  v['minPrice'] =
                                                      double.tryParse(val))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: TextFormField(
                                              initialValue:
                                                  v['maxPrice']?.toString() ??
                                                      '',
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Max Price'),
                                              onChanged: (val) =>
                                                  v['maxPrice'] =
                                                      double.tryParse(val))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setDialogState(() => variants.add({
                                  'variantName': '',
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
                      onPressed: () async {
                        try {
                          await ApiClient.dio.post('/api/admin/catalog', data: {
                            'categoryId': categoryId,
                            'itemName': nameCtrl.text,
                            'price': double.tryParse(priceCtrl.text) ?? 0,
                            'minPrice': double.tryParse(minPriceCtrl.text),
                            'maxPrice': double.tryParse(maxPriceCtrl.text),
                            'variants': variants
                                .map((v) => {
                                      'variantName': v['variantName'],
                                      'price': v['price'],
                                      'minPrice': v['minPrice'],
                                      'maxPrice': v['maxPrice']
                                    })
                                .toList()
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            loadData();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: const Text('Save'),
                    )
                  ],
                )));
  }
}
