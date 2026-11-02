import 'package:dio/dio.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class BillingService {
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? customerGstin,
    String? invoiceNo,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final requestData = {
        'shop_id': shopId,
        'tenant_id': shopId,
        'items': items
            .map(
              (item) {
                final rawInvId = item['inventory_item_id']?.toString();
                final isCustom = rawInvId == null ||
                    rawInvId.startsWith('custom_') ||
                    (item['is_custom'] == true);
                return {
                  'inventory_item_id': isCustom ? null : item['inventory_item_id'],
                  'item_name': item['name'] ?? item['item_name'] ?? 'Custom Item',
                  'unit_price': (item['price'] ?? item['unit_price'] ?? item['mrp'] ?? 0.0).toDouble(),
                  'quantity': item['qty'] ?? item['quantity'] ?? 1,
                  'is_loose': item['is_loose'] ?? false,
                  'discount': (item['discount'] ?? item['disc'] ?? 0.0).toDouble(),
                  'gst': (item['gst'] ?? 0.0).toDouble(),
                };
              },
            )
            .toList(),
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestData['user_id'] = customerId;
      }
      if (customerName != null && customerName.isNotEmpty) {
        requestData['customer_name'] = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestData['customer_phone'] = customerPhone;
      }
      if (customerLocation != null && customerLocation.isNotEmpty) {
        requestData['customer_location'] = customerLocation;
      }
      if (customerGstin != null && customerGstin.isNotEmpty) {
        requestData['customer_gstin'] = customerGstin;
      }
      if (invoiceNo != null && invoiceNo.isNotEmpty) {
        requestData['invoice_no'] = invoiceNo;
      }

      final response = await ApiClient().dio.post(
        '/api/admin/pos/checkout',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Checkout failed: ${response.data}');
      }
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData != null) {
        throw Exception('Validation error: $resData');
      }
      throw Exception('Network error during checkout: ${e.message}');
    } catch (e) {
      throw Exception('Error during checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> getPosHistory() async {
    try {
      final shopId = await InventoryService.getShopId();

      final response = await ApiClient().dio.get(
        '/api/admin/pos/history',
        queryParameters: {
          'shop_id': shopId,
          'tenant_id': shopId,
          'limit': 1000,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch POS history: ${response.data}');
      }
    } catch (e) {
      if (e.toString().contains('No shops found')) {
        return <String, dynamic>{
          'history': <dynamic>[],
          'summary': <String, dynamic>{},
        };
      }
      throw Exception('Error fetching POS history: $e');
    }
  }
}
