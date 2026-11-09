import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

class OrderReportExportHelper {
  static void showExportOptions({
    required BuildContext context,
    required List<RestaurantOrder> orders,
    required DateRangePreset datePreset,
    DateTimeRange? customRange,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periodLabel = _formatPeriod(datePreset, customRange);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Orders Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Period: $periodLabel (${orders.length} orders)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildExportCard(
                        context: context,
                        icon: Icons.table_chart_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Excel Spreadsheet',
                        subtitle: 'Detailed .xlsx with orders, items, taxes & payment',
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _exportToExcel(context, orders, periodLabel);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildExportCard(
                        context: context,
                        icon: Icons.picture_as_pdf_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'PDF Document',
                        subtitle: 'Print-ready orders register with totals',
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _exportToPdf(context, orders, periodLabel);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatPeriod(DateRangePreset preset, DateTimeRange? customRange) {
    final now = DateTime.now();
    switch (preset) {
      case DateRangePreset.all:
        return 'All Time';
      case DateRangePreset.today:
        return 'Today (${DateFormat('dd MMM yyyy').format(now)})';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case DateRangePreset.thisYear:
        return 'Year ${now.year}';
      case DateRangePreset.custom:
        if (customRange != null) {
          final df = DateFormat('dd MMM yyyy');
          return '${df.format(customRange.start)} - ${df.format(customRange.end)}';
        }
        return 'Custom Range';
    }
  }

  static Widget _buildExportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _exportToExcel(
    BuildContext context,
    List<RestaurantOrder> orders,
    String periodLabel,
  ) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Orders Register';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // Header summary
      sheet.appendRow([
        TextCellValue('SirfBill Restaurant - Orders Register'),
      ]);
      sheet.appendRow([
        TextCellValue('Period: $periodLabel | Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
      ]);
      final totalRevenue = orders.fold<double>(0.0, (sum, o) => sum + o.grandTotal);
      sheet.appendRow([
        TextCellValue('Total Orders: ${orders.length} | Total Value: ₹${totalRevenue.toStringAsFixed(2)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);

      // Table columns
      sheet.appendRow([
        TextCellValue('Order #'),
        TextCellValue('Date & Time'),
        TextCellValue('Order Type'),
        TextCellValue('Table / Floor'),
        TextCellValue('Customer'),
        TextCellValue('Phone'),
        TextCellValue('Order Status'),
        TextCellValue('Payment Status'),
        TextCellValue('Payment Mode'),
        TextCellValue('Subtotal (₹)'),
        TextCellValue('Discount (₹)'),
        TextCellValue('GST (₹)'),
        TextCellValue('Grand Total (₹)'),
        TextCellValue('Items Summary'),
        TextCellValue('Order Notes'),
      ]);

      for (final o in orders) {
        final orderTypeLabel = o.orderType == OrderType.dineIn
            ? 'Dine-In'
            : (o.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery');

        final tableFloor = [
          if (o.tableLabel != null && o.tableLabel!.isNotEmpty) o.tableLabel,
          if (o.floor != null && o.floor!.isNotEmpty) o.floor,
        ].join(' - ');

        final statusLabel = o.status == OrderStatus.active
            ? 'Active / In Prep'
            : (o.status == OrderStatus.hold
                ? 'Held'
                : (o.status == OrderStatus.completed ? 'Completed' : 'Cancelled'));

        final payStatusLabel = o.paymentStatus == PaymentStatus.paid
            ? 'PAID'
            : (o.paymentStatus == PaymentStatus.refunded ? 'REFUNDED' : 'PENDING');

        final itemsSummary = o.items.map((i) => '${i.quantity}x ${i.item.name}').join(', ');

        sheet.appendRow([
          TextCellValue(o.orderNumber),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(o.createdAt)),
          TextCellValue(orderTypeLabel),
          TextCellValue(tableFloor.isEmpty ? 'N/A' : tableFloor),
          TextCellValue(o.customerName.isEmpty ? 'Walk-in Guest' : o.customerName),
          TextCellValue(o.customerPhone),
          TextCellValue(statusLabel),
          TextCellValue(payStatusLabel),
          TextCellValue(o.paymentMethod.isEmpty ? '-' : o.paymentMethod),
          DoubleCellValue(o.subtotal),
          DoubleCellValue(o.discount),
          DoubleCellValue(o.gstAmount),
          DoubleCellValue(o.grandTotal),
          TextCellValue(itemsSummary),
          TextCellValue(o.notes ?? '-'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final filename = 'Orders_Register_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveAs(
          name: filename,
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orders report exported successfully: $filename.xlsx'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting orders: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<void> _exportToPdf(
    BuildContext context,
    List<RestaurantOrder> orders,
    String periodLabel,
  ) async {
    try {
      final pdf = pw.Document();
      final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final totalAmount = orders.fold<double>(0.0, (sum, o) => sum + o.grandTotal);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SirfBill Restaurant - Orders Register',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Period: $periodLabel  |  Exported: $nowFormatted',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green800,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'Orders: ${orders.length} | Revenue: ₹${totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: [
                'Order #',
                'Date & Time',
                'Type',
                'Table',
                'Customer',
                'Items',
                'Payment',
                'Status',
                'Total (₹)',
              ],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              data: orders.map((o) {
                final orderTypeLabel = o.orderType == OrderType.dineIn
                    ? 'Dine-In'
                    : (o.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery');

                final itemsSummary = o.items.map((i) => '${i.quantity}x ${i.item.name}').join(', ');
                final payStatus = o.paymentStatus == PaymentStatus.paid ? 'PAID' : 'PENDING';

                return [
                  o.orderNumber,
                  DateFormat('dd/MM HH:mm').format(o.createdAt),
                  orderTypeLabel,
                  o.tableLabel ?? '-',
                  o.customerName.isEmpty ? 'Walk-in' : o.customerName,
                  itemsSummary,
                  '$payStatus (${o.paymentMethod.isEmpty ? '-' : o.paymentMethod})',
                  o.status.name.toUpperCase(),
                  '₹${o.grandTotal.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final filename = 'Orders_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF orders report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
