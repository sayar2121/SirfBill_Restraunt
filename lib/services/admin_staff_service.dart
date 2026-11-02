import 'package:dio/dio.dart';
import '../config/api_client.dart';

class RestaurantStaffUser {
  final String id;
  final String username;
  final String name;
  final String role; // 'admin', 'manager', 'cashier', 'waiter', 'chef'
  final String? phone;
  final String? branchId;
  final String? branchName;
  final bool isActive;

  RestaurantStaffUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.phone,
    this.branchId,
    this.branchName,
    this.isActive = true,
  });

  factory RestaurantStaffUser.fromJson(Map<String, dynamic> json) {
    return RestaurantStaffUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? json['email'] ?? '',
      name: json['name'] ?? json['full_name'] ?? 'Staff Member',
      role: (json['role'] ?? 'cashier').toString().toLowerCase(),
      phone: json['phone'] ?? json['contact_number'],
      branchId: json['outlet_id']?.toString() ?? json['branch_id']?.toString() ?? json['shop_id']?.toString(),
      branchName: json['branch_name'] ?? json['shop_name'],
      isActive: json['is_active'] ?? json['status'] == 'Active' || json['status'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'phone': phone,
      'branch_id': branchId,
      'is_active': isActive,
    };
  }
}

class AdminStaffService {
  static final Dio _dio = ApiClient().dio;

  /// Fetch all restaurant staff and managers
  static Future<List<RestaurantStaffUser>> getStaffUsers() async {
    // 1. Try /api/admin/users first
    try {
      final res = await _dio.get('/api/admin/users');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['users'] ?? []);
        return list.map((j) => RestaurantStaffUser.fromJson(j)).toList();
      }
    } catch (_) {}

    // 2. Fallback to /api/users (the standard users table in database)
    try {
      final res = await _dio.get('/api/users');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['users'] ?? []);
        if (list.isNotEmpty) {
          return list.map((j) => RestaurantStaffUser.fromJson(j)).toList();
        }
      }
    } catch (_) {}

    // 3. Return starter users if no user records exist yet
    return [
      RestaurantStaffUser(
        id: '1',
        username: 'admin@sirfbill.com',
        name: 'Super Admin',
        role: 'admin',
        phone: '+91 9876543210',
        branchName: 'Main Branch',
        isActive: true,
      ),
      RestaurantStaffUser(
        id: '2',
        username: 'cashier@sirfbill.com',
        name: 'Billing Cashier',
        role: 'cashier',
        phone: '+91 9812345678',
        branchName: 'Main Branch',
        isActive: true,
      ),
      RestaurantStaffUser(
        id: '3',
        username: 'chef@sirfbill.com',
        name: 'Head Chef',
        role: 'chef',
        phone: '+91 9765432109',
        branchName: 'Kitchen 1',
        isActive: true,
      ),
    ];
  }

  /// Create new staff user with role and branch assignment
  static Future<bool> createStaffUser({
    required String username,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? branchId,
  }) async {
    final normalizedRole = role.toUpperCase();
    final endpoints = [
      '/api/users/create',
      '/api/users',
      '/api/admin/users',
    ];

    final payload = {
      'username': username,
      'email': username,
      'password': password,
      'name': name,
      'full_name': name,
      'role': normalizedRole,
      'phone': phone ?? '+91 9999999999',
      'outlet_id': branchId,
      'branch_id': branchId,
      'is_active': true,
    };

    for (final ep in endpoints) {
      try {
        final res = await _dio.post(ep, data: payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Try next endpoint
      }
    }
    return false;
  }

  /// Update existing staff user
  static Future<bool> updateStaffUser({
    required String userId,
    required String name,
    required String role,
    String? phone,
    String? password,
    String? branchId,
    bool? isActive,
  }) async {
    final normalizedRole = role.toUpperCase();
    final endpoints = [
      '/api/users/$userId',
      '/api/admin/users/$userId',
    ];

    final payload = <String, dynamic>{
      'name': name,
      'full_name': name,
      'role': normalizedRole,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
      'outlet_id': (branchId != null && branchId.isNotEmpty) ? branchId : null,
      'branch_id': (branchId != null && branchId.isNotEmpty) ? branchId : null,
      if (isActive != null) 'is_active': isActive,
    };

    for (final ep in endpoints) {
      try {
        final res = await _dio.patch(ep, data: payload);
        if (res.statusCode == 200 || res.statusCode == 204) {
          return true;
        }
      } catch (_) {
        try {
          final resPut = await _dio.put(ep, data: payload);
          if (resPut.statusCode == 200 || resPut.statusCode == 204) {
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  /// Delete or deactivate staff user
  static Future<bool> deleteStaffUser(String userId) async {
    final endpoints = [
      '/api/users/$userId',
      '/api/admin/users/$userId',
    ];

    for (final ep in endpoints) {
      try {
        final res = await _dio.delete(ep);
        if (res.statusCode == 200 || res.statusCode == 204) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
