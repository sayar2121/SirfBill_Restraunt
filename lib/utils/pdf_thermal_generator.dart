import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'format_utils.dart';

class PdfThermalGenerator {
  static Future<Uint8List> generateThermalBill({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double roundedTotal,
    required String invoiceNumber,
    required String customerName,
    String? customerPhone,
    String? customerGstNo,
    required String shopName,
    required String address,
    required String phone,
    required String shopGstNo,
    String cinNumber = '',
    String drugLicence = '',
    String upiId = '',
    pw.ImageProvider? logoImage,
    pw.ImageProvider? qrImage,
    DateTime? billingDate,
    pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document(theme: theme);
    final displayCin = cinNumber.isNotEmpty ? cinNumber : drugLicence;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (logoImage != null)
                pw.Image(logoImage, width: 50, height: 50),
              pw.SizedBox(height: 5),
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                address,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Phone: $phone',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'GSTIN: $shopGstNo',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (displayCin.isNotEmpty)
                pw.Text(
                  'FSSAI: $displayCin',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Inv: $invoiceNumber',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    DateFormat('dd-MM-yyyy hh:mm a').format(billingDate ?? DateTime.now()),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Customer: ${customerName.isNotEmpty ? customerName : 'Walk-in Customer'}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              if (customerPhone != null && customerPhone.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Phone: $customerPhone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (customerGstNo != null && customerGstNo.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'GSTIN: $customerGstNo',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Thermal Items Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.6), // Item
                  1: const pw.FlexColumnWidth(0.8), // Qty
                  2: const pw.FlexColumnWidth(1.1), // Rate
                  3: const pw.FlexColumnWidth(0.9), // Disc%
                  4: const pw.FlexColumnWidth(0.9), // GST%
                  5: const pw.FlexColumnWidth(1.3), // Amount
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Qty',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'Rate',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Text(
                        'Disc',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'GST',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'Amt',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  ...items.map(
                    (item) {
                      double parseNum(dynamic val) {
                        if (val == null) return 0.0;
                        if (val is num) return val.toDouble();
                        if (val is String) return double.tryParse(val) ?? 0.0;
                        return 0.0;
                      }

                      final double rate = parseNum(item['price'] ?? item['mrp'] ?? item['unit_price']);
                      final double disc = parseNum(item['discount']);
                      final double cgst = parseNum(item['cgst']);
                      final double sgst = parseNum(item['sgst']);
                      double gst = parseNum(item['gst']);
                      if (gst == 0.0 && (cgst > 0.0 || sgst > 0.0)) {
                        gst = cgst + sgst;
                      }
                      final double total = parseNum(item['total']);

                      // If item gst wasn't specified, but bill has tax
                      if (gst == 0.0 && subtotal > 0 && tax > 0) {
                        final taxableBase = subtotal - discount;
                        if (taxableBase > 0) {
                          gst = (tax / taxableBase) * 100;
                        }
                      }

                      // Only show per-product discount in the row; total discount is shown at the bottom
                      final String discText = disc > 0
                          ? '${disc % 1 == 0 ? disc.toInt() : disc.toStringAsFixed(1)}%'
                          : '0%';
                      final String gstText = gst > 0
                          ? '${gst % 1 == 0 ? gst.toInt() : gst.toStringAsFixed(1)}%'
                          : '0%';

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              item['name'] ?? 'Unknown Item',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              FormatUtils.formatQty(item),
                              style: const pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              rate.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              discText,
                              style: const pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              gstText,
                              style: const pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                            child: pw.Text(
                              total.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    subtotal.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              if (discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discount:',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      discount.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Tax (GST):',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    tax.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              if (tax > 0) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 6, top: 2, bottom: 2),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  CGST:',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            (tax / 2).toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  SGST:',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            (tax / 2).toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    roundedTotal.toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you! Visit Again.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Sirfbill',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Powered By Naiyo24 Pvt. Ltd.',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
