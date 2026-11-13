import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../models/restaurant_pos_models.dart';
import '../inventory_service.dart';
import 'restaurant_order_parser.dart';

/// Service handling Order dispatch, item updates, status transitions, and live order polling
class RestaurantOrderService {
  static final Dio _dio = ApiClient().dio;

  /// 4. Create Order / Send Items to Kitchen (KOT)
  static Future<Map<String, dynamic>?> sendToKitchen({
    required String orderType,
    String? tableId,
    required List<PosCartItem> cartItems,
    String? customerName,
    String? customerPhone,
    String? orderNotes,
    String? outletId,
    String? paymentMethod,
  }) async {
    try {
      final actualOutletId = (outletId != null && outletId.isNotEmpty)
          ? outletId
          : await InventoryService.getShopId();

      // Format order_type to match Backend enum: DINE_IN, TAKEAWAY, DELIVERY
      String formattedOrderType = 'DINE_IN';
      final upperType = orderType.toUpperCase();
      if (upperType.contains('TAKEAWAY') || upperType.contains('TAKE_AWAY') || upperType.contains('PARCEL')) {
        formattedOrderType = 'TAKEAWAY';
      } else if (upperType.contains('DELIVERY')) {
        formattedOrderType = 'DELIVERY';
      }

      // Validate UUID format
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final validTableId = (tableId != null && uuidRegex.hasMatch(tableId.trim())) ? tableId.trim() : null;

      final payload = {
        'outlet_id': actualOutletId,
        'order_type': formattedOrderType,
        if (validTableId != null && formattedOrderType == 'DINE_IN') 'table_id': validTableId,
        if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
        if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
        if (orderNotes != null && orderNotes.isNotEmpty) 'notes': orderNotes,
        if (paymentMethod != null && paymentMethod.isNotEmpty) 'payment_method': paymentMethod.toUpperCase(),
        'lines': cartItems.map((cartItem) {
          return {
            'item_id': cartItem.item.id,
            'quantity': cartItem.quantity,
            'variant_name': 'Standard',
            if (cartItem.notes != null && cartItem.notes!.isNotEmpty)
              'special_instructions': cartItem.notes,
            'modifiers': [],
          };
        }).toList(),
      };

      debugPrint('POST /api/restaurant/orders payload: $payload');
      final res = await _dio.post('/api/restaurant/orders', data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final orderData = res.data is Map<String, dynamic> ? res.data : <String, dynamic>{};
        final orderId = orderData['id'] ?? orderData['order_id'];
        
        // Trigger kitchen ticket dispatch
        if (orderId != null) {
          try {
            await _dio.post('/api/restaurant/orders/$orderId/send-to-kitchen');
          } catch (e) {
            debugPrint('Info: Kitchen ticket dispatch: $e');
          }
        }
        return orderData;
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error sending order to kitchen [${e.response?.statusCode}]: ${e.response?.data}');
      } else {
        debugPrint('Error sending order to kitchen: $e');
      }
    }
    return null;
  }

