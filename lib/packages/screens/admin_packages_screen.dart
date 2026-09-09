import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> catalog = [];
  String filter = 'ALL';
  String search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/api/admin/packages'),
        ApiClient.dio.get('/api/admin/catalog'),
      ]);

      if (!mounted) return;
      setState(() {
        packages = _mapList(responses[0].data);
        catalog = _mapList(responses[1].data)
            .where((item) => item['active'] != false)
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => error = _errorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get visiblePackages {
    final query = search.trim().toLowerCase();
    return packages.where((item) {
      final published = item['published'] == true;
      final active = item['active'] != false;
      final matchesFilter = switch (filter) {
        'PUBLISHED' => published && active,
        'DRAFT' => !published && active,
        'ARCHIVED' => !active,
        _ => true,
      };
      final matchesSearch = query.isEmpty ||
          '${item['name'] ?? ''} ${item['description'] ?? ''}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _openEditor([Map<String, dynamic>? package]) async {
    if (catalog.isEmpty) {
      _showMessage(
          'Create active catalogue services before creating a package.');
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PackageEditorDialog(
        catalog: catalog,
        package: package,
      ),
    );
    if (saved == true) await _loadData();
  }

  Future<void> _changePublication(
    Map<String, dynamic> package,
    bool publish,
  ) async {
    final id = package['id'];
    if (id == null) return;

    try {
      await ApiClient.dio.patch(
        '/api/admin/packages/$id/${publish ? 'publish' : 'unpublish'}',
      );
      _showMessage(
        publish
            ? '${package['name']} is now visible to all customers.'
            : '${package['name']} has been unpublished.',
        success: true,
      );
      await _loadData();
    } catch (e) {
      _showMessage(_errorMessage(e));
    }
  }

  Future<void> _archive(Map<String, dynamic> package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive package?'),
        content: Text(
          '${package['name']} will immediately disappear from the customer app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiClient.dio.delete('/api/admin/packages/${package['id']}');
      _showMessage('Package archived.', success: true);
      await _loadData();
    } catch (e) {
      _showMessage(_errorMessage(e));
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final published = packages
        .where((item) => item['active'] != false && item['published'] == true)
        .length;
    final drafts = packages
        .where((item) => item['active'] != false && item['published'] != true)
        .length;
    final featured = packages
        .where((item) =>
            item['active'] != false &&
            item['published'] == true &&
            item['featured'] == true)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Packages',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Bundle catalogue services, set an offer price and publish it to every customer.',
                        style: TextStyle(color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loading ? null : _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: loading ? null : () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Package'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard('Published', published, Icons.campaign_rounded,
                    AppTheme.success),
                const SizedBox(width: 14),
                _statCard('Drafts', drafts, Icons.edit_note_rounded,
                    AppTheme.warning),
                const SizedBox(width: 14),
                _statCard('Featured', featured, Icons.star_rounded,
                    const Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => search = value),
                    decoration: const InputDecoration(
                      hintText: 'Search packages...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: filter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'ALL', child: Text('All packages')),
                      DropdownMenuItem(
                          value: 'PUBLISHED', child: Text('Published')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('Drafts')),
                      DropdownMenuItem(
                          value: 'ARCHIVED', child: Text('Archived')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => filter = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.navy)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return _ErrorPanel(message: error!, retry: _loadData);
    }
    final items = visiblePackages;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 54, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            const Text('No packages found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Create first package'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        return GridView.builder(
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 350,
          ),
          itemBuilder: (_, index) => _packageCard(items[index]),
        );
      },
    );
  }

  Widget _packageCard(Map<String, dynamic> item) {
    final active = item['active'] != false;
    final published = item['published'] == true;
    final featured = item['featured'] == true;
    final available = item['currentlyAvailable'] == true;
    final packageItems =
        item['items'] is List ? item['items'] as List : const [];

    final statusText = !active
        ? 'ARCHIVED'
        : published
            ? available
                ? 'LIVE'
                : 'SCHEDULED / EXPIRED'
            : 'DRAFT';
    final statusColor = !active
        ? AppTheme.mutedText
        : published && available
            ? AppTheme.success
            : published
                ? AppTheme.info
                : AppTheme.warning;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBadge(statusText, statusColor),
                if (featured) ...[
                  const SizedBox(width: 7),
                  _statusBadge('FEATURED', const Color(0xFF8B5CF6)),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Package actions',
                  onSelected: (action) {
                    if (action == 'edit') _openEditor(item);
                    if (action == 'publish') _changePublication(item, true);
                    if (action == 'unpublish') _changePublication(item, false);
                    if (action == 'archive') _archive(item);
                  },
                  itemBuilder: (_) => [
                    if (active && !published)
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit package')),
                    if (active && !published)
                      const PopupMenuItem(
                          value: 'publish',
                          child: Text('Publish to customers')),
                    if (active && published)
                      const PopupMenuItem(
                          value: 'unpublish', child: Text('Unpublish')),
                    if (active)
                      const PopupMenuItem(
                          value: 'archive', child: Text('Archive')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item['name']?.toString() ?? 'Untitled package',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['description']?.toString() ?? 'No description provided.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.mutedText, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(item['price']),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 9),
                if (_number(item['savingsAmount']) > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Save ${_money(item['savingsAmount'])}',
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(Icons.checkroom_rounded,
                '${packageItems.length} service selections'),
            const SizedBox(height: 7),
            _infoRow(Icons.event_rounded, _validityText(item)),
            const Spacer(),
            if (active && !published)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _changePublication(item, true),
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: const Text('Publish to All Customers'),
                ),
              )
            else if (published)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _changePublication(item, false),
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Unpublish'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
        ),
      ],
    );
  }

  String _validityText(Map<String, dynamic> item) {
    final from = _date(item['validFrom']);
    final until = _date(item['validUntil']);
    if (from == null && until == null) return 'No expiry';
    if (from == null)
      return 'Valid until ${DateFormat('dd MMM yyyy').format(until!)}';
    if (until == null)
      return 'Starts ${DateFormat('dd MMM yyyy').format(from)}';
    return '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM yyyy').format(until)}';
  }

  DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(dynamic value) =>
      '₹${NumberFormat('#,##0.00', 'en_IN').format(_number(value))}';
}

