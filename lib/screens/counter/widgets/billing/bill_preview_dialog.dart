import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class BillPreviewDialog extends StatelessWidget {
  final Future<Uint8List> pdfFuture;
  final String format;
  final String invoiceNo;

  const BillPreviewDialog({
    super.key,
    required this.pdfFuture,
    required this.format,
    required this.invoiceNo,
  });

  static void show(
    BuildContext context, {
    required Future<Uint8List> pdfFuture,
    required String format,
    required String invoiceNo,
  }) {
    showDialog(
      context: context,
      builder: (context) => BillPreviewDialog(
        pdfFuture: pdfFuture,
        format: format,
        invoiceNo: invoiceNo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 800,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FutureBuilder<Uint8List>(
          future: pdfFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating preview...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const SizedBox();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill Preview ($format)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    key: UniqueKey(), // Force fresh render to fix Flutter Web iframe bug
                    build: (format) => snapshot.data!,
                    allowPrinting: true,
                    allowSharing: false,
                    canDebug: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: '$invoiceNo.pdf',
                    initialPageFormat: format == 'Thermal'
                        ? const PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm)
                        : format == 'A5'
                            ? PdfPageFormat.a5.landscape
                            : PdfPageFormat.a4,
                    pageFormats: format == 'Thermal'
                        ? const {
                            '80mm Roll': PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm),
                          }
                        : const {
                            'A4': PdfPageFormat.a4,
                            'A5': PdfPageFormat.a5,
                          },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
