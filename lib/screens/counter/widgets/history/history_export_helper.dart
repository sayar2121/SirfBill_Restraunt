import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:sirfbill_restaurant/models/counter_models.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../services/export_service.dart';
import '../../../../utils/pdf_generator.dart';

class HistoryExportHelper {
  static List<Map<String, dynamic>> filterTransactions(
    List<Map<String, dynamic>> allTransactions, {
    required String activeDateRange,
    required String selectedType,
    required String selectedPaymentMode,
    required String searchQuery,
    DateTimeRange? customDateRange,
    String? overrideDateRange,
  }) {
    final now = DateTime.now();
    final targetRange = overrideDateRange ?? activeDateRange;

    return allTransactions.where((tx) {
      DateTime date = tx['createdAtDate'] ?? now;

      bool matchesDate = false;
      switch (targetRange) {
        case 'Today':
          matchesDate =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          matchesDate = date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          );
          break;
        case 'This Month':
          matchesDate = date.year == now.year && date.month == now.month;
          break;
        case 'This Year':
          matchesDate = date.year == now.year;
          break;
        case 'Custom Range':
          if (customDateRange != null) {
            final start = customDateRange.start;
            final end = customDateRange.end.add(const Duration(days: 1));
            matchesDate = date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                date.isBefore(end);
          } else {
            matchesDate = true;
          }
          break;
        default:
          matchesDate = true;
      }

      final matchesSearch =
          tx['refNo'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          tx['customerName'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          tx['customerPhone'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      final matchesType = selectedType == 'All' || tx['type'] == selectedType;
      final matchesMode =
          selectedPaymentMode == 'All' || tx['paymentMode'] == selectedPaymentMode;

      return matchesDate && matchesSearch && matchesType && matchesMode;
    }).toList();
  }

  static Future<void> exportToExcel(
    BuildContext context,
    List<Map<String, dynamic>> targetData,
  ) async {
    if (targetData.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data available to export for the selected filter!'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating Excel Report...')),
      );
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['History'];
    excel.setDefaultSheet('History');

    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Bill No / Ref No'),
      TextCellValue('Customer Name'),
      TextCellValue('Type'),
      TextCellValue('Items'),
      TextCellValue('Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Status'),
    ]);

    for (var tx in targetData) {
      sheetObject.appendRow([
        TextCellValue(tx['date'].toString()),
        TextCellValue(tx['time'].toString()),
        TextCellValue(tx['refNo'].toString()),
        TextCellValue(tx['customerName'].toString()),
        TextCellValue(tx['type'].toString()),
        IntCellValue(tx['items'] as int),
        DoubleCellValue(double.tryParse(tx['amount'].toString()) ?? 0.0),
        TextCellValue(tx['paymentMode'].toString()),
        TextCellValue(tx['status'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      try {
        await FileSaver.instance.saveAs(
          name: 'History_Report_${DateTime.now().millisecondsSinceEpoch}',
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel report saved successfully to your device!'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      }
    }
  }

  static Future<void> exportToPdf(
    BuildContext context,
    List<Map<String, dynamic>> targetData,
  ) async {
    if (targetData.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data available to export for the selected filter!'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF Report...')),
      );
    }

    final dataToExport = targetData.map((tx) => {
      'Date': tx['date'].toString(),
      'Bill No': tx['refNo'].toString(),
      'Customer Name': tx['customerName'].toString(),
      'Type': tx['type'].toString(),
      'Amount': tx['amount'].toString(),
      'Mode': tx['paymentMode'].toString(),
      'Status': tx['status'].toString(),
    }).toList();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await ExportService.exportToPDF(dataToExport, 'History_Report_$timestamp');
  }

  static void viewBill(
    BuildContext context,
    SavedBill bill,
    Map<String, dynamic> shopSettings,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill View - ${bill.invoiceNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      return await PdfGenerator.generateBill(
                        items: bill.items,
                        subtotal: bill.subtotal,
                        discount: bill.discount,
                        tax: bill.tax,
                        grandTotal: bill.grandTotal,
                        invoiceNumber: bill.invoiceNo,
                        customerName: bill.customerName,
                        customerPhone: bill.customerPhone,
                        customerLocation: bill.customerLocation,
                        gstNumber: bill.customerGstin,
                        doctorName: bill.doctorName,
                        paymentMethod: bill.paymentMode,
                        shopSettings: shopSettings,
                        format: bill.format,
                        billingDate: bill.createdAt,
                      );
                    },
                    allowSharing: false,
                    allowPrinting: true,
                    canDebug: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: '${bill.invoiceNo}.pdf',
                    initialPageFormat: bill.format == 'Thermal'
                        ? const PdfPageFormat(
                            80 * PdfPageFormat.mm,
                            300 * PdfPageFormat.mm,
                          )
                        : bill.format == 'A5'
                        ? PdfPageFormat.a5.landscape
                        : PdfPageFormat.a4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
