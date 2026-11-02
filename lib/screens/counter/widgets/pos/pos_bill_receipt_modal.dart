import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Modal dialog that immediately renders the generated 80mm thermal receipt on-screen
/// for cashier verification and provides direct one-click printing and dismiss buttons.
class PosBillReceiptModal extends StatelessWidget {
  final String orderNumber;
  final String title;
  final Uint8List pdfBytes;
  final VoidCallback? onDismiss;

  const PosBillReceiptModal({
    super.key,
    required this.orderNumber,
    required this.title,
    required this.pdfBytes,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderNumber,
    required String title,
    required Uint8List pdfBytes,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PosBillReceiptModal(
        orderNumber: orderNumber,
        title: title,
        pdfBytes: pdfBytes,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 720,
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 22,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Invoice / Token: $orderNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () {
                      Navigator.pop(context);
                      onDismiss?.call();
                    },
                  ),
                ],
              ),
            ),

            // On-screen 80mm Receipt PDF Preview
            Expanded(
              child: PdfPreview(
                key: ValueKey(orderNumber),
                build: (format) async => pdfBytes,
                initialPageFormat: const PdfPageFormat(
                  80 * PdfPageFormat.mm,
                  280 * PdfPageFormat.mm,
                  marginAll: 4 * PdfPageFormat.mm,
                ),
                pageFormats: const {
                  '80mm Thermal Roll': PdfPageFormat(
                    80 * PdfPageFormat.mm,
                    280 * PdfPageFormat.mm,
                    marginAll: 4 * PdfPageFormat.mm,
                  ),
                },
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: 'Bill_${orderNumber.replaceAll("#", "")}.pdf',
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDismiss?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Printing.layoutPdf(
                        name: 'Bill_${orderNumber.replaceAll("#", "")}',
                        format: const PdfPageFormat(
                          80 * PdfPageFormat.mm,
                          280 * PdfPageFormat.mm,
                          marginAll: 4 * PdfPageFormat.mm,
                        ),
                        onLayout: (PdfPageFormat format) async => pdfBytes,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'Print Bill',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
