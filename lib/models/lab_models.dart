class LabTest {
  final String id;
  final String name;
  final String testCode;
  final String description;
  String category;
  final double price;
  final String templateId;
  final String sampleType;
  final String reportingTime;
  final bool isActive;

  LabTest({
    required this.id,
    required this.name,
    this.testCode = '',
    required this.description,
    required this.category,
    required this.price,
    required this.templateId,
    this.sampleType = 'Blood',
    this.reportingTime = '24 hours',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    // 'id': id,
    'type': 'SINGLE_TEST',
    'title': name,
    'test_code': testCode,
    'description': description,
    'category': category,
    'price': price,
    'template_id': templateId,
    'sample_type': sampleType,
    'turnaround_time': reportingTime,
    'is_active': isActive,
  };

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'],
    name: json['title'] ?? '',
    testCode: json['test_code'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? 'General',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    templateId: json['template_id'] ?? '',
    sampleType: json['sample_type'] ?? 'Blood',
    reportingTime: json['turnaround_time'] ?? '24 hours',
    isActive: json['is_active'] ?? true,
  );
}

class TemplateField {
  final String name;
  final String shortCode;
  final String unit;
  final String normalRange;
  final String resultType;
  final int decimals;

  TemplateField({
    required this.name,
    this.shortCode = '',
    required this.unit,
    required this.normalRange,
    this.resultType = 'Numeric',
    this.decimals = 1,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'shortCode': shortCode,
    'unit': unit,
    'normalRange': normalRange,
    'resultType': resultType,
    'decimals': decimals,
  };

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
    name: json['name'],
    shortCode: json['shortCode'] ?? '',
    unit: json['unit'],
    normalRange: json['normalRange'],
    resultType: json['resultType'] ?? 'Numeric',
    decimals: json['decimals'] ?? 1,
  );
}

class DoctorSignature {
  final String doctorName;
  final String qualifications;
  final String designation;
  final String signatureImageUrl;

  DoctorSignature({
    required this.doctorName,
    required this.qualifications,
    required this.designation,
    this.signatureImageUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'doctorName': doctorName,
    'qualifications': qualifications,
    'designation': designation,
    'signatureImageUrl': signatureImageUrl,
  };

  factory DoctorSignature.fromJson(Map<String, dynamic> json) =>
      DoctorSignature(
        doctorName: json['doctorName'] ?? '',
        qualifications: json['qualifications'] ?? '',
        designation: json['designation'] ?? '',
        signatureImageUrl: json['signatureImageUrl'] ?? '',
      );
}

class ReportLayoutConfig {
  String clinicName;
  String clinicAddress;
  String clinicPhone;
  String clinicEmail;
  String headerLogoUrl;
  List<DoctorSignature> signatures;
  String qrCodeUrl;
  String playStoreUrl;
  String footerBannerUrl;
  String footerColorHex;

  ReportLayoutConfig({
    this.clinicName = 'SirfBill Bill Karo, Befikar Raho',
    this.clinicAddress = '123, Main Road, Kolkata - 700001',
    this.clinicPhone = '+91 98765 43210',
    this.clinicEmail = 'lab@manjumedical.com',
    this.headerLogoUrl = '',
    this.signatures = const [],
    this.qrCodeUrl = '',
    this.playStoreUrl = '',
    this.footerBannerUrl = '',
    this.footerColorHex = '#EA580C',
  });

  Map<String, dynamic> toJson() => {
    'clinicName': clinicName,
    'clinicAddress': clinicAddress,
    'clinicPhone': clinicPhone,
    'clinicEmail': clinicEmail,
    'headerLogoUrl': headerLogoUrl,
    'signatures': signatures.map((x) => x.toJson()).toList(),
    'qrCodeUrl': qrCodeUrl,
    'playStoreUrl': playStoreUrl,
    'footerBannerUrl': footerBannerUrl,
    'footerColorHex': footerColorHex,
  };

  factory ReportLayoutConfig.fromJson(Map<String, dynamic> json) =>
      ReportLayoutConfig(
        clinicName: json['clinicName'] ?? 'SirfBill Bill Karo, Befikar Raho',
        clinicAddress:
            json['clinicAddress'] ?? '123, Main Road, Kolkata - 700001',
        clinicPhone: json['clinicPhone'] ?? '+91 98765 43210',
        clinicEmail: json['clinicEmail'] ?? 'lab@manjumedical.com',
        headerLogoUrl: json['headerLogoUrl'] ?? '',
        signatures: json['signatures'] != null
            ? List<DoctorSignature>.from(
                json['signatures'].map((x) => DoctorSignature.fromJson(x)),
              )
            : [],
        qrCodeUrl: json['qrCodeUrl'] ?? '',
        playStoreUrl: json['playStoreUrl'] ?? '',
        footerBannerUrl: json['footerBannerUrl'] ?? '',
        footerColorHex: json['footerColorHex'] ?? '#EA580C',
      );

  ReportLayoutConfig copyWith({
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    String? clinicEmail,
    String? headerLogoUrl,
    List<DoctorSignature>? signatures,
    String? qrCodeUrl,
    String? playStoreUrl,
    String? footerBannerUrl,
    String? footerColorHex,
  }) {
    return ReportLayoutConfig(
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      clinicEmail: clinicEmail ?? this.clinicEmail,
      headerLogoUrl: headerLogoUrl ?? this.headerLogoUrl,
      signatures: signatures ?? this.signatures,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      footerBannerUrl: footerBannerUrl ?? this.footerBannerUrl,
      footerColorHex: footerColorHex ?? this.footerColorHex,
    );
  }
}

class LabTemplate {
  final String id;
  final String name;
  final String testName;
  final String category;
  final String type;
  final String reportFormat;
  final bool isActive;
  final String description;
  final bool showPatientDetails;
  final bool showReferrals;
  final bool showLabLogo;
  final bool showRemarksSection;
  final String defaultRemarks;
  final List<TemplateField> fields;
  final ReportLayoutConfig layoutConfig;

  LabTemplate({
    required this.id,
    required this.name,
    this.testName = '',
    this.category = 'General',
    this.type = 'Tabular',
    this.reportFormat = 'A4 Portrait',
    this.isActive = true,
    this.description = '',
    this.showPatientDetails = true,
    this.showReferrals = true,
    this.showLabLogo = true,
    this.showRemarksSection = true,
    this.defaultRemarks = '',
    this.fields = const [],
    ReportLayoutConfig? layoutConfig,
  }) : layoutConfig = layoutConfig ?? ReportLayoutConfig();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'testName': testName,
    'category': category,
    'type': type,
    'reportFormat': reportFormat,
    'isActive': isActive,
    'description': description,
    'showPatientDetails': showPatientDetails,
    'showReferrals': showReferrals,
    'showLabLogo': showLabLogo,
    'showRemarksSection': showRemarksSection,
    'defaultRemarks': defaultRemarks,
    'fields': fields.map((e) => e.toJson()).toList(),
    'layoutConfig': layoutConfig.toJson(),
  };

  factory LabTemplate.fromJson(Map<String, dynamic> json) => LabTemplate(
    id: json['id'],
    name: json['name'],
    testName: json['testName'] ?? '',
    category: json['category'] ?? 'General',
    type: json['type'] ?? 'Tabular',
    reportFormat: json['reportFormat'] ?? 'A4 Portrait',
    isActive: json['isActive'] ?? true,
    description: json['description'] ?? '',
    showPatientDetails: json['showPatientDetails'] ?? true,
    showReferrals: json['showReferrals'] ?? true,
    showLabLogo: json['showLabLogo'] ?? true,
    showRemarksSection: json['showRemarksSection'] ?? false,
    defaultRemarks: json['defaultRemarks'] ?? '',
    fields: (json['fields'] as List)
        .map((e) => TemplateField.fromJson(e))
        .toList(),
    layoutConfig: json['layoutConfig'] != null
        ? ReportLayoutConfig.fromJson(json['layoutConfig'])
        : null,
  );

  LabTemplate copyWith({
    String? id,
    String? name,
    String? testName,
    String? category,
    String? type,
    String? reportFormat,
    bool? isActive,
    String? description,
    bool? showPatientDetails,
    bool? showReferrals,
    bool? showLabLogo,
    bool? showRemarksSection,
    String? defaultRemarks,
    List<TemplateField>? fields,
    ReportLayoutConfig? layoutConfig,
  }) {
    return LabTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      testName: testName ?? this.testName,
      category: category ?? this.category,
      type: type ?? this.type,
      reportFormat: reportFormat ?? this.reportFormat,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      showPatientDetails: showPatientDetails ?? this.showPatientDetails,
      showReferrals: showReferrals ?? this.showReferrals,
      showLabLogo: showLabLogo ?? this.showLabLogo,
      showRemarksSection: showRemarksSection ?? this.showRemarksSection,
      defaultRemarks: defaultRemarks ?? this.defaultRemarks,
      fields: fields ?? this.fields,
      layoutConfig: layoutConfig ?? this.layoutConfig,
    );
  }
}

