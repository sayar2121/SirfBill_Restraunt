import 'package:dio/dio.dart';
import '../config/api_client.dart';

class Shop {
  final String id;
  final String name;
  final String code;
  final String location;
  final String city;
  final String contact;
  final String status;
  final bool isPrimary;
  final String? outletType;
  final String? timeZone;
  final String? currency;
  final String? gstin;
  final String? fssai;
  final String? openingTime;
  final String? closingTime;
  final String? invoicePrefix;
  final double? taxRate;
  final String? logoUrl;
  final String? upiId;
  final String? bankName;
  final String? bankAccount;
  final String? bankIfsc;
  final String? bankBranch;
  final String? bankAccountName;
  final Map<String, dynamic>? rawJson;

  Shop({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.city,
    required this.contact,
    required this.status,
    required this.isPrimary,
    this.outletType,
    this.timeZone,
    this.currency,
    this.gstin,
    this.fssai,
    this.openingTime,
    this.closingTime,
    this.invoicePrefix,
    this.taxRate,
    this.logoUrl,
    this.upiId,
    this.bankName,
    this.bankAccount,
    this.bankIfsc,
    this.bankBranch,
    this.bankAccountName,
    this.rawJson,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final extra = (json['extra_data'] is Map<String, dynamic>)
        ? json['extra_data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      code: json['code'] ?? 'N/A',
      location: json['address'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
      contact: json['contact_number'] ?? json['phone'] ?? 'N/A',
      status: json['status'] ?? 'Active',
      isPrimary: json['is_primary'] ?? false,
      outletType: json['outlet_type'],
      timeZone: json['time_zone'],
      currency: json['currency'],
      gstin: json['gstin'] ?? json['gst_number'] ?? extra['gstin'] ?? extra['gst_number'],
      fssai: json['fssai'] ?? json['fssai_no'] ?? json['fssai_number'] ?? extra['fssai'] ?? extra['fssai_no'] ?? extra['fssai_number'],
      openingTime: json['opening_time'] ?? extra['opening_time'],
      closingTime: json['closing_time'] ?? extra['closing_time'],
      invoicePrefix: json['invoice_prefix'],
      taxRate: (json['tax_rate'] is num) ? (json['tax_rate'] as num).toDouble() : null,
      logoUrl: json['logo_url'] ?? json['logo'] ?? extra['logo_url'],
      upiId: json['upi_id'] ?? extra['upi_id'],
      bankName: json['bank_name'] ?? extra['bank_name'],
      bankAccount: json['bank_account_no'] ?? json['bank_account'] ?? extra['bank_account_no'] ?? extra['bank_account'] ?? extra['account_number'],
      bankIfsc: json['bank_ifsc'] ?? extra['bank_ifsc'] ?? extra['ifsc_code'],
      bankBranch: json['bank_branch'] ?? extra['bank_branch'],
      bankAccountName: json['bank_account_name'] ?? extra['bank_account_name'] ?? extra['ac_holder_name'],
      rawJson: json,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'city': city,
      'contact': contact,
      'status': status,
      'isPrimary': isPrimary,
      'outletType': outletType,
      'timeZone': timeZone,
      'currency': currency,
      'gstin': gstin,
      'fssai': fssai,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'invoicePrefix': invoicePrefix,
      'taxRate': taxRate,
    };
  }
}

class ShopService {
  static Future<List<Shop>> getShops() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/shops');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Shop.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shops: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shops: $e');
    }
  }

  static Future<Shop> createShop({
    required String name,
    required String code,
    required String address,
    required String city,
    required String contactNumber,
    required String status,
    required bool isPrimary,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'code': code,
        'address': address,
        'city': city,
        'contact_number': contactNumber,
        'status': status,
        'is_primary': isPrimary,
        if (extraData != null) ...extraData,
      };

      final response = await ApiClient().dio.post(
        '/api/admin/shop',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Shop.fromJson(response.data);
      } else {
        throw Exception('Failed to create shop');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to create shop');
    } catch (e) {
      throw Exception('Error creating shop: $e');
    }
  }

  static Future<Shop> updateShop({
    required String id,
    required String name,
    required String code,
    required String address,
    required String city,
    required String contactNumber,
    required String status,
    required bool isPrimary,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'code': code,
        'address': address,
        'city': city,
        'contact_number': contactNumber,
        'status': status,
        'is_primary': isPrimary,
        if (extraData != null) ...extraData,
      };

      final response = await ApiClient().dio.put(
        '/api/admin/shop/$id',
        data: payload,
      );

      if (response.statusCode == 200) {
        return Shop.fromJson(response.data);
      } else {
        throw Exception('Failed to update shop');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to update shop');
    } catch (e) {
      throw Exception('Error updating shop: $e');
    }
  }

  static Future<void> deleteShop(String id, {String? code, String? name}) async {
    try {
      // 1. Cascade cleanup: delete all staff users & credentials belonging to this outlet
      try {
        final staffList = await ApiClient().dio.get('/api/users');
        if (staffList.statusCode == 200 && staffList.data != null) {
          final List users = staffList.data is List ? staffList.data : (staffList.data['users'] ?? []);
          final cleanCode = code?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase() ?? '';
          final outletName = name?.trim().toLowerCase() ?? '';

          for (final u in users) {
            final uid = u['id']?.toString() ?? '';
            final uTenant = (u['tenant_id'] ?? u['tenantId'] ?? u['shop_id'] ?? '').toString();
            final uEmail = (u['email'] ?? u['username'] ?? '').toString().toLowerCase();
            final uName = (u['name'] ?? u['full_name'] ?? '').toString().toLowerCase();

            final belongsToOutlet = (uTenant.isNotEmpty && uTenant == id) ||
                (cleanCode.isNotEmpty && (uEmail.contains(cleanCode) || uName.contains(cleanCode))) ||
                (outletName.isNotEmpty && uName.contains(outletName));

            if (belongsToOutlet && uid.isNotEmpty) {
              try {
                await ApiClient().dio.delete('/api/users/$uid');
              } catch (_) {}
              try {
                await ApiClient().dio.delete('/api/admin/users/$uid');
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // 2. Cascade cleanup: delete menu items linked to this outlet
      try {
        final menuRes = await ApiClient().dio.get(
          '/api/restaurant/menu/items',
          queryParameters: {'tenant_id': id, 'shop_id': id, 'outlet_id': id},
        );
        if (menuRes.statusCode == 200 && menuRes.data != null) {
          final List items = menuRes.data is List ? menuRes.data : (menuRes.data['items'] ?? []);
          for (final it in items) {
            final itemId = it['id']?.toString() ?? '';
            if (itemId.isNotEmpty) {
              try {
                await ApiClient().dio.delete('/api/restaurant/menu/items/$itemId');
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // 3. Delete outlet record
      // Try singular endpoint (/api/admin/shop/$id)
      try {
        final response = await ApiClient().dio.delete('/api/admin/shop/$id');
        if (response.statusCode == 200 || response.statusCode == 204) return;
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
      }

      // Fallback to plural REST convention (/api/admin/shops/$id)
      final response = await ApiClient().dio.delete('/api/admin/shops/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete shop');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to delete shop');
    } catch (e) {
      throw Exception('Error deleting shop: $e');
    }
  }
}
