import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

final reportsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ApiClient.dio.get('/api/admin-panel/reports');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _GenerateReportDialog(
              onSuccess: () => ref.refresh(reportsProvider),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Custom Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Reports & Analytics',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Generate predefined reports or view past exports.',
                style: TextStyle(color: AppTheme.mutedText)),
            const SizedBox(height: 32),
            const Text('Report Templates',
                style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTemplateCard(
                    'Monthly Financials',
                    'Revenue, Costs, Margins',
                    Icons.account_balance_wallet,
                    Colors.green),
                _buildTemplateCard('Store Performance', 'Order volumes, SLAs',
                    Icons.storefront, Colors.blue),
                _buildTemplateCard('Rider Payouts', 'Trips, Tips, Salaries',
                    Icons.electric_moped, Colors.purple),
                _buildTemplateCard(
                    'Inventory Usage',
                    'Stock consumption, Alerts',
                    Icons.inventory,
                    Colors.orange),
                _buildTemplateCard('Customer Retention',
                    'LTV, Churn, Active Users', Icons.people, Colors.pink),
                _buildTemplateCard(
                    'Tax Report (GST)',
                    'Tax liabilities & filings',
                    Icons.receipt_long,
                    Colors.teal),
              ],
            ),
            const SizedBox(height: 48),
            const Text('Recent Exports',
                style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: reportsAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator())),
                error: (err, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('Error: $err'))),
                data: (data) {
                  if (data.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                            child: Text(
                                'No reports generated yet. Click a template above to generate one.')));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final rep = data[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.picture_as_pdf,
                              color: Colors.redAccent, size: 24),
                        ),
                        title: Text(rep['reportName'] ?? 'Unnamed Report',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Type: ${rep['reportType']} • By: ${rep['generatedBy']}'),
                        trailing: Chip(
                          label: Text(rep['status'] ?? 'GENERATING',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          backgroundColor: rep['status'] == 'COMPLETED'
                              ? Colors.green
                              : (rep['status'] == 'FAILED'
                                  ? Colors.red
                                  : Colors.orange),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          side: BorderSide.none,
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
    );
  }

  Widget _buildTemplateCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedText)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GenerateReportDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _GenerateReportDialog({required this.onSuccess});

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  final _nameCtrl = TextEditingController();
  String _type = 'PDF';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/api/admin-panel/reports', data: {
        'reportName': _nameCtrl.text,
        'reportType': _type,
        'generatedBy': 'Admin',
        'status': 'COMPLETED'
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Report'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Report Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Report Type'),
              items: ['PDF', 'CSV', 'EXCEL']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _type = val!),
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
              : const Text('Generate'),
        ),
      ],
    );
  }
}
