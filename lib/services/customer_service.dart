import 'package:dio/dio.dart';
import '../config/api_client.dart';
import '../models/counter_models.dart';
import 'inventory_service.dart';
export '../models/counter_models.dart';

class CustomerService {
  /// Save customer to restaurant_customers table via /api/restaurant/crm/customers
  /// Also mirrors to /api/users/create so both systems stay perfectly synchronized.
  static Future<Customer> saveCustomer(Customer customer) async {
    try {
      final shopId = await InventoryService.getShopId();

      // 1. Save directly into restaurant_customers table
      try {
        final restaurantCrmRes = await ApiClient().dio.post(
          '/api/restaurant/crm/customers',
          data: {
            'outlet_id': shopId,
            'name': customer.name,
            'phone': customer.phone,
            'email': customer.email.isNotEmpty ? customer.email : null,
            'notes': customer.location.isNotEmpty ? customer.location : null,
            'is_active': customer.isActive,
          },
        );

        if (restaurantCrmRes.statusCode == 200 || restaurantCrmRes.statusCode == 201) {
          final data = restaurantCrmRes.data;
          // Synchronize to users table in background
          _syncToUsersTable(customer, shopId);

          return Customer(
            id: data['id']?.toString() ?? customer.id,
            tenantId: data['outlet_id']?.toString() ?? shopId,
            name: data['name']?.toString() ?? customer.name,
            phone: data['phone']?.toString() ?? customer.phone,
            email: data['email']?.toString() ?? customer.email,
            location: (data['notes'] ?? customer.location).toString(),
            isActive: data['is_active'] ?? true,
            createdAt: data['created_at']?.toString() ?? customer.createdAt,
          );
        }
      } catch (crmError) {
        // Fall back to users table if crm endpoint has an issue
      }

      // 2. Fallback to /api/users/create
      final response = await ApiClient().dio.post(
        '/api/users/create',
        data: {
          'tenant_id': shopId,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email.isNotEmpty ? customer.email : null,
          'location': customer.location.isNotEmpty ? customer.location : null,
          'is_active': customer.isActive,
          'role': 'USER',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Customer.fromJson(response.data);
      } else {
        throw Exception('Failed to save customer');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          throw Exception(data['detail']);
        }
      }
      throw Exception('Failed to save customer: ${e.message}');
    }
  }

  static Future<void> _syncToUsersTable(Customer customer, String shopId) async {
    try {
      await ApiClient().dio.post(
        '/api/users/create',
        data: {
          'tenant_id': shopId,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email.isNotEmpty ? customer.email : null,
          'location': customer.location.isNotEmpty ? customer.location : null,
          'is_active': customer.isActive,
          'role': 'USER',
        },
      );
    } catch (_) {}
  }

  static Future<void> updateCustomer(Customer customer) async {
    final shopId = await InventoryService.getShopId();

    // 1. Try updating restaurant_customers CRM profile first
    try {
      final crmRes = await ApiClient().dio.patch(
        '/api/restaurant/crm/customers/${customer.id}',
        data: {
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email.isNotEmpty ? customer.email : null,
          'notes': customer.location.isNotEmpty ? customer.location : null,
          'is_active': customer.isActive,
        },
      );
      if (crmRes.statusCode == 200) {
        // Also update users table mirror if possible
        _syncUpdateToUsersTable(customer, shopId);
        return;
      }
    } catch (_) {}

    // 2. Fallback to /api/users table
    final response = await ApiClient().dio.patch(
      '/api/users/${customer.id}',
      data: {
        'tenant_id': shopId,
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email.isNotEmpty ? customer.email : null,
        'location': customer.location.isNotEmpty ? customer.location : null,
        'is_active': customer.isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update customer');
    }
  }

  static Future<void> _syncUpdateToUsersTable(Customer customer, String shopId) async {
    try {
      await ApiClient().dio.patch(
        '/api/users/${customer.id}',
        data: {
          'tenant_id': shopId,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email.isNotEmpty ? customer.email : null,
          'location': customer.location.isNotEmpty ? customer.location : null,
          'is_active': customer.isActive,
        },
      );
    } catch (_) {}
  }

  /// Fetches customers from restaurant_customers table (/api/restaurant/crm/customers)
  /// and merges with users table (/api/users?role=USER)
  /// Staff accounts (CASHIER, MANAGER, ADMIN, OWNER, WAITER, KITCHEN) are strictly excluded.
  static Future<List<Customer>> getCustomers() async {
    final shopId = await InventoryService.getShopId();
    final Map<String, Customer> customersByPhone = {};

    // 1. Fetch from restaurant_customers
    try {
      final res = await ApiClient().dio.get(
        '/api/restaurant/crm/customers',
        queryParameters: {'outlet_id': shopId, 'limit': 100},
      );
      if (res.statusCode == 200 && res.data is List) {
        for (final item in res.data) {
          final phone = (item['phone'] ?? '').toString().trim();
          final id = (item['id'] ?? '').toString();
          final cust = Customer(
            id: id,
            tenantId: item['outlet_id']?.toString() ?? shopId,
            name: item['name']?.toString() ?? '',
            phone: phone,
            email: item['email']?.toString() ?? '',
            location: (item['notes'] ?? '').toString(),
            isActive: item['is_active'] ?? true,
            createdAt: item['created_at']?.toString(),
          );
          if (phone.isNotEmpty) {
            customersByPhone[phone] = cust;
          } else {
            customersByPhone[id] = cust;
          }
        }
      }
    } catch (_) {
      // Continue to users table
    }

    // 2. Fetch from users table to include any retail/web users who are customers
    // Strictly filter by role: 'USER' to prevent staff accounts from showing up
    try {
      final response = await ApiClient().dio.get(
        '/api/users',
        queryParameters: {
          if (shopId.isNotEmpty) 'tenant_id': shopId,
          'role': 'USER',
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        for (final json in response.data) {
          final role = (json['role'] ?? '').toString().toUpperCase();
          // Explicit safeguard: Exclude staff members
          if (role.isNotEmpty && role != 'USER' && role != 'CUSTOMER') {
            continue;
          }

          final cust = Customer.fromJson(json);
          final phone = cust.phone.trim();
          if (phone.isNotEmpty) {
            if (!customersByPhone.containsKey(phone)) {
              customersByPhone[phone] = cust;
            }
          } else if (!customersByPhone.containsKey(cust.id)) {
            customersByPhone[cust.id] = cust;
          }
        }
      }
    } catch (_) {}

    return customersByPhone.values.toList();
  }

  static Future<void> deleteCustomer(String customerId) async {
    try {
      // 1. Try deleting from restaurant_customers table
      try {
        final crmRes = await ApiClient().dio.delete('/api/restaurant/crm/customers/$customerId');
        if (crmRes.statusCode == 200 || crmRes.statusCode == 204) {
          return;
        }
      } catch (_) {}

      // 2. If deleting from users table, verify role is NOT staff before deleting
      try {
        final userRes = await ApiClient().dio.get('/api/users/$customerId');
        if (userRes.statusCode == 200 && userRes.data is Map) {
          final role = (userRes.data['role'] ?? '').toString().toUpperCase();
          if (role.isNotEmpty && role != 'USER' && role != 'CUSTOMER') {
            throw Exception('Cannot delete a staff account from customer management.');
          }
        }
      } catch (e) {
        if (e.toString().contains('Cannot delete a staff account')) rethrow;
      }

      final response = await ApiClient().dio.delete('/api/users/$customerId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete customer');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          throw Exception(data['detail']);
        }
      }
      throw Exception('Failed to delete customer: ${e.message}');
    }
  }
}
