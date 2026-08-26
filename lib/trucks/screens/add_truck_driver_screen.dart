import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class AddTruckDriverScreen extends StatefulWidget {
  const AddTruckDriverScreen({super.key});

  @override
  State<AddTruckDriverScreen> createState() => _AddTruckDriverScreenState();
}

class _AddTruckDriverScreenState extends State<AddTruckDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _truckNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _capacityController = TextEditingController(text: '1000.0');

  bool _isSaving = false;

  Future<void> _saveTruck() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      await ApiClient.dio.post('/api/truck-logistics/trucks', data: {
        'truckNumber': _truckNumberController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'driverPhone': _driverPhoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'capacityKg': double.tryParse(_capacityController.text.trim()) ?? 1000.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Truck & Driver created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add truck: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Truck Driver', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Truck & Driver details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              const SizedBox(height: 24),
              _buildTextField('Truck Number (e.g. DL-14-1234)', _truckNumberController, Icons.local_shipping),
              const SizedBox(height: 16),
              _buildTextField('Driver Name', _driverNameController, Icons.person),
              const SizedBox(height: 16),
              _buildTextField('Driver Phone', _driverPhoneController, Icons.phone, isNumeric: true),
              const SizedBox(height: 16),
              _buildTextField('Driver Email', _emailController, Icons.email),
              const SizedBox(height: 16),
              _buildTextField('Driver Password', _passwordController, Icons.lock),
              const SizedBox(height: 16),
              _buildTextField('Capacity (KG)', _capacityController, Icons.monitor_weight, isNumeric: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTruck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Register Truck', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.mutedText),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
