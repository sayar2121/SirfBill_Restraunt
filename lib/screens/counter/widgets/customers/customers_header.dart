import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';
import '../../../../services/export_service.dart';

class CustomersHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onAddCustomer;
  final List<Map<String, dynamic>> filteredCustomers;

  const CustomersHeader({
    super.key,
    required this.onRefresh,
    required this.onAddCustomer,
    required this.filteredCustomers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      spacing: 16,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people,
                  color: Theme.of(context).cardColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your customers, view purchase history and build better relationships',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Export Customers',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      size: 18,
                      color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                const PopupMenuItem(value: 'excel', child: Text('Export as Excel')),
              ],
              onSelected: (val) async {
                final exportData = filteredCustomers.map((c) => {
                  'Customer ID': c['id'],
                  'Name': c['name'],
                  'Phone': c['phone'],
                  'City': c['city'],
                  'Status': c['status'],
                  'Total Purchases': c['totalPurchases'] ?? 0,
                  'Bills Count': c['bills'] ?? 0,
                  'Created At': c['raw_created_at'] ?? '',
                }).toList();

                try {
                  if (val == 'csv') {
                    await ExportService.exportToCSV(exportData, 'customers_export');
                  } else {
                    await ExportService.exportToExcel(exportData, 'customers_export');
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export successful!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAddCustomer,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
