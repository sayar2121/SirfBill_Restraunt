import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'format_utils.dart';

class PdfA5Generator {
  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static Future<Uint8List> generateA5Bill({
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
    required PdfColor secondaryGreen,
    pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document(theme: theme);
    
    int itemsPerPage = 10;
    int numPages = (items.length / itemsPerPage).ceil();
    if (numPages == 0) numPages = 1;

    for (int i = 0; i < numPages; i++) {
      int start = i * itemsPerPage;
      int end = start + itemsPerPage;
      if (end > items.length) end = items.length;
      List<dynamic> chunk = items.sublist(start, end);
      bool isLastPage = (i == numPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5.landscape,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  shopName: shopName,
                  tagline: tagline,
                  address: address,
                  phone: phone,
                  email: email,
                  shopGstNo: shopGstNo,
                  cinNumber: cinNumber,
                  drugLicence: drugLicence,
                  invoiceNumber: invoiceNumber,
                  customerName: customerName,
                  customerPhone: customerPhone,
                  customerLocation: customerLocation,
                  customerGstNo: customerGstNo,
                  doctorName: doctorName,
                  billingDate: billingDate,
                  logoImage: logoImage,
                  primaryGreen: primaryGreen,
                ),
                pw.SizedBox(height: 4),
                _buildTable(
                  chunk: chunk,
                  startIndex: start,
                  primaryGreen: primaryGreen,
                ),
                pw.Spacer(),

                if (isLastPage)
                  _buildTotals(
                    subtotal: subtotal,
                    discount: discount,
                    tax: tax,
                    grandTotal: grandTotal,
                    roundedTotal: roundedTotal,
                    roundOff: roundOff,
                    paymentMethod: paymentMethod,
                    qrImage: qrImage,
                    bankName: bankName,
                    branchName: branchName,
                    acHolder: acHolder,
                    acNumber: acNumber,
                    ifsc: ifsc,
                    upiId: upiId,
                    shopName: shopName,
                    invoiceNumber: invoiceNumber,
                    primaryGreen: primaryGreen,
                  ),

                if (!isLastPage)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      i == 0 ? '* Continue to second page for total' : '* Continue to next page',
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                    ),
                  ),
                
                pw.SizedBox(height: 4),
                
                _buildTermsAndSignature(
                  term1: term1,
                  term2: term2,
                  term3: term3,
                  shopName: shopName,
                  primaryGreen: primaryGreen,
                ),
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String shopName,
    required String tagline,
    required String address,
    required String phone,
    required String email,
    required String shopGstNo,
    String cinNumber = '',
    String drugLicence = '',
    required String invoiceNumber,
    required String customerName,
    String? customerPhone,
    String? customerLocation,
    String? customerGstNo,
    String? doctorName,
    DateTime? billingDate,
    pw.ImageProvider? logoImage,
    required PdfColor primaryGreen,
  }) {
    final displayCin = cinNumber.isNotEmpty ? cinNumber : drugLicence;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 40,
                height: 40,
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
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  if (tagline.isNotEmpty)
                    pw.Text(
                      tagline,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    address,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Phone: $phone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Email: $email',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'GSTIN: $shopGstNo',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (displayCin.isNotEmpty)
                    pw.Text(
                      'CIN: $displayCin',
                      style: pw.TextStyle(
                        fontSize: 8,
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
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Invoice No: $invoiceNumber',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Date: ${billingDate != null ? DateFormat('dd-MM-yyyy HH:mm').format(billingDate) : DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: primaryGreen, thickness: 1),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Billed To:',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (customerPhone != null && customerPhone.isNotEmpty)
                  pw.Text(
                    'Phone: $customerPhone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                if (customerLocation != null && customerLocation.isNotEmpty)
                  pw.Text(
                    'Location: $customerLocation',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                if (customerGstNo != null && customerGstNo.isNotEmpty)
                  pw.Text(
                    'GSTIN: $customerGstNo',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable({
    required List<dynamic> chunk,
    required int startIndex,
    required PdfColor primaryGreen,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: primaryGreen, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(5),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(1.5),
        6: pw.FlexColumnWidth(1.5),
        7: pw.FlexColumnWidth(1.5),
        8: pw.FlexColumnWidth(1.5),
        9: pw.FlexColumnWidth(1.5),
        10: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
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
            'Total'
          ].map((text) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              )).toList(),
        ),
        ...chunk.asMap().entries.map((entry) {
          int idx = startIndex + entry.key;
          var item = entry.value;
          String itemName = item['name']?.toString().split(' - Item')[0] ?? '';
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text('${idx + 1}', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(itemName, style: const pw.TextStyle(fontSize: 7)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(item['batch']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(item['expiry']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(item['hsn']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(FormatUtils.formatQty(item), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(_parseDouble(item['mrp']).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text('${item['discount']?.toString() ?? '0'}%', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text('${item['cgst']?.toString() ?? '0'}%', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text('${item['sgst']?.toString() ?? '0'}%', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: pw.Text(_parseDouble(item['total']).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotals({
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double roundedTotal,
    required double roundOff,
    String? paymentMethod,
    pw.ImageProvider? qrImage,
    required String bankName,
    required String branchName,
    required String acHolder,
    required String acNumber,
    required String ifsc,
    String upiId = '',
    String shopName = '',
    String invoiceNumber = '',
    required PdfColor primaryGreen,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
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
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FlexColumnWidth(4),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bank Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                        pw.Text('Bank: $bankName', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('Branch: $branchName', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('A/C Name: $acHolder', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('A/C No: $acNumber', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('IFSC: $ifsc', style: const pw.TextStyle(fontSize: 7)),
                        if (upiId.isNotEmpty)
                          pw.Text('UPI: $upiId', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(
                      child: upiId.isNotEmpty
                          ? pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&am=${roundedTotal.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Bill $invoiceNumber")}',
                                  width: 55,
                                  height: 55,
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  '₹${roundedTotal.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : (qrImage != null ? pw.Image(qrImage, width: 60, height: 60) : pw.SizedBox()),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GST Summary', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('CGST', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text((tax / 2).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('SGST', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text((tax / 2).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7)),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST Total', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Taxable', style: const pw.TextStyle(fontSize: 7)), pw.Text(subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))]),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Discount', style: const pw.TextStyle(fontSize: 7)), pw.Text(discount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))]),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tax (GST)', style: const pw.TextStyle(fontSize: 7)), pw.Text(tax.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))]),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Payment Mode', style: const pw.TextStyle(fontSize: 7)), pw.Text(paymentMethod ?? 'CASH', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))]),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total', style: const pw.TextStyle(fontSize: 7)), pw.Text(grandTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))]),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Round Off', style: const pw.TextStyle(fontSize: 7)), pw.Text(roundOff.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))]),
                        pw.Divider(color: primaryGreen),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Rounded Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)), pw.Text(roundedTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen))]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTermsAndSignature({
    required String term1,
    required String term2,
    required String term3,
    required String shopName,
    required PdfColor primaryGreen,
  }) {
    return pw.Container(
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
                        pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                        if (term1.isNotEmpty) pw.Text(term1, style: const pw.TextStyle(fontSize: 7)),
                        if (term2.isNotEmpty) pw.Text(term2, style: const pw.TextStyle(fontSize: 7)),
                        if (term3.isNotEmpty) pw.Text(term3, style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'For $shopName',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        pw.SizedBox(height: 18), // Space for signature
                        pw.Text(
                          'Authorized Signatory',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
