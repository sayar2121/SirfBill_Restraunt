import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/shop_settings_service.dart';

class RestaurantReportExportHelper {
  /// Opens a modern export options sheet allowing user to export to Excel or PDF
  static void showExportOptions({
    required BuildContext context,
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          'Export Analytics Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Period: $periodLabel (${orders.length} orders analyzed)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Excel Export Button
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  tileColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Export Complete Excel Workbook (.xlsx)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Includes 4 tabs: Financial Summary, Orders Register, Item-wise Sales, Audit Trail',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
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

                // PDF Export Button
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  tileColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6366F1),
                    child: Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Export Executive PDF Report (.pdf)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Polished presentation with financial breakdown, payment mix, and channel metrics',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
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
        );
      },
    );
  }

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

      summarySheet.appendRow([
        TextCellValue('RESTAURANT EXECUTIVE REPORT'),
        TextCellValue(''),
      ]);
      summarySheet.appendRow([
        TextCellValue('Reporting Period:'),
        TextCellValue(periodLabel),
      ]);
      summarySheet.appendRow([
        TextCellValue('Generated At:'),
        TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())),
      ]);
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
          TextCellValue(DateFormat('dd-MM-yyyy').format(o.createdAt)),
          TextCellValue(DateFormat('hh:mm a').format(o.createdAt)),
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
          TextCellValue(DateFormat('dd-MM-yyyy HH:mm:ss').format(log.timestamp)),
          TextCellValue(log.action),
          TextCellValue(log.actorName),
          TextCellValue(log.details),
          TextCellValue(log.severity.toUpperCase()),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final filename = 'Restaurant_Report_${periodLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveAs(
          name: filename,
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel Report "$filename.xlsx" exported successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Excel report: $e'),
            backgroundColor: Colors.red,
          ),
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
      final settings = await ShopSettingsService.getSettings();
      final restaurantName = (settings['shop_name'] ?? 'SirfBill Restaurant').toString().toUpperCase();
      final address = (settings['address'] ?? '').toString();
      final gstin = (settings['gst_number'] ?? settings['gstin'] ?? '').toString();

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
                          restaurantName,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                        ),
                        if (address.isNotEmpty)
                          pw.Text(address, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        if (gstin.isNotEmpty)
                          pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
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
                      _buildPdfHeaderCell('Gross Revenue'),
                      _buildPdfHeaderCell('Net Revenue'),
                      _buildPdfHeaderCell('GST Collected'),
                      _buildPdfHeaderCell('Discounts'),
                      _buildPdfHeaderCell('Total Orders'),
                      _buildPdfHeaderCell('Avg Check (AOV)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfDataCell('Rs. ${summary.grossSales.toStringAsFixed(2)}', isBold: true),
                      _buildPdfDataCell('Rs. ${summary.netSales.toStringAsFixed(2)}'),
                      _buildPdfDataCell('Rs. ${summary.totalGst.toStringAsFixed(2)}'),
                      _buildPdfDataCell('Rs. ${summary.totalDiscount.toStringAsFixed(2)}'),
                      _buildPdfDataCell('${summary.totalOrders} bills'),
                      _buildPdfDataCell('Rs. ${summary.averageOrderValue.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // 2. Tender & Channels breakdown
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Payment Tender mix
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
                                _buildPdfHeaderCell('Method'),
                                _buildPdfHeaderCell('Amount (INR)'),
                              ],
                            ),
                            pw.TableRow(children: [_buildPdfDataCell('Cash Tendered'), _buildPdfDataCell('Rs. ${summary.cashSales.toStringAsFixed(2)}')]),
                            pw.TableRow(children: [_buildPdfDataCell('UPI / Dynamic QR'), _buildPdfDataCell('Rs. ${summary.upiSales.toStringAsFixed(2)}')]),
                            pw.TableRow(children: [_buildPdfDataCell('Card / EDC Terminal'), _buildPdfDataCell('Rs. ${summary.cardSales.toStringAsFixed(2)}')]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),

                  // Order Channels mix
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Order Channels Distribution', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                              children: [
                                _buildPdfHeaderCell('Channel'),
                                _buildPdfHeaderCell('Amount (INR)'),
                              ],
                            ),
                            pw.TableRow(children: [_buildPdfDataCell('Dine-In Tables'), _buildPdfDataCell('Rs. ${summary.dineInSales.toStringAsFixed(2)}')]),
                            pw.TableRow(children: [_buildPdfDataCell('Takeaway Counter'), _buildPdfDataCell('Rs. ${summary.takeawaySales.toStringAsFixed(2)}')]),
                            pw.TableRow(children: [_buildPdfDataCell('Delivery Orders'), _buildPdfDataCell('Rs. ${summary.deliverySales.toStringAsFixed(2)}')]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 3. Top Selling Dishes table
              pw.Text('Top Performing Dishes & Menu Items', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (topDishes.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No menu items sold in this period.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
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
                    ...topDishes.take(15).toList().asMap().entries.map((entry) {
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

              // 4. Audit Trail Activity Summary
              pw.Text(
                periodLabel == 'All Time'
                    ? 'Audit Trail Activity (Latest Entries)'
                    : 'Recent Audit Trail Activity',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              if (auditLogs.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: pw.BoxDecoration(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No audit logs recorded for this period.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
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
                    ...auditLogs.take(30).map((log) {
                      return pw.TableRow(
                        children: [
                          _buildPdfDataCell(DateFormat('dd-MM-yy HH:mm').format(log.timestamp)),
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
      final filename = 'Executive_Report_${periodLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      await FileSaver.instance.saveAs(
        name: filename,
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Report "$filename.pdf" downloaded successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
