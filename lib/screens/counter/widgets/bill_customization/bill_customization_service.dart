import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../config/api_client.dart';
import '../../../../models/settings_models.dart';
import '../../../../services/shop_settings_service.dart';
import '../../../../utils/pdf_generator.dart';

/// Helper service for PDF preview generation and media uploads in Bill Customization.
class BillCustomizationService {
  BillCustomizationService._();

  static Uint8List? cachedDefaultLogo;
  static Uint8List? cachedLogoBytes;
  static String? cachedLogoUrl;
  static Uint8List? cachedQrBytes;
  static String? cachedQrUrl;

  /// Handles media picking (Logo or QR) and backend upload.
  static Future<Map<String, dynamic>?> pickAndUploadImage({
    required BuildContext context,
    required bool isLogo,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        Uint8List? fileBytes = platformFile.bytes;

        if (!kIsWeb && fileBytes == null && platformFile.path != null) {
          final file = File(platformFile.path!);
          if (await file.exists()) {
            fileBytes = await file.readAsBytes();
          }
        }

        if (fileBytes == null || fileBytes.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not read image file data.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading ${isLogo ? "Logo" : "QR Code"}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final filename = platformFile.name;
        String url;
        if (isLogo) {
          url = await ShopSettingsService.uploadLogo(fileBytes, filename);
          cachedLogoBytes = fileBytes;
          cachedLogoUrl = url;
        } else {
          url = await ShopSettingsService.uploadQr(fileBytes, filename);
          cachedQrBytes = fileBytes;
          cachedQrUrl = url;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isLogo ? "Logo" : "QR Code"} uploaded successfully! Remember to click "Save".'),
              backgroundColor: Colors.green,
            ),
          );
        }

        return {'url': url, 'bytes': fileBytes};
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
  }

  /// Generates a dummy sample bill in the selected format for visual inspection.
  static Future<Uint8List?> generatePreviewPdf({
    required String? logoUrl,
    required String? qrUrl,
    required String previewFormat,
    required ShopSettings settings,
  }) async {
    Uint8List? finalLogoBytes;
    Uint8List? finalQrBytes;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (cachedLogoUrl == logoUrl && cachedLogoBytes != null) {
        finalLogoBytes = cachedLogoBytes;
      } else {
        final logoTarget = logoUrl.startsWith('http://') || logoUrl.startsWith('https://')
            ? logoUrl
            : '${logoUrl.startsWith('/') ? '' : '/'}$logoUrl';
        final res = await ApiClient().dio.get(
          logoTarget,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.statusCode == 200) {
          cachedLogoBytes = res.data;
          cachedLogoUrl = logoUrl;
          finalLogoBytes = cachedLogoBytes;
        }
      }
    } else {
      if (cachedDefaultLogo == null) {
        final ByteData bytes = await rootBundle.load('assets/LOGO.png');
        cachedDefaultLogo = bytes.buffer.asUint8List();
      }
      finalLogoBytes = cachedDefaultLogo;
    }

    if (qrUrl != null && qrUrl.isNotEmpty) {
      if (cachedQrUrl == qrUrl && cachedQrBytes != null) {
        finalQrBytes = cachedQrBytes;
      } else {
        final qrTarget = qrUrl.startsWith('http://') || qrUrl.startsWith('https://')
            ? qrUrl
            : '${qrUrl.startsWith('/') ? '' : '/'}$qrUrl';
        final res = await ApiClient().dio.get(
          qrTarget,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.statusCode == 200) {
          cachedQrBytes = res.data;
          cachedQrUrl = qrUrl;
          finalQrBytes = cachedQrBytes;
        }
      }
    }

    final dummyItems = [
      BillItem(
        id: '1',
        name: 'Mutton Biryani (Special)',
        batch: '',
        expiry: '',
        hsn: '9963',
        qty: 2,
        mrp: 320.0,
        price: 320.0,
        cgst: 2.5,
        sgst: 2.5,
        total: 640.0,
      ),
      BillItem(
        id: '2',
        name: 'Butter Chicken Masala',
        batch: '',
        expiry: '',
        hsn: '9963',
        qty: 1,
        mrp: 280.0,
        price: 280.0,
        cgst: 2.5,
        sgst: 2.5,
        total: 280.0,
      ),
      BillItem(
        id: '3',
        name: 'Garlic Butter Naan',
        batch: '',
        expiry: '',
        hsn: '9963',
        qty: 3,
        mrp: 60.0,
        price: 60.0,
        cgst: 2.5,
        sgst: 2.5,
        total: 180.0,
      ),
    ].map((e) => e.toMap()).toList();

    return PdfGenerator.generateBill(
      items: dummyItems,
      subtotal: 1100.0,
      discount: 0.0,
      tax: 55.0,
      grandTotal: 1155.0,
      invoiceNumber: 'PREVIEW-001',
      customerName: 'Sayar Paul',
      customerPhone: '9876543210',
      customerLocation: 'Kolkata',
      doctorName: '',
      format: 'Thermal',
      shopSettings: settings.toMap(),
      logoBytes: finalLogoBytes,
      qrBytes: finalQrBytes,
    );
  }
}
