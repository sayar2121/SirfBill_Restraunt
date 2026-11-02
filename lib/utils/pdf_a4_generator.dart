import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'format_utils.dart';

class PdfA4Generator {
  static Future<Uint8List> generateA4Bill({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double roundedTotal,
    required double roundOff,
    required String invoiceNumber,
    required String customerName,
    String? customerPhone,
    String? customerLocation,
    String? paymentMethod,
    String? doctorName,
    String? customerGstNo,
    required String shopName,
    required String tagline,
    required String address,
    required String phone,
    required String landline,
    required String email,
    required String shopGstNo,
    String cinNumber = '',
    String drugLicence = '',
    required String bankName,
    required String branchName,
    required String acHolder,
    required String acNumber,
    required String ifsc,
    String upiId = '',
    required String term1,
    required String term2,
    required String term3,
    pw.ImageProvider? logoImage,
    pw.ImageProvider? qrImage,
    DateTime? billingDate,
    required PdfColor primaryGreen,
    pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document(theme: theme);
    String format = 'A4'; // Hardcode format so ternary logic still evaluates cleanly
    final displayCin = cinNumber.isNotEmpty ? cinNumber : drugLicence;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: format == 'A4' ? 65 : 40,
                      height: format == 'A4' ? 65 : 40,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName,
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 16 : 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        if (tagline.isNotEmpty)
                          pw.Text(
                            tagline,
                            style: pw.TextStyle(
                              fontSize: format == 'A4' ? 10 : 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          address,
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                          ),
                        ),
                        pw.Text(
                          'Phone: $phone ${landline.isNotEmpty ? '| $landline' : ''}',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                          ),
                        ),
                        pw.Text(
                          'Email: $email',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                          ),
                        ),
                        pw.Text(
                          'GSTIN: $shopGstNo',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (displayCin.isNotEmpty)
                          pw.Text(
                            'CIN: $displayCin',
                            style: pw.TextStyle(
                              fontSize: format == 'A4' ? 10 : 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: format == 'A4' ? 16 : 12,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Invoice No: $invoiceNumber',
                        style: pw.TextStyle(
                          fontSize: format == 'A4' ? 10 : 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd-MM-yyyy HH:mm').format(billingDate ?? DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: format == 'A4' ? 10 : 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: format == 'A4' ? 8 : 4),
              pw.Divider(color: primaryGreen, thickness: 1.5),
              pw.SizedBox(height: format == 'A4' ? 4 : 2),

              // Customer Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Billed To:',
                        style: pw.TextStyle(
                          fontSize: format == 'A4' ? 10 : 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(
                          fontSize: format == 'A4' ? 12 : 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        pw.Text(
                          'Phone: $customerPhone',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                          ),
                        ),
                      if (customerLocation != null &&
                          customerLocation.isNotEmpty)
                        pw.Text(
                          'Location: $customerLocation',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                          ),
                        ),
                      if (customerGstNo != null && customerGstNo.isNotEmpty)
                        pw.Text(
                          'GSTIN: $customerGstNo',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 10 : 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: format == 'A4' ? 16 : 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Items Table
            pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(color: primaryGreen, width: 0.5),
                right: pw.BorderSide(color: primaryGreen, width: 0.5),
                top: pw.BorderSide(color: primaryGreen, width: 0.5),
                bottom: pw.BorderSide(color: primaryGreen, width: 0.5),
                verticalInside: pw.BorderSide(
                  color: primaryGreen,
                  width: 0.5,
                ),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(0.8),
                6: const pw.FlexColumnWidth(0.8),
                7: const pw.FlexColumnWidth(0.8),
                8: const pw.FlexColumnWidth(0.8),
                9: const pw.FlexColumnWidth(0.8),
                10: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  repeat: true,
                  decoration: pw.BoxDecoration(color: primaryGreen),
                  children: [
                    'S.No',
                    'Item Name',
                    'Batch',
                    'Expiry',
                    'HSN',
                    'Qty',
                    'MRP',
                    'Disc%',
                    'CGST%',
                    'SGST%',
                    'Total',
                  ]
                  .map(
                    (text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: format == 'A4' ? 8 : 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
                ),
                // Data rows
                ...items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          '${idx + 1}',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          item['name'],
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          item['batch']?.toString() ?? '-',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          item['expiry']?.toString() ?? '-',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          item['hsn']?.toString() ?? '-',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          FormatUtils.formatQty(item),
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          (item['mrp'] ?? 0.0).toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          '${item['discount']?.toString() ?? '0'}%',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          '${item['cgst']?.toString() ?? '0'}%',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          '${item['sgst']?.toString() ?? '0'}%',
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                          vertical: format == 'A4' ? 4 : 2,
                          horizontal: 4,
                        ),
                        child: pw.Text(
                          (item['total'] ?? 0.0).toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: format == 'A4' ? 8 : 7,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Bank Details, GST, Summary (Appended immediately after the table on the last page)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryGreen, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: primaryGreen, width: 1),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          // Left Side: Bank Details & QR
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Bank Details',
                                        style: pw.TextStyle(
                                          fontSize: format == 'A4' ? 10 : 8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text('Bank: $bankName', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                      pw.Text('Branch: $branchName', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                      pw.Text('A/C Name: $acHolder', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                      pw.Text('A/C No: $acNumber', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                      pw.Text('IFSC: $ifsc', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                      if (upiId.isNotEmpty)
                                        pw.Text('UPI: $upiId', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                if (upiId.isNotEmpty)
                                  pw.Column(
                                    children: [
                                      pw.BarcodeWidget(
                                        barcode: pw.Barcode.qrCode(),
                                        data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&am=${roundedTotal.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Bill $invoiceNumber")}',
                                        width: format == 'A4' ? 65 : 45,
                                        height: format == 'A4' ? 65 : 45,
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        '₹${roundedTotal.toStringAsFixed(2)}',
                                        style: pw.TextStyle(
                                          fontSize: format == 'A4' ? 7 : 6,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (qrImage != null)
                                  pw.Container(
                                    width: format == 'A4' ? 70 : 50,
                                    height: format == 'A4' ? 70 : 50,
                                    child: pw.Image(qrImage),
                                  ),
                              ],
                            ),
                          ),
                          // Middle: GST Summary
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'GST Summary',
                                  style: pw.TextStyle(
                                    fontSize: format == 'A4' ? 10 : 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('CGST', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text((tax / 2).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('SGST', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text((tax / 2).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Divider(color: PdfColors.grey300),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('GST Total', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold)),
                                    pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Right: Amount Summary
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Taxable', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(subtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Discount', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(discount.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Tax (GST)', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Payment Mode', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(paymentMethod ?? 'CASH', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Grand Total', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Round Off', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                    pw.Text(roundOff.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  ],
                                ),
                                pw.Divider(color: primaryGreen),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Rounded Total', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                                    pw.Text(roundedTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryGreen, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: primaryGreen, width: 1),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(7),
                      1: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Terms & Conditions',
                                  style: pw.TextStyle(
                                    fontSize: format == 'A4' ? 10 : 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                if (term1.isNotEmpty)
                                  pw.Text(
                                    term1,
                                    style: pw.TextStyle(
                                      fontSize: format == 'A4' ? 8 : 7,
                                    ),
                                  ),
                                if (term2.isNotEmpty)
                                  pw.Text(
                                    term2,
                                    style: pw.TextStyle(
                                      fontSize: format == 'A4' ? 8 : 7,
                                    ),
                                  ),
                                if (term3.isNotEmpty)
                                  pw.Text(
                                    term3,
                                    style: pw.TextStyle(
                                      fontSize: format == 'A4' ? 8 : 7,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.SizedBox(height: format == 'A4' ? 15 : 10),
                                pw.Text(
                                  'For $shopName',
                                  style: pw.TextStyle(
                                    fontSize: format == 'A4' ? 8 : 7,
                                  ),
                                ),
                                pw.Text(
                                  'Authorized Signatory',
                                  style: pw.TextStyle(
                                    fontSize: format == 'A4' ? 8 : 7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