class _PackageEditorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> catalog;
  final Map<String, dynamic>? package;

  const _PackageEditorDialog({required this.catalog, this.package});

  @override
  State<_PackageEditorDialog> createState() => _PackageEditorDialogState();
}

class _PackageEditorDialogState extends State<_PackageEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController imageController;
  late final TextEditingController termsController;
  final TextEditingController searchController = TextEditingController();
  final Map<String, _SelectedService> selected = {};

  bool featured = false;
  bool saving = false;
  DateTime? validFrom;
  DateTime? validUntil;
  String serviceSearch = '';

  bool get editing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final package = widget.package;
    nameController = TextEditingController(text: package?['name']?.toString());
    descriptionController =
        TextEditingController(text: package?['description']?.toString());
    priceController =
        TextEditingController(text: package?['price']?.toString());
    imageController =
        TextEditingController(text: package?['imageUrl']?.toString());
    termsController =
        TextEditingController(text: package?['termsAndConditions']?.toString());
    featured = package?['featured'] == true;
    validFrom = DateTime.tryParse(package?['validFrom']?.toString() ?? '');
    validUntil = DateTime.tryParse(package?['validUntil']?.toString() ?? '');
    _restoreSelections(package?['items']);
  }

  void _restoreSelections(dynamic rawItems) {
    if (rawItems is! List) return;
    for (final raw in rawItems.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final catalogId = item['catalogId']?.toString();
      if (catalogId == null) continue;
      selected[catalogId] = _SelectedService(
        catalogId: catalogId,
        variantId: item['variantId']?.toString(),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageController.dispose();
    termsController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredCatalog {
    final query = serviceSearch.trim().toLowerCase();
    if (query.isEmpty) return widget.catalog;
    return widget.catalog.where((service) {
      return '${service['itemName'] ?? ''} ${service['categoryName'] ?? ''} ${service['subCategoryName'] ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  double get catalogueValue {
    double total = 0;
    for (final selection in selected.values) {
      final service = widget.catalog.firstWhere(
        (item) => item['id']?.toString() == selection.catalogId,
        orElse: () => <String, dynamic>{},
      );
      double price = _number(service['price']);
      final variants = _variants(service);
      if (selection.variantId != null) {
        final variant = variants.cast<Map<String, dynamic>>().firstWhere(
              (item) => item['id']?.toString() == selection.variantId,
              orElse: () => <String, dynamic>{},
            );
        price = _number(variant['price']);
      }
      total += price * selection.quantity;
    }
    return total;
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final current = start ? validFrom : validUntil;
    final firstAllowedDate = DateTime(now.year - 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        validFrom = DateTime(picked.year, picked.month, picked.day);
        if (validUntil != null && !validUntil!.isAfter(validFrom!)) {
          validUntil = null;
        }
      } else {
        validUntil =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (selected.isEmpty) {
      _message('Select at least one catalogue service.');
      return;
    }
    if (validFrom != null &&
        validUntil != null &&
        !validUntil!.isAfter(validFrom!)) {
      _message('Validity end must be after the start date.');
      return;
    }

    setState(() => saving = true);
    final payload = {
      'name': nameController.text.trim(),
      'description': _nullable(descriptionController.text),
      'price': double.parse(priceController.text.trim()),
      'imageUrl': _nullable(imageController.text),
      'featured': featured,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'termsAndConditions': _nullable(termsController.text),
      'items': selected.values
          .map((item) => {
                'catalogId': item.catalogId,
                'variantId': item.variantId,
                'quantity': item.quantity,
              })
          .toList(),
    };

    try {
      if (editing) {
        await ApiClient.dio.put(
          '/api/admin/packages/${widget.package!['id']}',
          data: payload,
        );
      } else {
        await ApiClient.dio.post('/api/admin/packages', data: payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _message(_errorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: (media.width - 48).clamp(320.0, 980.0),
        height: media.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Edit Package' : 'Create Package',
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy),
                        ),
                        const Text(
                          'Select catalogue services and configure the customer offer.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FormHeading('Package details'),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                  labelText: 'Package name *'),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Package name is required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              onChanged: (_) => setState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Offer price *', prefixText: '₹ '),
                              validator: (value) {
                                final amount =
                                    double.tryParse(value?.trim() ?? '');
                                return amount == null || amount <= 0
                                    ? 'Enter a valid price'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Customer-facing description'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                            labelText: 'Package image URL'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _dateField('Valid from', validFrom, true)),
                          const SizedBox(width: 14),
                          Expanded(
                              child:
                                  _dateField('Valid until', validUntil, false)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              title: const Text('Featured',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              subtitle:
                                  const Text('Show before other packages'),
                              value: featured,
                              onChanged: (value) =>
                                  setState(() => featured = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: termsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Terms and conditions'),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                              child: _FormHeading('Included services')),
                          Text(
                            '${selected.length} selected  •  Catalogue value ${_money(catalogueValue)}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setState(() => serviceSearch = value),
                        decoration: const InputDecoration(
                          hintText: 'Search catalogue services...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: filteredCatalog
                              .map((service) => _serviceTile(service))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(
                    'Offer: ${_money(double.tryParse(priceController.text) ?? 0)}',
                    style: const TextStyle(
                        color: AppTheme.navy, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving...' : 'Save Draft'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, bool start) {
    return InkWell(
      onTap: () => _pickDate(start),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: () => setState(() {
                    if (start) {
                      validFrom = null;
                    } else {
                      validUntil = null;
                    }
                  }),
                  icon: const Icon(Icons.close, size: 18),
                ),
        ),
        child: Text(date == null
            ? 'No restriction'
            : DateFormat('dd MMM yyyy').format(date)),
      ),
    );
  }

  Widget _serviceTile(Map<String, dynamic> service) {
    final id = service['id']?.toString() ?? '';
    final selection = selected[id];
    final checked = selection != null;
    final variants = _variants(service);
    final category = service['categoryName']?.toString() ?? '';
    final subCategory = service['subCategoryName']?.toString() ?? '';
    final serviceContext = [
      if (category.isNotEmpty) category,
      if (subCategory.isNotEmpty) subCategory,
      _money(service['price']),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: checked,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  selected[id] = _SelectedService(catalogId: id);
                } else {
                  selected.remove(id);
                }
              });
            },
            title: Text(service['itemName']?.toString() ?? 'Service',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              serviceContext,
            ),
            secondary:
                const Icon(Icons.checkroom_rounded, color: AppTheme.primary),
          ),
          if (checked)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 8, 8),
              child: Row(
                children: [
                  if (variants.isNotEmpty) ...[
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey('$id-${selection.variantId}'),
                        initialValue: selection.variantId,
                        decoration: const InputDecoration(labelText: 'Variant'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child:
                                Text('Standard (${_money(service['price'])})'),
                          ),
                          ...variants.map(
                            (variant) => DropdownMenuItem<String?>(
                              value: variant['id']?.toString(),
                              child: Text(
                                '${variant['variantName']} (${_money(variant['price'])})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selection.variantId = value),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  const Text('Quantity',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: selection.quantity <= 1
                        ? null
                        : () => setState(() => selection.quantity--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text('${selection.quantity}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => selection.quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _variants(Map<String, dynamic> service) {
    final raw = service['variants'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(dynamic value) =>
      '₹${NumberFormat('#,##0.00', 'en_IN').format(_number(value))}';
}

class _SelectedService {
  final String catalogId;
  String? variantId;
  int quantity;

  _SelectedService({
    required this.catalogId,
    this.variantId,
    this.quantity = 1,
  });
}

class _FormHeading extends StatelessWidget {
  final String text;
  const _FormHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.navy));
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback retry;

  const _ErrorPanel({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return error.message ?? 'Unable to contact the server.';
  }
  return error.toString();
}
