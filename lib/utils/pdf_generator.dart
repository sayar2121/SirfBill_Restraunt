import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:sirfbill_restaurant/config/api_client.dart';
import 'package:printing/printing.dart';
import 'package:sirfbill_restaurant/utils/pdf_thermal_generator.dart';
import 'package:sirfbill_restaurant/utils/pdf_a4_generator.dart';
import 'package:sirfbill_restaurant/utils/pdf_a5_generator.dart';

Future<Uint8List> generateBillIsolate(Map<String, dynamic> args) async {
  return PdfGenerator.generateBill(
    items: args['items'],
    subtotal: args['subtotal'],
    discount: args['discount'],
    tax: args['tax'],
    grandTotal: args['grandTotal'],
    invoiceNumber: args['invoiceNumber'],
    customerName: args['customerName'],
    format: args['format'],
    customerPhone: args['customerPhone'],
    customerLocation: args['customerLocation'],
    paymentMethod: args['paymentMethod'],
    doctorName: args['doctorName'],
    shopSettings: args['shopSettings'],
    logoBytes: args['logoBytes'],
    qrBytes: args['qrBytes'],
    billingDate: args['billingDate'] != null ? DateTime.tryParse(args['billingDate'].toString()) : null,
  );
}

class PdfGenerator {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedFontBold;
  static Uint8List? _cachedDefaultLogo;
  static Uint8List? _cachedLogoBytes;
  static String? _cachedLogoUrl;

  static Uint8List? _cachedQrBytes;
  static String? _cachedQrUrl;

  static String? getCachedLogoUrl() => _cachedLogoUrl;
  
