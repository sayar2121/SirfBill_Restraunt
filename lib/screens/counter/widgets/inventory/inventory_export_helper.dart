import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/rack_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/export_service.dart';

class InventoryExportHelper {
  static List<InventoryItem> sortItems(
    List<InventoryItem> items,
    String sortColumn,
    bool sortAscending,
  ) {
    final sortedItems = List<InventoryItem>.from(items);
    sortedItems.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'Item Name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'Added/Updated':
          final aDate = a.createdAt ?? '';
          final bDate = b.createdAt ?? '';
          cmp = aDate.compareTo(bDate);
          break;
        case 'Stock':
          cmp = a.stockQuantity.compareTo(b.stockQuantity);
          break;
        case 'Price (₹)':
          cmp = a.unitPrice.compareTo(b.unitPrice);
          break;
        case 'GST (%)':
          cmp = (a.gst ?? 0).compareTo(b.gst ?? 0);
          break;
        case 'Expiry Date':
          cmp = a.expiryDate.compareTo(b.expiryDate);
          break;
        case 'Status':
          final aLow = a.lowStockThreshold ?? 10;
          final bLow = b.lowStockThreshold ?? 10;
          final aStatus = a.stockQuantity == 0 ? 0 : (a.stockQuantity <= aLow ? 1 : 2);
          final bStatus = b.stockQuantity == 0 ? 0 : (b.stockQuantity <= bLow ? 1 : 2);
          cmp = aStatus.compareTo(bStatus);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });
    return sortedItems;
  }

  static Future<void> exportData({
    required BuildContext context,
    required String format,
    required List<InventoryItem> items,
    required List<Rack> racks,
    required List<Category> categories,
    List<dynamic> distributors = const [],
    required Map<String, dynamic> settings,
  }) async {
    final data = items.map((m) {
      final rackName = racks
          .firstWhere(
            (r) => r.id == m.rackId,
            orElse: () => Rack(id: '', rackNumber: 'N/A'),
          )
          .rackNumber;
      final categoryName = categories
          .firstWhere(
            (c) => c.id == m.categoryId,
            orElse: () => Category(id: '', name: 'N/A'),
          )
          .name;
      final distMatch = distributors.firstWhere(
        (d) => d['id']?.toString() == m.distributorId?.toString(),
        orElse: () => null,
      );
      final distName = (m.distributor != null && m.distributor!.isNotEmpty)
          ? m.distributor!
          : (distMatch?['name']?.toString() ?? 'N/A');

      return {
        'Name': m.name,
        'SKU': m.sku,
        'Batch': m.batchNumber,
        'Stock': m.stockQuantity,
        'Loose Stock': m.looseStock,
        'Pack Size': m.packSize ?? 'N/A',
        'Buying Price (₹)': m.buyingPrice,
        'Unit Price (₹)': m.unitPrice,
        'GST (%)': m.gst ?? 0,
        'Discount (%)': m.discount ?? 0,
        'Manufacturer': m.manufacturer,
        'Expiry': m.expiryDate,
        'Rack': rackName,
        'Category': categoryName,
        'Distributor': distName,
        'HSN Code': m.hsnCode ?? 'N/A',
      };
    }).toList();

    final shopDetails = {
      'name': settings['shop_name'] ?? 'MANJU MEDICAL STORES',
      'location': settings['address'],
      'contact': settings['phone'],
      'email': settings['email'],
      'gstin': settings['gst_number'],
      'logo_url': settings['logo_url'],
    };

    final filename =
        'inventory_export_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    try {
      if (format == 'CSV') {
        await ExportService.exportToCSV(data, filename);
      } else if (format == 'Excel') {
        await ExportService.exportToExcel(data, filename);
      } else if (format == 'PDF') {
        await ExportService.exportToPDF(data, filename, shopDetails);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported as $format successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
