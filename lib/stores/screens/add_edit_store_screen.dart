import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddEditStoreScreen extends StatefulWidget {
  final Map? store;
  final VoidCallback onSaved;

  const AddEditStoreScreen({super.key, this.store, required this.onSaved});

  @override
  State<AddEditStoreScreen> createState() => _AddEditStoreScreenState();
}

class _AddEditStoreScreenState extends State<AddEditStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _adminNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  bool _gstEnabled = true;
  bool _saving = false;
  bool _loadingStore = false;
  String? _error;

  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url =
          'https://api.maptiler.com/geocoding/$query.json?key=KzCce63ORKUguuaHmdh1';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _searchResults = data['features'] ?? [];
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _gstEnabled = s?['gstEnabled'] != false;
    _codeCtrl = TextEditingController(text: s?['storeCode'] ?? '');
    _nameCtrl =
        TextEditingController(text: s?['name'] ?? s?['storeName'] ?? '');
    _adminNameCtrl = TextEditingController(text: s?['storeAdminName'] ?? '');
    _phoneCtrl = TextEditingController(text: s?['phone'] ?? '');
    _emailCtrl = TextEditingController(text: s?['email'] ?? '');
    _addressCtrl = TextEditingController(text: s?['address'] ?? '');
    _cityCtrl = TextEditingController(text: s?['city'] ?? '');
    _latCtrl = TextEditingController(text: s?['latitude']?.toString() ?? '');
    _lngCtrl = TextEditingController(text: s?['longitude']?.toString() ?? '');
    if (s != null && s['latitude'] != null && s['longitude'] != null) {
      _selectedLocation = LatLng(s['latitude'], s['longitude']);
    } else {
      _selectedLocation =
          const LatLng(28.19644, 77.40000); // Default placeholder
    }

    if (s != null) {
      _fetchFullStoreDetails();
    }
  }

  Future<void> _fetchFullStoreDetails() async {
    final s = widget.store!;
    final storeId = s['storeId'] ?? s['id'];
    if (storeId == null) return;

    setState(() => _loadingStore = true);
    try {
      final res = await ApiClient.dio.get('/api/admin/stores/$storeId');
      final fullStore = res.data;
      if (mounted) {
        setState(() {
          _gstEnabled = fullStore['gstEnabled'] != false;
          _codeCtrl.text = fullStore['storeCode'] ?? _codeCtrl.text;
          _nameCtrl.text = fullStore['name'] ?? _nameCtrl.text;
          _adminNameCtrl.text =
              fullStore['storeAdminName'] ?? _adminNameCtrl.text;
          _phoneCtrl.text = fullStore['phone'] ?? _phoneCtrl.text;
          _emailCtrl.text = fullStore['email'] ?? _emailCtrl.text;
          _addressCtrl.text = fullStore['address'] ?? _addressCtrl.text;
          _cityCtrl.text = fullStore['city'] ?? _cityCtrl.text;
          _latCtrl.text = fullStore['latitude']?.toString() ?? _latCtrl.text;
          _lngCtrl.text = fullStore['longitude']?.toString() ?? _lngCtrl.text;
          if (fullStore['latitude'] != null && fullStore['longitude'] != null) {
            _selectedLocation =
                LatLng(fullStore['latitude'], fullStore['longitude']);
            _mapController.move(_selectedLocation!, 14);
          }
        });
      }
    } catch (e) {
      print('Error fetching full store details: $e');
    } finally {
      if (mounted) setState(() => _loadingStore = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _adminNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = {
        'gstEnabled': _gstEnabled,
        'storeCode': _codeCtrl.text,
        'name': _nameCtrl.text,
        'storeAdminName': _adminNameCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'address': _addressCtrl.text,
        'city': _cityCtrl.text,
        'latitude': double.tryParse(_latCtrl.text) ?? 0.0,
        'longitude': double.tryParse(_lngCtrl.text) ?? 0.0,
      };

      if (widget.store == null) {
        // Create
        final res =
            await ApiClient.dio.post('/api/admin/stores', data: payload);
        final data = res.data;
        if (data != null && data['generatedPassword'] != null) {
          final pw = data['generatedPassword'];
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Store Credentials Generated',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Store created successfully! Please copy these credentials for the store manager to log in:'),
                    const SizedBox(height: 16),
                    Text('Email: ${_emailCtrl.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Password: $pw',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: 'Email: ${_emailCtrl.text}\nPassword: $pw'));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')));
                    },
                    child: const Text('Copy Credentials'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onSaved();
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
            return;
          }
        }
      } else {
        // Update
        final id = widget.store!['storeId'] ?? widget.store!['id'];
        await ApiClient.dio.put('/api/admin/stores/$id', data: payload);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.store != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Store' : 'Add Store',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loadingStore
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SwitchListTile(
                      title: const Text('GST enabled'),
                      subtitle:
                          const Text('Apply GST to new orders for this store'),
                      value: _gstEnabled,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _gstEnabled = value),
                    ),
                    _buildField('Store Code', _codeCtrl, Icons.code),
                    const SizedBox(height: 16),
                    _buildField('Store Name', _nameCtrl, Icons.storefront),
                    const SizedBox(height: 16),
                    _buildField(
                        'Store Admin Name', _adminNameCtrl, Icons.person),
                    const SizedBox(height: 16),
                    _buildField('Phone', _phoneCtrl, Icons.phone),
                    const SizedBox(height: 16),
                    _buildField('Email', _emailCtrl, Icons.email),
                    const SizedBox(height: 16),
                    _buildField('Address', _addressCtrl, Icons.location_on,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    _buildField('City', _cityCtrl, Icons.location_city),
                    const SizedBox(height: 16),
                    const Text('Store Location (Search & Pick on Map)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.navy)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Location...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _searchLocation(val);
                        });
                      },
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        height: 150,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (ctx, i) {
                            final item = _searchResults[i];
                            return ListTile(
                              title: Text(
                                  item['place_name'] ?? item['text'] ?? ''),
                              onTap: () {
                                final coords = item['center'];
                                if (coords != null && coords.length >= 2) {
                                  final latLng = LatLng(coords[1], coords[0]);
                                  setState(() {
                                    _selectedLocation = latLng;
                                    _latCtrl.text = latLng.latitude.toString();
                                    _lngCtrl.text = latLng.longitude.toString();
                                    _addressCtrl.text = item['place_name'] ??
                                        item['text'] ??
                                        '';
                                    _searchResults.clear();
                                  });
                                  _mapController.move(latLng, 14);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation!,
                            initialZoom: 13,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _selectedLocation = point;
                                _latCtrl.text = point.latitude.toString();
                                _lngCtrl.text = point.longitude.toString();
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KzCce63ORKUguuaHmdh1',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on,
                                      color: Colors.red, size: 40),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child:
                                _buildField('Latitude', _latCtrl, Icons.map)),
                        const SizedBox(width: 16),
                        Expanded(
                            child:
                                _buildField('Longitude', _lngCtrl, Icons.map)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                isEdit ? 'Update Store' : 'Create Store',
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