class LabPackage {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> testIds;
  final double discountedPrice;
  final bool isActive;

  LabPackage({
    required this.id,
    required this.name,
    this.category = 'Wellness',
    required this.description,
    required this.testIds,
    required this.discountedPrice,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    // 'id': id,
    'type': 'PACKAGE',
    'title': name,
    'category': category,
    'description': description,
    'includes': testIds,
    'price': discountedPrice,
    'is_active': isActive,
  };

  factory LabPackage.fromJson(Map<String, dynamic> json) => LabPackage(
    id: json['id'],
    name: json['title'] ?? '',
    category: json['category'] ?? 'Wellness',
    description: json['description'] ?? '',
    testIds: json['includes'] != null
        ? List<String>.from(json['includes'])
        : [],
    discountedPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
    isActive: json['is_active'] ?? true,
  );
}

class LabBooking {
  final String id;
  final String sampleId;
  final String patientName;
  final String patientPhone;
  final String patientAge;
  final String patientGender;
  final DateTime bookingDate; // Maps to Collection Date
  final List<String> testIds; // IDs of LabTest
  final List<String> packageIds; // IDs of LabPackage
  final String testsDescription;
  final String sampleType;
  final String collectedBy;
  final String assignedTo;
  final DateTime? expectedReportDate;
  final double totalAmount;
  final String status; // Pending, Collected, In Processing, Ready, Delivered