  /// Fetch single order details by ID
  static Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final res = await _dio.get('/api/restaurant/orders/$orderId');
      if (res.statusCode == 200 && res.data != null && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('Info: fetchOrderById error for $orderId: $e');
    }
    return null;
  }

  /// 4b. Append / Update Items on an Existing Held Table Order
  static Future<Map<String, dynamic>?> appendItemsToOrder({
    required String orderId,
    required List<PosCartItem> newItems,
    int? expectedVersion = 1,
  }) async {
    try {
      final linesData = newItems.map((cartItem) {
        return {
          'item_id': cartItem.item.id,
          'quantity': cartItem.quantity,
          'variant_name': 'Standard',
          if (cartItem.notes != null && cartItem.notes!.isNotEmpty)
            'special_instructions': cartItem.notes,
          'modifiers': [],
        };
      }).toList();

      int currentVer = expectedVersion ?? 1;

      // Helper function to send the PATCH request
      Future<Response> sendPatch(int ver) {
        final payload = {
          'expected_version': ver,
          'lines': linesData,
          'items': linesData,
        };
        debugPrint('PATCH /api/restaurant/orders/$orderId/items payload: $payload');
        return _dio.patch('/api/restaurant/orders/$orderId/items', data: payload);
      }

      Response? res;
      try {
        res = await sendPatch(currentVer);
      } catch (firstErr) {
        if (firstErr is DioException) {
          final sc = firstErr.response?.statusCode;
          debugPrint('PATCH error $sc for order $orderId: ${firstErr.response?.data}');

          if (sc == 409) {
            // Extract exact server version from backend response
            int? serverVer;
            final errBody = firstErr.response?.data?.toString() ?? '';
            final match = RegExp(r'version is (\d+)').firstMatch(errBody);
            if (match != null) {
              serverVer = int.tryParse(match.group(1)!);
              debugPrint('Parsed exact server version from 409 error message: $serverVer');
            }

            if (serverVer == null) {
              final allOrders = await fetchOrders();
              final matchOrd = allOrders.where((o) => o.id == orderId).firstOrNull;
              if (matchOrd != null) {
                serverVer = matchOrd.version;
              }
            }

            if (serverVer != null) {
              debugPrint('Retrying PATCH with resolved server version: $serverVer');
              try {
                res = await sendPatch(serverVer);
              } catch (retryErr) {
                debugPrint('Retry with serverVer $serverVer failed: $retryErr');
              }
            }
          } else if (sc == 400 || sc == 422 || sc == 405 || sc == 403) {
            // When order is in SERVED, HOLD, or READY status, backend might disallow direct PATCH.
            // Transition status back to SENT_TO_KITCHEN first, then retry!
            debugPrint('Order in completed/served/ready state. Attempting transition to SENT_TO_KITCHEN...');
            try {
              await _dio.post(
                '/api/restaurant/orders/$orderId/transitions',
                queryParameters: {'payload': 'SENT_TO_KITCHEN'},
                data: {'target_status': 'SENT_TO_KITCHEN', 'status': 'SENT_TO_KITCHEN'},
              );
              // Fetch latest version again because transition increments the version
              final allOrders = await fetchOrders();
              final matchOrd = allOrders.where((o) => o.id == orderId).firstOrNull;
              final retryVer = matchOrd?.version ?? (currentVer + 1);
              res = await sendPatch(retryVer);
            } catch (trErr) {
              debugPrint('Transition retry failed: $trErr');
            }
          }
        }

        if (res == null) {
          rethrow;
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final kotRes = await _dio.post('/api/restaurant/orders/$orderId/send-to-kitchen');
          debugPrint('send-to-kitchen response: ${kotRes.statusCode}');
        } catch (kotErr) {
          debugPrint('send-to-kitchen error: $kotErr');
        }
        // Also ensure order status transitions back to SENT_TO_KITCHEN so kitchen displays the running ticket
        try {
          await _dio.post(
            '/api/restaurant/orders/$orderId/transitions',
            queryParameters: {'payload': 'SENT_TO_KITCHEN'},
            data: {'target_status': 'SENT_TO_KITCHEN', 'status': 'SENT_TO_KITCHEN'},
          );
        } catch (_) {}
        return (res.data is Map<String, dynamic>) ? res.data : <String, dynamic>{};
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error updating order items [${e.response?.statusCode}]: ${e.response?.data}');
      } else {
        debugPrint('Error updating order items: $e');
      }
    }
    return null;
  }

  /// 8b. Fetch Active Order for Seated Table
  static Future<Map<String, dynamic>?> fetchActiveOrderByTable(String tableId) async {
    try {
      final res = await _dio.get('/api/restaurant/orders/table/$tableId');
      if (res.statusCode == 200 && res.data != null && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('Info: No active order for table $tableId: $e');
    }
    return null;
  }

  /// 9. Fetch Live Orders from Backend
  static Future<List<RestaurantOrder>> fetchOrders({
    String? outletId,
    String? statusFilter,
    String? customerPhone,
    int limit = 500,
  }) async {
    try {
      String resolvedOutletId = outletId ?? '';
      if (resolvedOutletId.isEmpty) {
        try {
          resolvedOutletId = await InventoryService.getShopId();
        } catch (_) {}
      }

      final res = await _dio.get(
        '/api/restaurant/orders',
        queryParameters: {
          if (resolvedOutletId.isNotEmpty) 'outlet_id': resolvedOutletId,
          if (statusFilter != null && statusFilter.isNotEmpty) 'status_filter': statusFilter,
          if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
          'limit': limit,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['orders'] ?? res.data['items'] ?? []);
        return list.map((json) => RestaurantOrderParser.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching live restaurant orders from backend: $e');
    }
    return [];
  }

  /// 10. Update Order Status / Transition on Backend
  static Future<bool> transitionOrderStatus({
    required String orderId,
    required String targetStatus,
  }) async {
    final status = targetStatus.toUpperCase();

    // 1. Try standard state-machine transition endpoint
    try {
      final res = await _dio.post(
        '/api/restaurant/orders/$orderId/transitions',
        queryParameters: {'payload': status},
        data: {'target_status': status, 'status': status, 'action': status},
      );
      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        // Also execute direct PATCH so backend updates kitchen_status and kot_status database columns!
        try {
          await _dio.patch(
            '/api/restaurant/orders/$orderId',
            data: {
              'status': status,
              'order_status': status,
              'kitchen_status': status,
              'kot_status': status,
            },
          );
        } catch (_) {}
        return true;
      }
    } catch (e) {
      debugPrint('POST /transitions error for $orderId ($status): $e');
    }

    // 2. Fallback: Direct PATCH /api/restaurant/orders/$orderId
    try {
      final patchRes = await _dio.patch(
        '/api/restaurant/orders/$orderId',
        data: {
          'status': status,
          'order_status': status,
          'kitchen_status': status,
          'kot_status': status,
        },
      );
      if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
        return true;
      }
    } catch (patchErr) {
      debugPrint('PATCH /orders/$orderId fallback error: $patchErr');
    }

    // 3. Fallback: POST /api/restaurant/orders/$orderId/status
    try {
      final statusRes = await _dio.post(
        '/api/restaurant/orders/$orderId/status',
        data: {'status': status, 'order_status': status},
      );
      if (statusRes.statusCode == 200 || statusRes.statusCode == 204) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}

