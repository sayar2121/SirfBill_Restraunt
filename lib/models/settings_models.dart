class ShopSettings {
  final String shopName;
  final String tagline;
  final String address;
  final String phone;
  final String landline;
  final String email;
  final String gstNumber;
  final String bankName;
  final String branchName;
  final String acHolderName;
  final String acNumber;
  final String ifscCode;
  final String upiId;
  final String terms1;
  final String terms2;
  final String terms3;
  final String cinNumber;
  String get drugLicence => cinNumber;
  final String? tenantId;

  ShopSettings({
    required this.shopName,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.landline,
    required this.email,
    required this.gstNumber,
    required this.bankName,
    required this.branchName,
    required this.acHolderName,
    required this.acNumber,
    required this.ifscCode,
    this.upiId = '',
    required this.terms1,
    required this.terms2,
    required this.terms3,
    String? cinNumber,
    String? drugLicence,
    this.tenantId,
  }) : cinNumber = cinNumber ?? drugLicence ?? '';

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shop_name'] ?? '',
      tagline: map['tagline'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      landline: map['landline'] ?? '',
      email: map['email'] ?? '',
      gstNumber: map['gst_number'] ?? '',
      bankName: map['bank_name'] ?? '',
      branchName: map['branch_name'] ?? '',
      acHolderName: map['ac_holder_name'] ?? '',
      acNumber: map['ac_number'] ?? '',
      ifscCode: map['ifsc_code'] ?? '',
      upiId: map['upi_id'] ?? '',
      terms1: map['terms_1'] ?? '',
      terms2: map['terms_2'] ?? '',
      terms3: map['terms_3'] ?? '',
      cinNumber: map['cin_number'] ?? map['drug_licence'] ?? '',
      tenantId: map['tenant_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_name': shopName,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'landline': landline,
      'email': email,
      'gst_number': gstNumber,
      'bank_name': bankName,
      'branch_name': branchName,
      'ac_holder_name': acHolderName,
      'ac_number': acNumber,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'terms_1': terms1,
      'terms_2': terms2,
      'terms_3': terms3,
      'cin_number': cinNumber,
      'drug_licence': cinNumber,
      'tenant_id': tenantId,
    };
  }
}

class BillItem {
  final String id;
  final String name;
  final String brand;
  final int qty;
  final double price;
  final double mrp;
  final double total;
  final String batch;
  final String expiry;
  final String hsn;
  final double cgst;
  final double sgst;
  final int stock;
  final String? tenantId;

  BillItem({
    required this.id,
    required this.name,
    this.brand = '',
    required this.qty,
    required this.price,
    required this.mrp,
    required this.total,
    this.batch = '-',
    this.expiry = '-',
    this.hsn = '-',
    this.cgst = 0,
    this.sgst = 0,
    this.stock = 0,
    this.tenantId,
  });

  BillItem copyWith({
    String? id,
    String? name,
    String? brand,
    int? qty,
    double? price,
    double? mrp,
    double? total,
    String? batch,
    String? expiry,
    String? hsn,
    double? cgst,
    double? sgst,
    int? stock,
    String? tenantId,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      total: total ?? this.total,
      batch: batch ?? this.batch,
      expiry: expiry ?? this.expiry,
      hsn: hsn ?? this.hsn,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      stock: stock ?? this.stock,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] ?? map['inventory_item_id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      qty: map['qty'] ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      batch: map['batch'] ?? '-',
      expiry: map['expiry'] ?? '-',
      hsn: map['hsn'] ?? '-',
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] ?? 0,
      tenantId: map['tenant_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventory_item_id': id,
      'name': name,
      'brand': brand,
      'qty': qty,
      'price': price,
      'mrp': mrp,
      'total': total,
      'batch': batch,
      'expiry': expiry,
      'hsn': hsn,
      'cgst': cgst,
      'sgst': sgst,
      'stock': stock,
      'tenant_id': tenantId,
    };
  }
}
