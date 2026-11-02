import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'shop_settings_service.dart';
import '../config/api_constants.dart';

class ExportService {
  static Future<void> _exportOrShare(String filename, Uint8List bytes, String ext, MimeType mimeType) async {
    await FileSaver.instance.saveAs(
      name: filename,
      bytes: bytes,
      fileExtension: ext,
      mimeType: mimeType,
    );
  }
  static Future<void> exportHeadersToCSV(
    List<String> headers,
    String filename,
  ) async {
    final csv = '${headers.join(',')}\n';
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await _exportOrShare(filename, bytes, 'csv', MimeType.csv);
  }

  static Future<void> exportToCSV(
    List<Map<String, dynamic>> data,
    String filename,
  ) async {
    if (data.isEmpty) return;

    final headers = data.first.keys.where((k) => k != 'id').toList();
    String csv = '${headers.join(',')}\n';

    for (var row in data) {
      final values = headers
          .map((h) => '"${row[h]?.toString().replaceAll('"', '""') ?? ''}"')
          .join(',');
      csv += '$values\n';
    }

    final bytes = Uint8List.fromList(utf8.encode(csv));
    await _exportOrShare(filename, bytes, 'csv', MimeType.csv);
  }

  static Future<void> exportToExcel(
    List<Map<String, dynamic>> data,
    String filename,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    if (data.isNotEmpty) {
      final headers = data.first.keys.where((k) => k != 'id').toList();
      sheetObject.appendRow(
        headers.map((h) => TextCellValue(h.toUpperCase())).toList(),
      );

      for (var row in data) {
        final values = headers
            .map((h) => TextCellValue(row[h]?.toString() ?? ''))
            .toList();
        sheetObject.appendRow(values);
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await _exportOrShare(filename, Uint8List.fromList(bytes), 'xlsx', MimeType.microsoftExcel);
    }
  }

  static Future<void> exportToPDF(
    List<Map<String, dynamic>> data,
    String filename, [
    Map<String, dynamic>? shopDetails,
  ]) async {
    final pdf = pw.Document();

    if (shopDetails == null) {
      try {
        shopDetails = await ShopSettingsService.getSettings();
      } catch (e) {
        // Fallback to empty if fetch fails
      }
    }

    if (data.isNotEmpty) {
      final headers = data.first.keys.where((k) => k != 'id').toList();
      final tableData = [headers.map((h) => h.toUpperCase()).toList()];

      for (var row in data) {
        tableData.add(headers.map((h) => row[h]?.toString() ?? '').toList());
      }

      // Load the logo image
      pw.ImageProvider logoImage;
      if (shopDetails?['logo_url'] != null && shopDetails!['logo_url'].toString().isNotEmpty) {
        try {
          final logoUrl = shopDetails['logo_url'].toString().startsWith('http') 
              ? shopDetails['logo_url'] 
              : '${ApiConstants.baseUrl}${shopDetails['logo_url']}';
          final response = await Dio().get(
            logoUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          logoImage = pw.MemoryImage(Uint8List.fromList(response.data));
        } catch (e) {
          final logoBytes = await rootBundle.load('assets/LOGO.png');
          logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        }
      } else {
        final logoBytes = await rootBundle.load('assets/LOGO.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 60, height: 60),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            shopDetails?['name']?.toString() ?? 'Shop Directory Report',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700,
                            ),
                          ),
                          if (shopDetails?['location'] != null || shopDetails?['city'] != null)
                            pw.Text(
                              [shopDetails?['location'], shopDetails?['city']].where((e) => e != null && e.toString().isNotEmpty).join(', '),
                              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                            ),
                          if (shopDetails?['contact'] != null)
                            pw.Text(
                              'Phone: ${shopDetails?['contact']}',
                              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                            ),
                          if (shopDetails?['email'] != null)
                            pw.Text(
                              'Email: ${shopDetails?['email']}',
                              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                            ),
                          if (shopDetails?['gstin'] != null)
                            pw.Text(
                              'GSTIN: ${shopDetails?['gstin']}',
                              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Inventory Export',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green600,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                cellStyle: const pw.TextStyle(fontSize: 10),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(
                    color: PdfColors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ];
          },
        ),
      );
    }

    final bytes = await pdf.save();
    await _exportOrShare(filename, bytes, 'pdf', MimeType.pdf);
  }
}
