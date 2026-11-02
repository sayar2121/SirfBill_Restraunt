import 'package:flutter/material.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../utils/pdf_generator.dart';
import '../../../../models/counter_models.dart';

void showViewBillDialog(BuildContext context, SavedBill bill, Map<String, dynamic> shopSettings) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
                          marginAll: 4 * PdfPageFormat.mm,
                        )
                      : bill.format == 'A5'
                      ? PdfPageFormat.a5.landscape
                      : PdfPageFormat.a4,
                  pageFormats: bill.format == 'Thermal'
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
          ),
        ),
      );
    },
  );
}
