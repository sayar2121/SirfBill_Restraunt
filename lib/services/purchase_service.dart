import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_client.dart';
import 'inventory_service.dart';

class PurchaseService {
  final ApiClient _apiClient = ApiClient();

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data['detail'] != null) return data['detail'].toString();
          if (data['message'] != null) return data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          return data;
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return error.toString();
  }

  // Create a purchase bill
  Future<Map<String, dynamic>> createPurchaseBill(Map<String, dynamic> data) async {
    try {
      final shopId = await InventoryService.getShopId();
      data['tenant_id'] = shopId;
      final response = await _apiClient.dio.post(
        '/api/admin/purchases/',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create purchase bill: ${response.statusCode} - ${response.data}');
    } catch (e) {
      final msg = _extractErrorMessage(e);
      if (kDebugMode) {
        print('Error creating purchase bill: $msg');
      }
      throw Exception(msg);
    }
  }

  // Fetch purchase bills
  Future<List<dynamic>> getPurchaseBills() async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await _apiClient.dio.get(
        '/api/admin/purchases/',
        queryParameters: {'shop_id': shopId, 'tenant_id': shopId},
      );
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching purchase bills: $e');
      }
      return [];
    }
  }

  // Mark a purchase bill as PAID
  Future<Map<String, dynamic>> markBillAsPaid(
    String billId, {
    String? accountId,
    String? paymentMethod,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (accountId != null && accountId.isNotEmpty) {
        queryParams['account_id'] = accountId;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        queryParams['payment_method'] = paymentMethod;
      }

      final response = await _apiClient.dio.patch(
        '/api/admin/purchases/$billId/pay',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'status': 'success'};
      }
      throw Exception('Failed to mark bill as paid');
    } catch (e) {
      final msg = _extractErrorMessage(e);
      if (kDebugMode) {
        print('Error paying bill: $msg');
      }
      throw Exception(msg);
    }
  }
}
