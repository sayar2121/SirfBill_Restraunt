import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/shop_settings_service.dart';

class RestaurantReportExportHelper {
  /// Robust local file saver:
  /// - On macOS/Windows/Linux: Writes directly to local ~/Downloads folder
  /// - On Web: Triggers browser download directly into ~/Downloads
  /// - On Mobile: Saves to Downloads directory
  static Future<String> _saveFileLocally({
    required String filename,
    required Uint8List bytes,
    required String ext,
    required MimeType mimeType,
  }) async {
    String savedLocation = '$filename.$ext';

    // 1. Desktop direct filesystem write to Downloads folder
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final filePath = '${downloadsDir.path}${Platform.pathSeparator}$filename.$ext';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint('[Export] Saved directly to local filesystem: $filePath');
        return filePath;
      } catch (e) {
        debugPrint('Direct desktop save failed: $e, falling back to FileSaver');
      }
    }

    // 2. Browser native download (Web) or Mobile Downloads directory
    try {
      final res = await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mimeType,
      );
      if (res.isNotEmpty) savedLocation = res;
    } catch (e) {
      debugPrint('FileSaver.saveFile failed: $e, trying saveAs fallback');
      try {
        final res = await FileSaver.instance.saveAs(
          name: filename,
          bytes: bytes,
          fileExtension: ext,
          mimeType: mimeType,
        );
        if (res != null && res.isNotEmpty) savedLocation = res;
      } catch (err) {
        debugPrint('FileSaver.saveAs failed: $err');
      }
    }

    return savedLocation;
  }

  /// Resolve dynamic restaurant name, address and GSTIN
  static Future<Map<String, String>> _resolveRestaurantInfo() async {
    try {
      final settings = await ShopSettingsService.getSettings();
      final name = (settings['shop_name'] ?? 'SirfBill Restaurant').toString().toUpperCase();
      final address = (settings['address'] ?? '').toString();
      final gstin = (settings['gst_number'] ?? settings['gstin'] ?? '').toString();
      return {'name': name, 'address': address, 'gstin': gstin};
    } catch (_) {
      return {'name': 'SIRFBILL RESTAURANT', 'address': '', 'gstin': ''};
    }
  }

  /// Opens an intuitive export sheet tailored to the currently active tab & date filter
  static void showExportOptions({
    required BuildContext context,
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
    int activeTab = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String sheetTitle = 'Export Analytics Report';
        String sheetSubtitle = 'Period: $periodLabel (${orders.length} orders analyzed)';

        if (activeTab == 1) {
          sheetTitle = 'Export Item-wise Sales Report';
          sheetSubtitle = 'Period: $periodLabel (${topDishes.length} menu items sold)';
        } else if (activeTab == 2) {
          sheetTitle = 'Export Audit Trail Activity';
          sheetSubtitle = 'Period: $periodLabel (${auditLogs.length} audit records)';
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sheetTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sheetSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // TAB-SPECIFIC EXPORT: Item-wise Sales
                  if (activeTab == 1) ...[
                    _buildOptionTile(
                      color: const Color(0xFF10B981),
                      icon: Icons.table_chart_rounded,
                      title: 'Download Item-wise Sales (.xlsx)',
                      subtitle: 'Complete Excel sheet with ${topDishes.length} dishes, sales volume, category mix & revenue',
                      onTap: () {
                        Navigator.pop(ctx);
                        exportItemWiseSalesExcel(
                          context: context,
                          periodLabel: periodLabel,
                          topDishes: topDishes,
                          summary: summary,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      color: const Color(0xFF6366F1),
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Download Item-wise Sales Report (.pdf)',
                      subtitle: 'Printable executive PDF leaderboard and category sales breakdown',
                      onTap: () {
                        Navigator.pop(ctx);
                        exportItemWiseSalesPdf(
                          context: context,
                          periodLabel: periodLabel,
                          topDishes: topDishes,
                          summary: summary,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Or Export Complete Executive Package:'),
                    const SizedBox(height: 10),
                  ],

                  // TAB-SPECIFIC EXPORT: Audit Trail
                  if (activeTab == 2) ...[
                    _buildOptionTile(
                      color: const Color(0xFF10B981),
                      icon: Icons.table_chart_rounded,
                      title: 'Download Audit Trail Log (.xlsx)',
                      subtitle: 'Excel spreadsheet of ${auditLogs.length} events with cashier, action, and timestamps',
                      onTap: () {
                        Navigator.pop(ctx);
                        exportAuditTrailExcel(
                          context: context,
                          periodLabel: periodLabel,
                          auditLogs: auditLogs,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      color: const Color(0xFF6366F1),
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Download Audit Trail Report (.pdf)',
                      subtitle: 'Official compliance and operational audit log report',
                      onTap: () {
                        Navigator.pop(ctx);
                        exportAuditTrailPdf(
                          context: context,
                          periodLabel: periodLabel,
                          auditLogs: auditLogs,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Or Export Complete Executive Package:'),
                    const SizedBox(height: 10),
                  ],

                  // FULL EXECUTIVE PACKAGE: Excel Workbook
                  _buildOptionTile(
                    color: const Color(0xFF10B981),
                    icon: Icons.description_rounded,
                    title: 'Export Full Executive Workbook (.xlsx)',
                    subtitle: 'Multi-sheet workbook: Financials, Orders Register, Item-wise Sales & Audit Trail',
                    onTap: () {
                      Navigator.pop(ctx);
                      exportToExcel(
                        context: context,
                        periodLabel: periodLabel,
                        summary: summary,
                        topDishes: topDishes,
                        orders: orders,
                        auditLogs: auditLogs,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // FULL EXECUTIVE PACKAGE: PDF Report
                  _buildOptionTile(
                    color: const Color(0xFF6366F1),
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Export Executive PDF Report (.pdf)',
                    subtitle: 'Full visual report with KPI dashboard, payment mix, menu sales & recent events',
                    onTap: () {
                      Navigator.pop(ctx);
                      exportToPdf(
                        context: context,
                        periodLabel: periodLabel,
                        summary: summary,
                        topDishes: topDishes,
                        orders: orders,
                        auditLogs: auditLogs,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOptionTile({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      tileColor: color.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  static Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.2,
      ),
    );
  }

  // =========================================================================
  // 1. ITEM-WISE SALES EXPORTS (Excel & PDF)
  // =========================================================================

  /// Dedicated Item-wise Sales Excel Spreadsheet
  static Future<void> exportItemWiseSalesExcel({
    required BuildContext context,
    required String periodLabel,
    required List<TopSellingDish> topDishes,
    required SalesReportSummary summary,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Item-wise Sales Excel sheet...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final excel = Excel.createExcel();
      const sheetName = 'Item-wise Sales';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      sheet.appendRow([TextCellValue('ITEM-WISE SALES & MENU LEADERBOARD')]);
      sheet.appendRow([TextCellValue('Period:'), TextCellValue(periodLabel)]);
      sheet.appendRow([TextCellValue('Exported At:'), TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()))]);
      sheet.appendRow([TextCellValue('Total Culinary Revenue:'), DoubleCellValue(summary.grossSales)]);
      sheet.appendRow([TextCellValue('Total Portions Sold:'), IntCellValue(summary.totalItemsSold)]);
      sheet.appendRow([TextCellValue('Total Menu Items:'), IntCellValue(topDishes.length)]);
      sheet.appendRow([TextCellValue(''), TextCellValue('')]);

      sheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Item / Dish Name'),
        TextCellValue('Category'),
        TextCellValue('Quantity Sold (Plates)'),
        TextCellValue('Gross Sales (INR)'),
        TextCellValue('Share of Revenue (%)'),
      ]);

      for (int i = 0; i < topDishes.length; i++) {
        final d = topDishes[i];
        final share = summary.grossSales > 0 ? (d.revenue / summary.grossSales * 100) : 0.0;
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(d.name),
          TextCellValue(d.category),
          IntCellValue(d.quantitySold),
          DoubleCellValue(d.revenue),
          TextCellValue('${share.toStringAsFixed(1)}%'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
        final filename = 'Item_Sales_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

        final savedPath = await _saveFileLocally(
          filename: filename,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item-wise Sales Excel saved to local storage: $savedPath'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Item-wise Sales: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Dedicated Item-wise Sales PDF Report
  static Future<void> exportItemWiseSalesPdf({
    required BuildContext context,
    required String periodLabel,
    required List<TopSellingDish> topDishes,
    required SalesReportSummary summary,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Item-wise Sales PDF Report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final info = await _resolveRestaurantInfo();
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          info['name']!,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                        ),
                        if (info['address']!.isNotEmpty)
                          pw.Text(info['address']!, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        if (info['gstin']!.isNotEmpty)
                          pw.Text('GSTIN: ${info['gstin']}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ITEM-WISE SALES & MENU REPORT',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                        ),
                        pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(
                          'Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.5, color: PdfColors.teal700),
                pw.SizedBox(height: 10),
              ],
            );
          },
          build: (pw.Context context) {
            final starDish = topDishes.isNotEmpty ? topDishes.first.name : 'N/A';
            final avgPrice = summary.totalItemsSold > 0 ? (summary.grossSales / summary.totalItemsSold) : 0.0;

            return [
              // Summary KPI blocks
              pw.Row(
                children: [
                  _buildPdfStatBox('Total Menu Revenue', 'Rs. ${summary.grossSales.toStringAsFixed(0)}', PdfColors.teal700),
                  pw.SizedBox(width: 8),
                  _buildPdfStatBox('Portions Sold', '${summary.totalItemsSold} plates', PdfColors.indigo700),
                  pw.SizedBox(width: 8),
                  _buildPdfStatBox('Top Star Item', starDish, PdfColors.amber800),
                  pw.SizedBox(width: 8),
                  _buildPdfStatBox('Avg Realization', 'Rs. ${avgPrice.toStringAsFixed(1)}', PdfColors.blue700),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text('Full Menu Performance Table (${topDishes.length} Items Listed)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildPdfHeaderCell('Rank'),
                      _buildPdfHeaderCell('Item Name'),
                      _buildPdfHeaderCell('Category'),
                      _buildPdfHeaderCell('Qty Sold'),
                      _buildPdfHeaderCell('Gross Revenue'),
                      _buildPdfHeaderCell('Share'),
                    ],
                  ),
                  ...topDishes.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final dish = entry.value;
                    final share = summary.grossSales > 0 ? (dish.revenue / summary.grossSales * 100) : 0.0;

                    return pw.TableRow(
                      children: [
                        _buildPdfDataCell('#$rank', alignCenter: true),
                        _buildPdfDataCell(dish.name, isBold: true),
                        _buildPdfDataCell(dish.category),
                        _buildPdfDataCell('${dish.quantitySold}', alignCenter: true),
                        _buildPdfDataCell('Rs. ${dish.revenue.toStringAsFixed(2)}'),
                        _buildPdfDataCell('${share.toStringAsFixed(1)}%', alignCenter: true),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
      final filename = 'Item_Sales_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      final savedPath = await _saveFileLocally(
        filename: filename,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$filename.pdf');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item-wise Sales PDF downloaded successfully: $savedPath'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Item-wise Sales PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================================
  // 2. AUDIT TRAIL EXPORTS (Excel & PDF)
  // =========================================================================

  /// Dedicated Audit Trail Excel
  static Future<void> exportAuditTrailExcel({
    required BuildContext context,
    required String periodLabel,
    required List<AuditLogEntry> auditLogs,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Audit Trail Excel sheet...'), duration: Duration(seconds: 2)),
    );

    try {
      final excel = Excel.createExcel();
      const sheetName = 'Audit Trail';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      sheet.appendRow([TextCellValue('AUDIT TRAIL & SYSTEM LOG REPORT')]);
      sheet.appendRow([TextCellValue('Period:'), TextCellValue(periodLabel)]);
      sheet.appendRow([TextCellValue('Total Records:'), IntCellValue(auditLogs.length)]);
      sheet.appendRow([TextCellValue('Exported At:'), TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()))]);
      sheet.appendRow([TextCellValue(''), TextCellValue('')]);

      sheet.appendRow([
        TextCellValue('Timestamp'),
        TextCellValue('Action / Event'),
        TextCellValue('Actor / Staff'),
        TextCellValue('Details'),
        TextCellValue('Severity'),
      ]);

      for (final log in auditLogs) {
        sheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy HH:mm:ss').format(log.timestamp.toLocal())),
          TextCellValue(log.action),
          TextCellValue(log.actorName),
          TextCellValue(log.details),
          TextCellValue(log.severity.toUpperCase()),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
        final filename = 'Audit_Trail_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

        final savedPath = await _saveFileLocally(
          filename: filename,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audit Trail Excel saved to local storage: $savedPath'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Audit Trail: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Dedicated Audit Trail PDF
  static Future<void> exportAuditTrailPdf({
    required BuildContext context,
    required String periodLabel,
    required List<AuditLogEntry> auditLogs,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Audit Trail PDF Report...'), duration: Duration(seconds: 2)),
    );

    try {
      final info = await _resolveRestaurantInfo();
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          info['name']!,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                        ),
                        if (info['address']!.isNotEmpty)
                          pw.Text(info['address']!, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'AUDIT TRAIL & SYSTEM ACTIVITY REPORT',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                        ),
                        pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(
                          'Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.5, color: PdfColors.teal700),
                pw.SizedBox(height: 10),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Text('System Audit Activity Log (${auditLogs.length} Events Recorded)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              if (auditLogs.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  color: PdfColors.grey50,
                  child: pw.Center(child: pw.Text('No audit events found for $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildPdfHeaderCell('Timestamp'),
                        _buildPdfHeaderCell('Action'),
                        _buildPdfHeaderCell('Staff / Actor'),
                        _buildPdfHeaderCell('Details'),
                        _buildPdfHeaderCell('Severity'),
                      ],
                    ),
                    ...auditLogs.map((log) {
                      return pw.TableRow(
                        children: [
                          _buildPdfDataCell(DateFormat('dd-MM-yy HH:mm:ss').format(log.timestamp.toLocal())),
                          _buildPdfDataCell(log.action, isBold: true),
                          _buildPdfDataCell(log.actorName),
                          _buildPdfDataCell(log.details),
                          _buildPdfDataCell(log.severity.toUpperCase(), alignCenter: true),
                        ],
                      );
                    }),
                  ],
                ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
      final filename = 'Audit_Trail_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      final savedPath = await _saveFileLocally(
        filename: filename,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$filename.pdf');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audit Trail PDF downloaded successfully: $savedPath'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Audit Trail PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================================
  // 3. COMPLETE EXECUTIVE WORKBOOK (.xlsx) & EXECUTIVE PDF (.pdf)
  // =========================================================================

  /// Exports a rich multi-sheet Excel workbook containing all restaurant performance data
  static Future<void> exportToExcel({
    required BuildContext context,
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating comprehensive Excel report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final excel = Excel.createExcel();

      // SHEET 1: Financial & Channel Summary
      const summarySheetName = 'Financial Overview';
      final summarySheet = excel[summarySheetName];
      excel.setDefaultSheet(summarySheetName);

      summarySheet.appendRow([TextCellValue('RESTAURANT EXECUTIVE REPORT'), TextCellValue('')]);
      summarySheet.appendRow([TextCellValue('Reporting Period:'), TextCellValue(periodLabel)]);
      summarySheet.appendRow([TextCellValue('Generated At:'), TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()))]);
      summarySheet.appendRow([TextCellValue(''), TextCellValue('')]);

      summarySheet.appendRow([TextCellValue('METRIC'), TextCellValue('VALUE (INR)')]);
      summarySheet.appendRow([TextCellValue('Gross Revenue (Total Realized)'), DoubleCellValue(summary.grossSales)]);
      summarySheet.appendRow([TextCellValue('Net Revenue (Base Sales)'), DoubleCellValue(summary.netSales)]);
      summarySheet.appendRow([TextCellValue('GST Collected'), DoubleCellValue(summary.totalGst)]);
      summarySheet.appendRow([TextCellValue('Discounts Given'), DoubleCellValue(summary.totalDiscount)]);
      summarySheet.appendRow([TextCellValue('Total Orders Completed'), IntCellValue(summary.totalOrders)]);
      summarySheet.appendRow([TextCellValue('Average Order Value (AOV)'), DoubleCellValue(summary.averageOrderValue)]);
      summarySheet.appendRow([TextCellValue('Unique Guests Served'), IntCellValue(summary.uniqueCustomers)]);
      summarySheet.appendRow([TextCellValue('Total Dishes Cooked'), IntCellValue(summary.totalItemsSold)]);
      summarySheet.appendRow([TextCellValue(''), TextCellValue('')]);

      summarySheet.appendRow([TextCellValue('PAYMENT TENDER MIX'), TextCellValue('AMOUNT (INR)')]);
      summarySheet.appendRow([TextCellValue('Cash Tendered'), DoubleCellValue(summary.cashSales)]);
      summarySheet.appendRow([TextCellValue('UPI / Dynamic QR'), DoubleCellValue(summary.upiSales)]);
      summarySheet.appendRow([TextCellValue('Card / POS Terminal'), DoubleCellValue(summary.cardSales)]);
      summarySheet.appendRow([TextCellValue(''), TextCellValue('')]);

      summarySheet.appendRow([TextCellValue('ORDER CHANNELS MIX'), TextCellValue('AMOUNT (INR)')]);
      summarySheet.appendRow([TextCellValue('Dine-In Tables'), DoubleCellValue(summary.dineInSales)]);
      summarySheet.appendRow([TextCellValue('Takeaway Counter'), DoubleCellValue(summary.takeawaySales)]);
      summarySheet.appendRow([TextCellValue('Delivery Orders'), DoubleCellValue(summary.deliverySales)]);

      // SHEET 2: Orders Register
      final ordersSheet = excel['Orders Register'];
      ordersSheet.appendRow([
        TextCellValue('Order #'),
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Order Type'),
        TextCellValue('Customer Name'),
        TextCellValue('Customer Phone'),
        TextCellValue('Subtotal'),
        TextCellValue('Discount'),
        TextCellValue('GST Amount'),
        TextCellValue('Grand Total'),
        TextCellValue('Payment Mode'),
        TextCellValue('Status'),
      ]);

      for (final o in orders) {
        ordersSheet.appendRow([
          TextCellValue(o.orderNumber),
          TextCellValue(DateFormat('dd-MM-yyyy').format(o.createdAt.toLocal())),
          TextCellValue(DateFormat('hh:mm a').format(o.createdAt.toLocal())),
          TextCellValue(o.orderType.name.toUpperCase()),
          TextCellValue(o.customerName),
          TextCellValue(o.customerPhone),
          DoubleCellValue(o.subtotal),
          DoubleCellValue(o.discount),
          DoubleCellValue(o.gstAmount),
          DoubleCellValue(o.grandTotal),
          TextCellValue(o.paymentMethod.isNotEmpty ? o.paymentMethod : 'Cash'),
          TextCellValue(o.status.name.toUpperCase()),
        ]);
      }

      // SHEET 3: Item-wise Sales
      final dishesSheet = excel['Item-wise Sales'];
      dishesSheet.appendRow([
        TextCellValue('Dish / Item Name'),
        TextCellValue('Category'),
        TextCellValue('Quantity Sold'),
        TextCellValue('Total Revenue (INR)'),
      ]);

      if (topDishes.isEmpty) {
        dishesSheet.appendRow([
          TextCellValue('No menu items sold in this period'),
          TextCellValue('-'),
          const IntCellValue(0),
          const DoubleCellValue(0.0),
        ]);
      } else {
        for (final dish in topDishes) {
          dishesSheet.appendRow([
            TextCellValue(dish.name),
            TextCellValue(dish.category),
            IntCellValue(dish.quantitySold),
            DoubleCellValue(dish.revenue),
          ]);
        }
      }

      // SHEET 4: Audit Trail
      final auditSheet = excel['Audit Trail'];
      auditSheet.appendRow([
        TextCellValue('Timestamp'),
        TextCellValue('Action'),
        TextCellValue('Actor / Staff'),
        TextCellValue('Details'),
        TextCellValue('Severity'),
      ]);

      for (final log in auditLogs) {
        auditSheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy HH:mm:ss').format(log.timestamp.toLocal())),
          TextCellValue(log.action),
          TextCellValue(log.actorName),
          TextCellValue(log.details),
          TextCellValue(log.severity.toUpperCase()),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
        final filename = 'Restaurant_Report_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

        final savedPath = await _saveFileLocally(
          filename: filename,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel Report saved to local storage: $savedPath'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Exports an executive PDF summary report with charts, metrics & channel breakdown
  static Future<void> exportToPdf({
    required BuildContext context,
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Executive PDF Report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final info = await _resolveRestaurantInfo();
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          info['name']!,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                        ),
                        if (info['address']!.isNotEmpty)
                          pw.Text(info['address']!, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        if (info['gstin']!.isNotEmpty)
                          pw.Text('GSTIN: ${info['gstin']}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'EXECUTIVE ANALYTICS REPORT',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                        ),
                        pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(
                          'Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.5, color: PdfColors.teal700),
                pw.SizedBox(height: 10),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // 1. High-level financial KPIs
              pw.Text('Key Performance Indicators', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildPdfHeaderCell('Metric'),
                      _buildPdfHeaderCell('Amount / Value'),
                      _buildPdfHeaderCell('Metric'),
                      _buildPdfHeaderCell('Amount / Value'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfDataCell('Gross Realized Revenue'),
                      _buildPdfDataCell('Rs. ${summary.grossSales.toStringAsFixed(2)}', isBold: true),
                      _buildPdfDataCell('Net Base Revenue'),
                      _buildPdfDataCell('Rs. ${summary.netSales.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfDataCell('Total Orders Completed'),
                      _buildPdfDataCell('${summary.totalOrders}', isBold: true),
                      _buildPdfDataCell('Average Order Value (AOV)'),
                      _buildPdfDataCell('Rs. ${summary.averageOrderValue.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfDataCell('GST Collected'),
                      _buildPdfDataCell('Rs. ${summary.totalGst.toStringAsFixed(2)}'),
                      _buildPdfDataCell('Discounts Given'),
                      _buildPdfDataCell('Rs. ${summary.totalDiscount.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfDataCell('Total Food Items Sold'),
                      _buildPdfDataCell('${summary.totalItemsSold} portions', isBold: true),
                      _buildPdfDataCell('Unique Guests Served'),
                      _buildPdfDataCell('${summary.uniqueCustomers} patrons'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 2. Breakdown Tables (Payment Tender Mix & Order Channels)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Payment Tender Mix
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Tender Mix', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                              children: [
                                _buildPdfHeaderCell('Tender Mode'),
                                _buildPdfHeaderCell('Amount (INR)'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('UPI / Dynamic QR'),
                                _buildPdfDataCell('Rs. ${summary.upiSales.toStringAsFixed(2)}'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('Cash Tendered'),
                                _buildPdfDataCell('Rs. ${summary.cashSales.toStringAsFixed(2)}'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('Card / POS Terminal'),
                                _buildPdfDataCell('Rs. ${summary.cardSales.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),

                  // Order Channels Mix
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Fulfillment Channels Mix', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                              children: [
                                _buildPdfHeaderCell('Order Channel'),
                                _buildPdfHeaderCell('Amount (INR)'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('Dine-In Tables'),
                                _buildPdfDataCell('Rs. ${summary.dineInSales.toStringAsFixed(2)}'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('Takeaway Counter'),
                                _buildPdfDataCell('Rs. ${summary.takeawaySales.toStringAsFixed(2)}'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfDataCell('Delivery Orders'),
                                _buildPdfDataCell('Rs. ${summary.deliverySales.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 3. Top Selling Dishes table (ALL dishes)
              pw.Text('Menu Items & Dish Sales Performance (${topDishes.length} Items)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (topDishes.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: PdfColors.grey50,
                  child: pw.Center(
                    child: pw.Text('No menu items sold in this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildPdfHeaderCell('Rank'),
                        _buildPdfHeaderCell('Item Name'),
                        _buildPdfHeaderCell('Category'),
                        _buildPdfHeaderCell('Quantity Sold'),
                        _buildPdfHeaderCell('Revenue Generated'),
                      ],
                    ),
                    ...topDishes.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final dish = entry.value;
                      return pw.TableRow(
                        children: [
                          _buildPdfDataCell('#$rank', alignCenter: true),
                          _buildPdfDataCell(dish.name, isBold: true),
                          _buildPdfDataCell(dish.category),
                          _buildPdfDataCell('${dish.quantitySold}', alignCenter: true),
                          _buildPdfDataCell('Rs. ${dish.revenue.toStringAsFixed(2)}'),
                        ],
                      );
                    }),
                  ],
                ),
              pw.SizedBox(height: 20),

              // 4. Audit Trail Activity Summary (ALL audit logs for period)
              pw.Text('Audit Trail Activity ($periodLabel - ${auditLogs.length} Events)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (auditLogs.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  color: PdfColors.grey50,
                  child: pw.Center(
                    child: pw.Text('No audit logs recorded for this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildPdfHeaderCell('Timestamp'),
                        _buildPdfHeaderCell('Action'),
                        _buildPdfHeaderCell('Actor'),
                        _buildPdfHeaderCell('Details'),
                      ],
                    ),
                    ...auditLogs.map((log) {
                      return pw.TableRow(
                        children: [
                          _buildPdfDataCell(DateFormat('dd-MM-yy HH:mm').format(log.timestamp.toLocal())),
                          _buildPdfDataCell(log.action, isBold: true),
                          _buildPdfDataCell(log.actorName),
                          _buildPdfDataCell(log.details),
                        ],
                      );
                    }),
                  ],
                ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
      final filename = 'Executive_Report_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      final savedPath = await _saveFileLocally(
        filename: filename,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$filename.pdf');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Executive PDF downloaded successfully: $savedPath'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildPdfStatBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: color.luminance > 0.5 ? color : PdfColors.white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildPdfDataCell(String text, {bool isBold = false, bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