  LabBooking({
    required this.id,
    this.sampleId = '',
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientGender,
    required this.bookingDate,
    required this.testIds,
    required this.packageIds,
    this.testsDescription = '',
    this.sampleType = 'Blood',
    this.collectedBy = '',
    this.assignedTo = '',
    this.expectedReportDate,
    required this.totalAmount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sampleId': sampleId,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'patientAge': patientAge,
    'patientGender': patientGender,
    'bookingDate': bookingDate.toIso8601String(),
    'testIds': testIds,
    'packageIds': packageIds,
    'testsDescription': testsDescription,
    'sampleType': sampleType,
    'collectedBy': collectedBy,
    'assignedTo': assignedTo,
    'expectedReportDate': expectedReportDate?.toIso8601String(),
    'totalAmount': totalAmount,
    'status': status,
  };

  factory LabBooking.fromJson(Map<String, dynamic> json) => LabBooking(
    id: json['id'],
    sampleId: json['sampleId'] ?? '',
    patientName: json['patientName'],
    patientPhone: json['patientPhone'],
    patientAge: json['patientAge'],
    patientGender: json['patientGender'],
    bookingDate: DateTime.parse(json['bookingDate']),
    testIds: List<String>.from(json['testIds']),
    packageIds: List<String>.from(json['packageIds']),
    testsDescription: json['testsDescription'] ?? '',
    sampleType: json['sampleType'] ?? 'Blood',
    collectedBy: json['collectedBy'] ?? '',
    assignedTo: json['assignedTo'] ?? '',
    expectedReportDate: json['expectedReportDate'] != null
        ? DateTime.parse(json['expectedReportDate'])
        : null,
    totalAmount: json['totalAmount'].toDouble(),
    status: json['status'],
  );
}

class LabReport {
  final String id;
  final String reportId;
  final String patientName;
  final String patientPhone;
  final String patientAge;
  final String patientGender;
  final String referredBy;
  final String testsPackageName;
  final DateTime reportDate;
  final String status; // Pending, In Processing, Ready, Delivered
  final bool isSent;
  final String sampleId;
  final String sampleType;
  final DateTime collectionDate;

  LabReport({
    required this.id,
    required this.reportId,
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientGender,
    this.referredBy = '',
    required this.testsPackageName,
    required this.reportDate,
    required this.status,
    this.isSent = false,
    required this.sampleId,
    this.sampleType = 'Whole Blood',
    required this.collectionDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportId': reportId,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'patientAge': patientAge,
    'patientGender': patientGender,
    'referredBy': referredBy,
    'testsPackageName': testsPackageName,
    'reportDate': reportDate.toIso8601String(),
    'status': status,
    'isSent': isSent,
    'sampleId': sampleId,
    'sampleType': sampleType,
    'collectionDate': collectionDate.toIso8601String(),
  };

  factory LabReport.fromJson(Map<String, dynamic> json) => LabReport(
    id: json['id'],
    reportId: json['reportId'] ?? '',
    patientName: json['patientName'],
    patientPhone: json['patientPhone'] ?? '',
    patientAge: json['patientAge'] ?? '',
    patientGender: json['patientGender'] ?? '',
    referredBy: json['referredBy'] ?? '',
    testsPackageName: json['testsPackageName'] ?? '',
    reportDate: DateTime.parse(json['reportDate']),
    status: json['status'],
    isSent: json['isSent'] ?? false,
    sampleId: json['sampleId'] ?? '',
    sampleType: json['sampleType'] ?? 'Whole Blood',
    collectionDate: json['collectionDate'] != null
        ? DateTime.parse(json['collectionDate'])
        : DateTime.now(),
  );
}

class LabActivity {
  final String id;
  final DateTime dateTime;
  final String type;
  final String description;
  final String referenceId;
  final String performedBy;
  final String? patientName;
  final String? patientPhone;
  final String? message;

  LabActivity({
    required this.id,
    required this.dateTime,
    required this.type,
    required this.description,
    required this.referenceId,
    required this.performedBy,
    this.patientName,
    this.patientPhone,
    this.message,
  });
}