  static Future<void> preloadLogo(String url) async {
    if (url.isEmpty || url == _cachedLogoUrl) return;
    try {
      final res = await ApiClient().dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200) {
        _cachedLogoBytes = res.data;
        _cachedLogoUrl = url;
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> preloadFonts() async {
    _cachedFont ??= await PdfGoogleFonts.robotoRegular();
    _cachedFontBold ??= await PdfGoogleFonts.robotoBold();
  }

  static String? getCachedQrUrl() => _cachedQrUrl;
  
  static Future<void> preloadQr(String url) async {
    if (url.isEmpty || url == _cachedQrUrl) return;
    try {
      final res = await ApiClient().dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200) {
        _cachedQrBytes = res.data;
        _cachedQrUrl = url;
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<Uint8List> generateBill({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String invoiceNumber,
    required String customerName,
    required String format,
    String? customerPhone,
    String? customerLocation,
    String? paymentMethod,
    String? doctorName,
    String? gstNumber,
    Map<String, dynamic>? shopSettings,
    Uint8List? logoBytes,
    Uint8List? qrBytes,
    DateTime? billingDate,
  }) async {
    _cachedFont ??= await PdfGoogleFonts.robotoRegular();
    _cachedFontBold ??= await PdfGoogleFonts.robotoBold();

    final theme = pw.ThemeData.withFont(base: _cachedFont, bold: _cachedFontBold);

    pw.ImageProvider? logoImage;
    pw.ImageProvider? qrImage;

    String? rawLogoUrl = (shopSettings?['logo_url'] ?? shopSettings?['extra_data']?['logo_url'])?.toString();
    if (logoBytes != null) {
      logoImage = pw.MemoryImage(logoBytes);
    } else if (rawLogoUrl != null && rawLogoUrl.trim().isNotEmpty) {
      String url = rawLogoUrl.startsWith('http://') || rawLogoUrl.startsWith('https://')
          ? rawLogoUrl
          : '${ApiClient().dio.options.baseUrl}${rawLogoUrl.startsWith('/') ? '' : '/'}$rawLogoUrl';
      if (_cachedLogoUrl == url && _cachedLogoBytes != null) {
        logoImage = pw.MemoryImage(_cachedLogoBytes!);
      } else {
        try {
          final res = await ApiClient().dio.get(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedLogoBytes = res.data;
            _cachedLogoUrl = url;
            logoImage = pw.MemoryImage(_cachedLogoBytes!);
          }
        } catch (e) {
          // Fallback to local
        }
      }
    }

    // Final fallback for logo
    if (logoImage == null) {
      try {
        if (_cachedDefaultLogo == null) {
          final ByteData data = await rootBundle.load('assets/LOGO.png');
          _cachedDefaultLogo = data.buffer.asUint8List();
        }
        logoImage = pw.MemoryImage(_cachedDefaultLogo!);
      } catch (e) {
        // ignore
      }
    }

    if (qrBytes != null) {
      qrImage = pw.MemoryImage(qrBytes);
    } else if (shopSettings?['qr_url'] != null &&
        shopSettings!['qr_url'].toString().isNotEmpty) {
      String url = shopSettings['qr_url'];
      if (_cachedQrUrl == url && _cachedQrBytes != null) {
        qrImage = pw.MemoryImage(_cachedQrBytes!);
      } else {
        try {
          final res = await ApiClient().dio.get(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedQrBytes = res.data;
            _cachedQrUrl = url;
            qrImage = pw.MemoryImage(_cachedQrBytes!);
          }
        } catch (e) {
          // Fallback
        }
      }
    }

    final String shopName = shopSettings?['shop_name'] ?? 'SirfBill Print Shop';
    final String tagline =
        shopSettings?['tagline'] ?? 'Your Trusted Health Partner';
    final String address =
        shopSettings?['address'] ?? '123 Health Avenue, Medical District';
    final String phone = shopSettings?['phone'] ?? '+91 98765 43210';
    final String landline = shopSettings?['landline'] ?? '';
    final String email = shopSettings?['email'] ?? 'contact@sirfbill.com';
    final String shopGstNo = shopSettings?['gst_number'] ?? 'Not Available';
    final String cinNumber =
        shopSettings?['cin_number'] ?? shopSettings?['drug_licence'] ?? '';
    final String drugLicence = cinNumber;
    final String customerGstNo = gstNumber?.isNotEmpty == true
        ? gstNumber!
        : '';

    final String bankName = shopSettings?['bank_name'] ?? 'State Bank of India';
    final String branchName = shopSettings?['branch_name'] ?? 'Main Branch';
    final String acHolder = shopSettings?['ac_holder_name'] ?? shopName;
    final String acNumber = shopSettings?['ac_number'] ?? '123456789012';
    final String ifsc = shopSettings?['ifsc_code'] ?? 'SBIN0000123';
    final String upiId = shopSettings?['upi_id']?.toString().trim() ?? '';

    final String term1 =
        shopSettings?['terms_1'] ??
        '1. Printed goods once sold will not be taken back.';
    final String term2 =
        shopSettings?['terms_2'] ?? '2. Store in cool and dry place.';
    final String term3 = shopSettings?['terms_3'] ?? '';

    final primaryGreen = PdfColor.fromHex('#166534');
    final secondaryGreen = PdfColor.fromHex('#4ade80'); // For A5

    // Calculate rounded total
    double roundedTotal = grandTotal.roundToDouble();
    double roundOff = roundedTotal - grandTotal;

    if (format == 'Thermal') {
      return PdfThermalGenerator.generateThermalBill(
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        roundedTotal: roundedTotal,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerGstNo: customerGstNo,
        shopName: shopName,
        address: address,
        phone: phone,
        shopGstNo: shopGstNo,
        cinNumber: cinNumber,
        drugLicence: drugLicence,
        upiId: upiId,
        logoImage: logoImage,
        qrImage: qrImage,
        billingDate: billingDate,
        theme: theme,
      );
    } else if (format == 'A5') {
      return PdfA5Generator.generateA5Bill(
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        roundedTotal: roundedTotal,
        roundOff: roundOff,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerLocation: customerLocation,
        paymentMethod: paymentMethod,
        doctorName: doctorName,
        customerGstNo: customerGstNo,
        shopName: shopName,
        tagline: tagline,
        address: address,
        phone: phone,
        email: email,
        shopGstNo: shopGstNo,
        cinNumber: cinNumber,
        drugLicence: drugLicence,
        bankName: bankName,
        branchName: branchName,
        acHolder: acHolder,
        acNumber: acNumber,
        ifsc: ifsc,
        upiId: upiId,
        term1: term1,
        term2: term2,
        term3: term3,
        logoImage: logoImage,
        qrImage: qrImage,
        billingDate: billingDate,
        primaryGreen: primaryGreen,
        secondaryGreen: secondaryGreen,
        theme: theme,
      );
    } else {
      return PdfA4Generator.generateA4Bill(
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        roundedTotal: roundedTotal,
        roundOff: roundOff,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerLocation: customerLocation,
        paymentMethod: paymentMethod,
        doctorName: doctorName,
        customerGstNo: customerGstNo,
        shopName: shopName,
        tagline: tagline,
        address: address,
        phone: phone,
        landline: landline,
        email: email,
        shopGstNo: shopGstNo,
        cinNumber: cinNumber,
        drugLicence: drugLicence,
        bankName: bankName,
        branchName: branchName,
        acHolder: acHolder,
        acNumber: acNumber,
        ifsc: ifsc,
        upiId: upiId,
        term1: term1,
        term2: term2,
        term3: term3,
        logoImage: logoImage,
        qrImage: qrImage,
        billingDate: billingDate,
        primaryGreen: primaryGreen,
        theme: theme,
      );
    }
  }
}
