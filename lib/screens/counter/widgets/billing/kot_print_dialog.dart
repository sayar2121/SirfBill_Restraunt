import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../utils/kot_printer_helper.dart';
import '../../../../models/restaurant_pos_models.dart';

class KotPrintDialog extends StatelessWidget {
  final String kotNumber;
  final String orderNumber;
  final String orderType;
  final String? tableLabel;
  final String? floor;
  final String? customerName;
  final String? orderNotes;
  final List<PosCartItem> items;
  final DateTime? timestamp;
  final VoidCallback? onPrintComplete;

  const KotPrintDialog({
    super.key,
    required this.kotNumber,
    required this.orderNumber,
    required this.orderType,
    this.tableLabel,
    this.floor,
    this.customerName,
    this.orderNotes,
    required this.items,
    this.timestamp,
    this.onPrintComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? orderNotes,
    required List<PosCartItem> items,
    DateTime? timestamp,
    VoidCallback? onPrintComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => KotPrintDialog(
        kotNumber: kotNumber,
        orderNumber: orderNumber,
        orderType: orderType,
        tableLabel: tableLabel,
        floor: floor,
        customerName: customerName,
        orderNotes: orderNotes,
        items: items,
        timestamp: timestamp,
        onPrintComplete: onPrintComplete,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 650,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.print_rounded, size: 20, color: Color(0xFFF97316)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Print Kitchen Order Ticket (KOT)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$kotNumber • $orderNumber',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Thermal 80mm PDF Preview with Print & Share tools
            Expanded(
              child: PdfPreview(
                key: UniqueKey(),
                build: (format) => KotPrinterHelper.generateKotPdf(
                  kotNumber: kotNumber,
                  orderNumber: orderNumber,
                  orderType: orderType,
                  tableLabel: tableLabel,
                  floor: floor,
                  customerName: customerName,
                  orderNotes: orderNotes,
                  items: items,
                  timestamp: timestamp,
                ),
                initialPageFormat: PdfPageFormat(
                  80 * PdfPageFormat.mm,
                  (85.0 + (items.length * 9.0)).clamp(100.0, 300.0) * PdfPageFormat.mm,
                  marginAll: 4 * PdfPageFormat.mm,
                ),
                pageFormats: {
                  '80mm Roll': PdfPageFormat(
                    80 * PdfPageFormat.mm,
                    (85.0 + (items.length * 9.0)).clamp(100.0, 300.0) * PdfPageFormat.mm,
                    marginAll: 4 * PdfPageFormat.mm,
                  ),
                },
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: 'KOT_${orderNumber.replaceAll("#", "")}.pdf',

              ),
            ),

            const Divider(height: 1),
            // Footer Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await KotPrinterHelper.printKotDirectly(
                        context: context,
                        kotNumber: kotNumber,
                        orderNumber: orderNumber,
                        orderType: orderType,
                        tableLabel: tableLabel,
                        floor: floor,
                        customerName: customerName,
                        orderNotes: orderNotes,
                        items: items,
                        timestamp: timestamp,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        onPrintComplete?.call();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('System Print', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
