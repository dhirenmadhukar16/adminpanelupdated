import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AddEditRiderScreen extends StatefulWidget {
  final Map? rider;
  final VoidCallback onSaved;

  const AddEditRiderScreen({super.key, this.rider, required this.onSaved});

  @override
  State<AddEditRiderScreen> createState() => _AddEditRiderScreenState();
}

class _AddEditRiderScreenState extends State<AddEditRiderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _passwordCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.rider;
    _nameCtrl = TextEditingController(text: r?['riderName'] ?? '');
    _phoneCtrl = TextEditingController(text: r?['phone'] ?? '');
    _emailCtrl = TextEditingController(text: r?['email'] ?? '');
    _vehicleCtrl = TextEditingController(text: r?['vehicleNumber'] ?? '');
    _passwordCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _vehicleCtrl.dispose();
    _passwordCtrl.dispose();
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
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'vehicleNumber': _vehicleCtrl.text,
        'password': _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
        'latitude': 0.0,
        'longitude': 0.0,
      };

      if (widget.rider == null) {
        // Create
        final res =
            await ApiClient.dio.post('/api/admin/riders', data: payload);
        final data = res.data;
        if (data != null && data['generatedPassword'] != null) {
          final pw = data['generatedPassword'];
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Rider Credentials Generated',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Rider created successfully! Please copy these credentials for the rider to log in:'),
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
        final id = widget.rider!['id'];
        await ApiClient.dio.put('/api/admin/riders/$id', data: payload);
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
    final isEdit = widget.rider != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Rider' : 'Add Rider',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
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
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _buildField('Rider Name', _nameCtrl, Icons.person),
              const SizedBox(height: 16),
              _buildField('Phone', _phoneCtrl, Icons.phone),
              const SizedBox(height: 16),
              _buildField('Email', _emailCtrl, Icons.email),
              const SizedBox(height: 16),
              _buildField(
                  'Vehicle Number', _vehicleCtrl, Icons.directions_bike),
              const SizedBox(height: 16),
              _buildOptionalField(
                  'Password (Optional)', _passwordCtrl, Icons.lock),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Rider' : 'Create Rider',
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
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

  Widget _buildOptionalField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
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
