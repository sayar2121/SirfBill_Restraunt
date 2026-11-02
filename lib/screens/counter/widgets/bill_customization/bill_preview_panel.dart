import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class BillPreviewPanel extends StatelessWidget {
  final String previewFormat;
  final Uint8List? previewBytes;
  final bool isGenerating;
  final ValueChanged<String> onFormatChanged;
  final VoidCallback onGeneratePreview;

  const BillPreviewPanel({
    super.key,
    required this.previewFormat,
    required this.previewBytes,
    required this.isGenerating,
    required this.onFormatChanged,
    required this.onGeneratePreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              spacing: 16,
              children: [
                Text(
                  'Live Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'Thermal (80mm)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isGenerating ? null : onGeneratePreview,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: previewBytes == null
                  ? const Center(
                      child: Text(
                        'Click "Generate Preview" to see the bill format',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : PdfPreview(
                      build: (format) async => previewBytes!,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      allowPrinting: false,
                      allowSharing: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
