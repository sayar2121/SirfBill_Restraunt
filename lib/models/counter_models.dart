class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final bool isActive;
  final String? createdAt;
  final String? tenantId;

  Customer({
    required this.id,
    this.tenantId,
    required this.name,
    required this.phone,
    this.email = '',
    this.location = '',
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'is_active': isActive,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      location: json['location'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }
}

class SavedBill {
  final String id;
  final String invoiceNo;
  final String customerName;
  final String customerPhone;
  final String customerLocation;
  final String customerGstin;
  final String doctorName;
  final String paymentMode;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;
  final String format;
  final String? tenantId;

  SavedBill({
    required this.id,
    this.tenantId,
    required this.invoiceNo,
    required this.customerName,
    required this.customerPhone,
    this.customerLocation = '',
    this.customerGstin = '',
    required this.doctorName,
    this.paymentMode = 'CASH',
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.items,
    required this.createdAt,
    this.format = 'A4',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'invoiceNo': invoiceNo,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerLocation': customerLocation,
    'customerGstin': customerGstin,
    'doctorName': doctorName,
    'paymentMode': paymentMode,
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'grandTotal': grandTotal,
    'items': items,
    'createdAt': createdAt.toIso8601String(),
    'format': format,
  };

  factory SavedBill.fromJson(Map<String, dynamic> json) => SavedBill(
    id: json['id'],
    tenantId: json['tenant_id'],
    invoiceNo: json['invoiceNo'],
    customerName: json['customerName'],
    customerPhone: json['customerPhone'] ?? '',
    customerLocation: json['customerLocation'] ?? '',
    customerGstin: json['customerGstin'] ?? '',
    doctorName: json['doctorName'] ?? '',
    paymentMode: json['paymentMode'] ?? 'CASH',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    items: List<Map<String, dynamic>>.from(json['items'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    format: json['format'] ?? 'A4',
  );
}
