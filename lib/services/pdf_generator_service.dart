import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/lab_models.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateReport(
    LabTest test,
    LabTemplate template,
    Map<String, dynamic> patientData,
  ) async {
    final pdf = pw.Document();
    final config = template.layoutConfig;

    // Load the logo image from assets
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/LOGO.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // If logo can't be loaded, logoImage stays null
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // Full page for banners
        build: (context) => [
          _buildRichHeader(config, patientData, logoImage: logoImage),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPatientDetails(patientData),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text(
                    (template.category).toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildTestTable(template),
              ],
            ),
          ),
        ],
        footer: (context) => _buildRichFooter(config),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRichHeader(
    ReportLayoutConfig config,
    Map<String, dynamic> patientData, {
    pw.MemoryImage? logoImage,
  }) {
    return pw.Column(
      children: [
        // Logo and Title Area
        pw.Padding(
          padding: const pw.EdgeInsets.only(
            left: 40,
            right: 40,
            top: 40,
            bottom: 10,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              if (logoImage != null)
                pw.ClipRRect(
                  horizontalRadius: 40,
                  verticalRadius: 40,
                  child: pw.Image(
                    logoImage,
                    width: 80,
                    height: 80,
                    fit: pw.BoxFit.contain,
                  ),
                )
              else
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(40),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'LOGO',
                      style: const pw.TextStyle(color: PdfColors.grey500),
                    ),
                  ),
                ),
              pw.SizedBox(width: 20),
              // Clinic Name
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    config.clinicName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF003B46),
                    ), // Dark teal
                  ),
                  pw.Text(
                    '',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Contact Info Strip
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 40),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildContactItem('Phone', config.clinicPhone),
              _buildContactItem('Email', config.clinicEmail),
              _buildContactItem('Location', config.clinicAddress),
            ],
          ),
        ),
        // Colored Banner
        pw.Container(
          width: double.infinity,
          height: 30,
          color: PdfColor.fromHex(config.footerColorHex),
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40),
          child: pw.Text(
            'QUALITY PRINTS  |  FAST SERVICE  |  YOUR TRUSTED PARTNER',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildContactItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Center(
            child: pw.Text(
              label[0],
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPatientDetails(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.blueAccent, width: 2),
          bottom: pw.BorderSide(color: PdfColors.blueAccent, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _detailRow('Patient Name', data['patientName'] ?? 'John Doe'),
              _detailRow(
                'Age / Gender',
                '${data['age'] ?? '30'} Y / ${data['gender'] ?? 'Male'}',
              ),
              _detailRow('Patient ID', data['patientId'] ?? 'PID-1001'),
              _detailRow('Referred By', data['referredBy'] ?? 'Self'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _detailRow('Sample ID', data['sampleId'] ?? 'SID-9928'),
              _detailRow('Sample Type', data['sampleType'] ?? 'Blood'),
              _detailRow(
                'Collection Date',
                data['collectionDate'] ?? '2026-06-22',
              ),
              _detailRow(
                'Reporting Date',
                data['reportingDate'] ?? '2026-06-22',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ),
          pw.Text(
            ': ',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTestTable(LabTemplate template) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'INVESTIGATION',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'RESULT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'UNIT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'REFERENCE VALUE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        if (template.fields.isEmpty)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  'Plasma Glucose (PP)',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  '113.0',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  'mg/dl',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  '70 - 140 mg/dl',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ...template.fields.map(
          (f) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(f.name, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  '113.0',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ), // Mock result
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(f.unit, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  f.normalRange,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRichFooter(ReportLayoutConfig config) {
    return pw.Column(
      children: [
        // Signatures
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40), // Space for signature image
                  pw.Text(
                    'DR. A. K. DUTTA',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'MD. PGI (Chandigarh)',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Pathologist',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(width: 80),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40), // Space for signature image
                  pw.Text(
                    'DR. ANANDA SAMANTA',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Msc (PGI), PhD (Cal)',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Consultant Clinical Biochemistry',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),

        // App Download / QR Code strip
        pw.Container(
          color: PdfColors.grey100,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: config.playStoreUrl.isNotEmpty
                        ? config.playStoreUrl
                        : 'https://play.google.com/store/apps/details?id=com.manjumedical.app',
                    width: 50,
                    height: 50,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Download Our App',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Scan QR Code',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.black,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'GET IT ON Google Play',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Motivational Text
              pw.Text(
                'Healthy People\nHappier Lives',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ),
        // Colored Bottom Banner
        pw.Container(
          width: double.infinity,
          height: 30,
          color: PdfColor.fromHex(config.footerColorHex),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'B&W PRINTS  |  COLOR PRINTS  |  BANNERS  |  SPIRAL BINDING',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              letterSpacing: 1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
