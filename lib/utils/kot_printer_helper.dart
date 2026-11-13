import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/api_client.dart';
import '../config/api_constants.dart';
import '../models/restaurant_pos_models.dart';

class KotPrinterHelper {
  /// Generates clean 80mm thermal receipt bytes for Kitchen Order Ticket
  static Future<Uint8List> generateKotPdf({
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? orderNotes,
    required List<PosCartItem> items,
    DateTime? timestamp,
  }) async {
    final pdf = pw.Document();
    final time = (timestamp ?? DateTime.now()).toLocal();
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

    // Consolidate identical items in the KOT
    final List<PosCartItem> consolidatedItems = [];
    for (final it in items) {
      final idx = consolidatedItems.indexWhere((c) =>
          c.item.name == it.item.name && (c.notes ?? '') == (it.notes ?? ''));
      if (idx >= 0) {
        consolidatedItems[idx] = consolidatedItems[idx].copyWith(
          quantity: consolidatedItems[idx].quantity + it.quantity,
        );
      } else {
        consolidatedItems.add(it);
      }
    }

    // Calculate dynamic height based on content to avoid massive empty paper roll
    // Base height for header, order details, table info, divider lines and footer is ~80mm
    // Each item line takes ~8-12mm
    final calculatedHeightMm = (85.0 + (consolidatedItems.length * 9.0)).clamp(100.0, 300.0);
    final pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, calculatedHeightMm * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '*** KITCHEN ORDER TICKET ***',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  kotNumber,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Order: $orderNumber [${orderType.toUpperCase()}]',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              if (tableLabel != null && tableLabel.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'TABLE: $tableLabel ${floor != null ? "($floor)" : ""}',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Time: $formattedTime', style: const pw.TextStyle(fontSize: 8.5)),
                  pw.Text('Server: POS', style: const pw.TextStyle(fontSize: 8.5)),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty)
                pw.Text('Guest: $customerName', style: const pw.TextStyle(fontSize: 8.5)),
              if (orderNotes != null && orderNotes.isNotEmpty)
                pw.Text('Note: $orderNotes', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Items table
              pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('QTY', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 8, child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 3),
              ...consolidatedItems.map((it) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${it.quantity}x',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              it.item.name,
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (it.notes != null && it.notes!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 14),
                          child: pw.Text(
                            '** ${it.notes} **',
                            style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Center(
                child: pw.Text(
                  'Total Items: ${consolidatedItems.fold<int>(0, (sum, i) => sum + i.quantity)}',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct System Print Dialog using browser/native print manager
  static Future<void> printKotDirectly({
    required BuildContext context,
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? orderNotes,
    required List<PosCartItem> items,
    DateTime? timestamp,
  }) async {
    final pdfBytes = await generateKotPdf(
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

    final heightMm = (85.0 + (items.length * 9.0)).clamp(100.0, 300.0);
    final thermal80mm = PdfPageFormat(80 * PdfPageFormat.mm, heightMm * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);

    await Printing.layoutPdf(
      name: 'KOT_${orderNumber.replaceAll("#", "")}',
      format: thermal80mm,
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Generates a single combined 80mm PDF containing Page 1 (KOT for Kitchen) and Page 2 (Final Customer Bill).
  /// Perfect for Takeaway, Dine-In, and Fast Food checkout so thermal printer cuts/prints both together with the exact same template and branding!
  static Future<Uint8List> generateCombinedTakeawayPdf({
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? customerPhone,
    String? orderNotes,
    required List<PosCartItem> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String shopName,
    required String address,
    required String phone,
    required String shopGstNo,
    String fssaiNo = '',
    String upiId = '',
    String? logoUrl,
    Uint8List? logoBytes,
    DateTime? timestamp,
  }) async {
    final pdf = pw.Document();

    // Resolve Logo Image for Bill
    pw.ImageProvider? billLogo;
    if (logoBytes != null) {
      billLogo = pw.MemoryImage(logoBytes);
    } else if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      try {
        final fullLogoUrl = logoUrl.startsWith('http')
            ? logoUrl
            : '${ApiConstants.baseUrl}${logoUrl.startsWith('/') ? '' : '/'}$logoUrl';
        final res = await ApiClient().dio.get(
          fullLogoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.statusCode == 200 && res.data != null) {
          billLogo = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }
    final time = (timestamp ?? DateTime.now()).toLocal();
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

    // 1. Consolidate identical items
    final List<PosCartItem> consolidatedItems = [];
    for (final it in items) {
      final idx = consolidatedItems.indexWhere((c) =>
          c.item.name == it.item.name && (c.notes ?? '') == (it.notes ?? ''));
      if (idx >= 0) {
        consolidatedItems[idx] = consolidatedItems[idx].copyWith(
          quantity: consolidatedItems[idx].quantity + it.quantity,
        );
      } else {
        consolidatedItems.add(it);
      }
    }

    final kotHeightMm = (85.0 + (consolidatedItems.length * 9.0)).clamp(100.0, 300.0);
    final kotPageFormat = PdfPageFormat(80 * PdfPageFormat.mm, kotHeightMm * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);

    // PAGE 1: KITCHEN ORDER TICKET (KOT)
    pdf.addPage(
      pw.Page(
        pageFormat: kotPageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '*** KITCHEN ORDER TICKET ***',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  kotNumber,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Order: $orderNumber [${orderType.toUpperCase()}]',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              if (tableLabel != null && tableLabel.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'TABLE: $tableLabel ${floor != null ? "($floor)" : ""}',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Time: $formattedTime', style: const pw.TextStyle(fontSize: 8.5)),
                  pw.Text('Type: ${orderType.toUpperCase()}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty)
                pw.Text('Guest: $customerName', style: const pw.TextStyle(fontSize: 8.5)),
              if (orderNotes != null && orderNotes.isNotEmpty)
                pw.Text('Note: $orderNotes', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Items table
              pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('QTY', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 8, child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 3),
              ...consolidatedItems.map((it) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${it.quantity}x',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              it.item.name,
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (it.notes != null && it.notes!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 14),
                          child: pw.Text(
                            '** ${it.notes} **',
                            style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Center(
                child: pw.Text(
                  'Total Items: ${consolidatedItems.fold<int>(0, (sum, i) => sum + i.quantity)}',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  '--- KITCHEN COPY ---',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: TAX INVOICE / OFFICIAL CUSTOMER BILL
    // Exact match to the official backend thermal tax invoice
    final double cgstVal = tax > 0 ? (tax / 2) : 0.0;
    final double sgstVal = tax > 0 ? (tax / 2) : 0.0;
    final billHeightMm = (130.0 + (consolidatedItems.length * 8.5) + (upiId.isNotEmpty ? 35.0 : 0.0)).clamp(145.0, 380.0);
    final billPageFormat = PdfPageFormat(80 * PdfPageFormat.mm, billHeightMm * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: billPageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo (if uploaded)
              if (billLogo != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Image(billLogo, fit: pw.BoxFit.contain),
                ),
              ],

              // 1. Outlet Name
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  address,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (phone.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Tel: $phone',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (shopGstNo.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'GSTIN: $shopGstNo',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (fssaiNo.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'FSSAI: $fssaiNo',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.0),
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Divider(thickness: 1.0),
              pw.SizedBox(height: 3),

              // Metadata Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill No: $orderNumber', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    tableLabel != null && tableLabel.isNotEmpty
                        ? 'Table: $tableLabel'
                        : (orderType.toUpperCase() == 'DINE_IN' ? 'Table: Dine-in' : 'Table: Takeaway'),
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Type: ${orderType.toUpperCase()}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $formattedTime', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty && customerName != 'Walk-in') ...[
                pw.SizedBox(height: 1.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.0),

              // Items table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(5.0),
                  1: const pw.FlexColumnWidth(1.6),
                  2: const pw.FlexColumnWidth(2.3),
                  3: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('ITEM', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...consolidatedItems.map((ci) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                          child: pw.Text(ci.item.name, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                          child: pw.Text('${ci.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                          child: pw.Text(ci.item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                          child: pw.Text(ci.totalPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Divider(thickness: 1.0),
              pw.SizedBox(height: 2),

              // Summary Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Rs. ${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (discount > 0) ...[
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('-Rs. ${discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              if (tax > 0) ...[
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST (2.5%):', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Rs. ${cgstVal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST (2.5%):', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Rs. ${sgstVal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1.2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PAID AMOUNT:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 1.2),
              pw.SizedBox(height: 6),

              // Footer matching official receipt
              pw.Text(
                'THANK YOU FOR DINING\nWITH US!',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'Please visit again',
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Sirfbill',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Powered By Naiyo24 Pvt. Ltd.',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
