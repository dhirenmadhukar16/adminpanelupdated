import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class AssignRiderDialog extends StatefulWidget {
  final String orderId;

  const AssignRiderDialog({super.key, required this.orderId});

  @override
  State<AssignRiderDialog> createState() => _AssignRiderDialogState();
}

class _AssignRiderDialogState extends State<AssignRiderDialog> {
  bool loading = true;
  String? error;
  List<dynamic> riders = [];
  String? selectedRiderId;

  @override
  void initState() {
    super.initState();
    loadRiders();
  }

  Future<void> loadRiders() async {
    try {
      final response = await ApiClient.dio.get('/api/admin-panel/riders/stats');
      setState(() {
        riders = response.data as List<dynamic>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> assignRider() async {
    if (selectedRiderId == null) return;

    try {
      await ApiClient.dio.patch(
        '/api/admin-panel/orders/${widget.orderId}/assign-rider',
        data: {'riderId': selectedRiderId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider assigned successfully')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Rider'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child:
                        Text(error!, style: const TextStyle(color: Colors.red)))
                : riders.isEmpty
                    ? const Center(child: Text('No riders available'))
                    : ListView.builder(
                        itemCount: riders.length,
                        itemBuilder: (context, index) {
                          final r = riders[index];
                          final id =
                              r['id']?.toString() ?? r['riderId']?.toString();
                          return RadioListTile<String>(
                            title:
                                Text(r['name'] ?? r['riderName'] ?? 'Unknown'),
                            subtitle: Text('Status: ${r['status'] ?? 'N/A'}'),
                            value: id ?? '',
                            groupValue: selectedRiderId,
                            onChanged: (value) {
                              setState(() {
                                selectedRiderId = value;
                              });
                            },
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedRiderId == null ? null : assignRider,
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
