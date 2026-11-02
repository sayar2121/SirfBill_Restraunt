import 'package:flutter/material.dart';
import '../../../../services/export_service.dart';
import '../../../../services/shop_service.dart';

/// Top header for Shop Management screen with Export dropdown and action buttons.
class ShopHeader extends StatelessWidget {
  final bool isDark;
  final List<Shop> shops;
  final VoidCallback onRefresh;
  final VoidCallback onAddShop;

  const ShopHeader({
    super.key,
    required this.isDark,
    required this.shops,
    required this.onRefresh,
    required this.onAddShop,
  });

  Future<void> _exportData(BuildContext context, String format) async {
    final exportData = shops
        .map(
          (s) => {
            'Name': s.name,
            'Code': s.code,
            'Address': s.location,
            'City': s.city,
            'Contact': s.contact,
            'Status': s.status,
            'Primary': s.isPrimary ? 'Yes' : 'No',
          },
        )
        .toList();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'shops_$timestamp';

    try {
      if (format == 'pdf') {
        await ExportService.exportToPDF(exportData, filename);
      } else if (format == 'excel') {
        await ExportService.exportToExcel(exportData, filename);
      } else if (format == 'csv') {
        await ExportService.exportToCSV(exportData, filename);
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
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 16,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shops',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Manage your branch shops and their settings',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Export Options',
                onSelected: (fmt) => _exportData(context, fmt),
                offset: const Offset(0, 50),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Export as PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_view, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Export as Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Export as CSV'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                onPressed: onRefresh,
              ),
              if (shops.isEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Shop'),
                  onPressed: onAddShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
