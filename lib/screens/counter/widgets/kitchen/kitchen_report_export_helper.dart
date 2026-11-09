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

class KitchenReportExportHelper {
  static void showExportOptions({
    required BuildContext context,
    required List<KitchenTicket> tickets,
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
                          'Export Kitchen Display Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Filter: $periodLabel (${tickets.length} tickets)',
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
                        subtitle: 'Detailed .xlsx file with tickets, items & prep time',
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _exportToExcel(context, tickets, periodLabel);
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
                        subtitle: 'Print-ready kitchen report with metrics',
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _exportToPdf(context, tickets, periodLabel);
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
    List<KitchenTicket> tickets,
    String periodLabel,
  ) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Kitchen Tickets';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // Title & Period headers
      sheet.appendRow([
        TextCellValue('SirfBill Restaurant - Kitchen Display System Report'),
      ]);
      sheet.appendRow([
        TextCellValue('Period: $periodLabel | Exported on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
      ]);
      sheet.appendRow([
        TextCellValue('Total Tickets: ${tickets.length}'),
      ]);
      sheet.appendRow([TextCellValue('')]); // empty spacer

      // Column Headers
      sheet.appendRow([
        TextCellValue('KOT #'),
        TextCellValue('Order #'),
        TextCellValue('Order Type'),
        TextCellValue('Table / Floor'),
        TextCellValue('Server / Staff'),
        TextCellValue('Status'),
        TextCellValue('Created Time'),
        TextCellValue('Prep Start Time'),
        TextCellValue('Total Items'),
        TextCellValue('Items & Quantities'),
        TextCellValue('Special Instructions'),
      ]);

      for (final t in tickets) {
        final orderTypeLabel = t.orderType == OrderType.dineIn
            ? 'Dine-In'
            : (t.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery');

        final tableFloor = [
          if (t.tableLabel != null && t.tableLabel!.isNotEmpty) t.tableLabel,
          if (t.floor != null && t.floor!.isNotEmpty) t.floor,
        ].join(' - ');

        final statusLabel = t.status == KotStatus.newOrder
            ? 'New Order'
            : (t.status == KotStatus.preparing
                ? 'Preparing'
                : (t.status == KotStatus.ready ? 'Ready' : 'Served'));

        final itemsSummary = t.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
        final totalQty = t.items.fold<int>(0, (sum, i) => sum + i.quantity);

        sheet.appendRow([
          TextCellValue(t.kotNumber),
          TextCellValue(t.orderNumber),
          TextCellValue(orderTypeLabel),
          TextCellValue(tableFloor.isEmpty ? 'N/A' : tableFloor),
          TextCellValue(t.serverName ?? 'Staff'),
          TextCellValue(statusLabel),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt)),
          TextCellValue(t.prepStartedAt != null ? DateFormat('HH:mm').format(t.prepStartedAt!) : '-'),
          IntCellValue(totalQty),
          TextCellValue(itemsSummary),
          TextCellValue(t.specialInstruction ?? '-'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final filename = 'Kitchen_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveAs(
          name: filename,
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kitchen report exported successfully: $filename.xlsx'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting kitchen report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<void> _exportToPdf(
    BuildContext context,
    List<KitchenTicket> tickets,
    String periodLabel,
  ) async {
    try {
      final pdf = pw.Document();
      final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      final newCount = tickets.where((t) => t.status == KotStatus.newOrder).length;
      final prepCount = tickets.where((t) => t.status == KotStatus.preparing).length;
      final readyCount = tickets.where((t) => t.status == KotStatus.ready).length;
      final servedCount = tickets.where((t) => t.status == KotStatus.served).length;

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
                        'SirfBill Restaurant - Kitchen Display System',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Period: $periodLabel  |  Exported: $nowFormatted',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      _buildPdfBadge('Total', tickets.length.toString(), PdfColors.blueGrey800),
                      pw.SizedBox(width: 8),
                      _buildPdfBadge('New', newCount.toString(), PdfColors.red700),
                      pw.SizedBox(width: 8),
                      _buildPdfBadge('In Prep', prepCount.toString(), PdfColors.orange700),
                      pw.SizedBox(width: 8),
                      _buildPdfBadge('Ready', readyCount.toString(), PdfColors.green700),
                      pw.SizedBox(width: 8),
                      _buildPdfBadge('Served', servedCount.toString(), PdfColors.indigo700),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: [
                'KOT #',
                'Order #',
                'Mode',
                'Table',
                'Server',
                'Status',
                'Time',
                'Items Summary',
              ],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              data: tickets.map((t) {
                final orderTypeLabel = t.orderType == OrderType.dineIn
                    ? 'Dine-In'
                    : (t.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery');

                final statusLabel = t.status == KotStatus.newOrder
                    ? 'New'
                    : (t.status == KotStatus.preparing
                        ? 'In Prep'
                        : (t.status == KotStatus.ready ? 'Ready' : 'Served'));

                final itemsSummary = t.items.map((i) => '${i.quantity}x ${i.name}').join(', ');

                return [
                  t.kotNumber,
                  t.orderNumber,
                  orderTypeLabel,
                  t.tableLabel ?? '-',
                  t.serverName ?? 'Staff',
                  statusLabel,
                  DateFormat('dd/MM HH:mm').format(t.createdAt),
                  itemsSummary,
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final filename = 'Kitchen_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF kitchen report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static pw.Widget _buildPdfBadge(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    );
  }
}

