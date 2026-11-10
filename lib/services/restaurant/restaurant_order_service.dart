import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../models/restaurant_pos_models.dart';
import '../inventory_service.dart';

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
      Future<Response> sendPatch(int ver, {bool includeExpectedVersion = true}) {
        final payload = {
          if (includeExpectedVersion) 'expected_version': ver,
          'lines': linesData,
          'items': linesData,
        };
        debugPrint('PATCH /api/restaurant/orders/$orderId/items payload: $payload');
        return _dio.patch('/api/restaurant/orders/$orderId/items', data: payload);
      }

      Response? res;
      try {
        res = await sendPatch(currentVer, includeExpectedVersion: true);
      } catch (firstErr) {
        if (firstErr is DioException) {
          final sc = firstErr.response?.statusCode;
          debugPrint('PATCH error $sc for order $orderId: ${firstErr.response?.data}');

          if (sc == 409) {
            debugPrint('409 Conflict detected for order $orderId. Fetching latest version from server...');
            final latestOrder = await fetchOrderById(orderId);
            if (latestOrder != null && latestOrder['version'] != null) {
              final serverVer = (latestOrder['version'] is num)
                  ? (latestOrder['version'] as num).toInt()
                  : (int.tryParse(latestOrder['version'].toString()) ?? currentVer + 1);
              debugPrint('Retrying with fetched server version: $serverVer');
              try {
                res = await sendPatch(serverVer, includeExpectedVersion: true);
              } catch (_) {}
            }

            if (res == null) {
              debugPrint('Retrying without expected_version key in payload...');
              try {
                res = await sendPatch(currentVer, includeExpectedVersion: false);
              } catch (_) {}
            }
          } else if (sc == 400 || sc == 422 || sc == 405 || sc == 403) {
            // When order is in SERVED or HOLD status, backend might disallow direct PATCH.
            // Transition status back to SENT_TO_KITCHEN or OPEN, then retry!
            debugPrint('Order in completed/served state. Attempting transition to SENT_TO_KITCHEN...');
            try {
              await _dio.post(
                '/api/restaurant/orders/$orderId/transitions',
                queryParameters: {'payload': 'SENT_TO_KITCHEN'},
                data: {'target_status': 'SENT_TO_KITCHEN', 'status': 'SENT_TO_KITCHEN'},
              );
              res = await sendPatch(currentVer, includeExpectedVersion: false);
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
          await _dio.post('/api/restaurant/orders/$orderId/send-to-kitchen');
        } catch (_) {}
        // Also ensure order status transitions back to OPEN/SENT_TO_KITCHEN so kitchen displays the running ticket
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
        return list.map((json) {
          final rawId = json['id'] ?? json['order_id'] ?? '';
          final rawOrderNum = json['order_number'] ?? json['order_no'] ?? '#ORD-${rawId.toString().substring(0, rawId.toString().length > 6 ? 6 : rawId.toString().length)}';
          
          final rawType = (json['order_type'] ?? 'DINE_IN').toString().toUpperCase();
          OrderType orderType = OrderType.dineIn;
          if (rawType.contains('TAKEAWAY') || rawType.contains('TAKE_AWAY') || rawType.contains('PARCEL')) {
            orderType = OrderType.takeaway;
          } else if (rawType.contains('DELIVERY')) {
            orderType = OrderType.delivery;
          }

          final rawStatus = (json['status'] ?? json['order_status'] ?? 'OPEN').toString().toUpperCase();
          OrderStatus orderStatus = OrderStatus.active;
          if (rawStatus == 'READY' || rawStatus.contains('READY') || rawStatus == 'FOOD_READY' || rawStatus == 'PREPARED') {
            orderStatus = OrderStatus.ready;
          } else if (rawStatus == 'SERVED') {
            orderStatus = OrderStatus.served;
          } else if (rawStatus.contains('SETTLED') || rawStatus.contains('COMPLETE') || rawStatus.contains('PAID')) {
            orderStatus = OrderStatus.completed;
          } else if (rawStatus.contains('CANCEL')) {
            orderStatus = OrderStatus.cancelled;
          } else if (rawStatus.contains('HOLD')) {
            orderStatus = OrderStatus.hold;
          }

          final rawPayment = (json['payment_status'] ?? 'PENDING').toString().toUpperCase();
          final rawPaidAmt = double.tryParse((json['paid_amount'] ?? '0').toString()) ?? 0.0;
          final rawGrandAmt = double.tryParse((json['grand_total'] ?? json['total'] ?? '0').toString()) ?? 0.0;
          PaymentStatus paymentStatus = PaymentStatus.pending;
          if (rawPayment.contains('PAID') ||
              rawStatus.contains('SETTLED') ||
              rawStatus.contains('COMPLET') ||
              (rawPaidAmt > 0 && rawPaidAmt >= rawGrandAmt)) {
            paymentStatus = PaymentStatus.paid;
          } else if (rawPayment.contains('REFUND')) {
            paymentStatus = PaymentStatus.refunded;
          }

          final rawItems = json['items'] ?? json['lines'] ?? json['order_lines'] ?? [];
          final List<PosCartItem> items = [];
          if (rawItems is List) {
            for (final it in rawItems) {
              final rawQty = it['quantity'] ?? it['qty'] ?? 1;
              final qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
              final rawPrice = it['unit_price'] ?? it['price'] ?? it['rate'] ?? 0.0;
              final price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
              final itemName = it['name'] ?? it['item_name'] ?? it['menu_item_name'] ?? 'Item';
              final itemId = it['menu_item_id'] ?? it['item_id'] ?? it['id'] ?? '';
              final itemNotes = it['notes']?.toString();

              items.add(
                PosCartItem(
                  item: PosMenuItem(
                    id: itemId.toString(),
                    name: itemName.toString(),
                    categoryId: it['category_id']?.toString() ?? 'all',
                    price: price,
                  ),
                  quantity: qty,
                  notes: itemNotes,
                ),
              );
            }
          }

          final rawSubtotal = json['subtotal'] ?? json['total_amount'] ?? json['sub_total'] ?? 0.0;
          final rawDiscount = json['discount_amount'] ?? json['discount'] ?? 0.0;
          final rawGst = json['tax_amount'] ?? json['gst_amount'] ?? json['tax'] ?? 0.0;
          final rawGrand = json['grand_total'] ?? json['total'] ?? json['settled_amount'] ?? 0.0;

          final createdAtStr = json['created_at'] ?? json['order_time'] ?? json['date'];
          DateTime createdAt = DateTime.now();
          if (createdAtStr != null) {
            try {
              String s = createdAtStr.toString().trim();
              if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
                s = '${s}Z';
              }
              createdAt = DateTime.parse(s).toLocal();
            } catch (_) {}
          }

          String resolvedPayment = '';
          if (json['tenders'] is List && (json['tenders'] as List).isNotEmpty) {
            final firstTender = (json['tenders'] as List).first;
            resolvedPayment = (firstTender['method'] ?? firstTender['payment_method'] ?? firstTender['mode'] ?? '').toString();
          }
          if (resolvedPayment.isEmpty && json['payments'] is List && (json['payments'] as List).isNotEmpty) {
            final firstPay = (json['payments'] as List).first;
            resolvedPayment = (firstPay['payment_mode'] ?? firstPay['method'] ?? firstPay['payment_method'] ?? '').toString();
          }
          if (resolvedPayment.isEmpty && json['settlements'] is List && (json['settlements'] as List).isNotEmpty) {
            final firstSet = (json['settlements'] as List).first;
            resolvedPayment = (firstSet['method'] ?? firstSet['payment_mode'] ?? '').toString();
          }
          if (resolvedPayment.isEmpty && json['payment_mode'] != null && json['payment_mode'].toString().isNotEmpty) {
            resolvedPayment = json['payment_mode'].toString();
          }
          if (resolvedPayment.isEmpty && json['payment_method'] != null && json['payment_method'].toString().isNotEmpty) {
            resolvedPayment = json['payment_method'].toString();
          }
          if (resolvedPayment.isEmpty && json['settlement_mode'] != null && json['settlement_mode'].toString().isNotEmpty) {
            resolvedPayment = json['settlement_mode'].toString();
          }
          if (resolvedPayment.isEmpty && json['tender_method'] != null && json['tender_method'].toString().isNotEmpty) {
            resolvedPayment = json['tender_method'].toString();
          }
          if (resolvedPayment.isEmpty) {
            resolvedPayment = 'CASH';
          }

          return RestaurantOrder(
            id: rawId.toString(),
            orderNumber: rawOrderNum.toString(),
            orderType: orderType,
            status: orderStatus,
            paymentStatus: paymentStatus,
            paymentMethod: resolvedPayment,
            tableId: json['table_id']?.toString(),
            tableLabel: json['table_label']?.toString() ?? json['table_number']?.toString() ?? json['table_name']?.toString() ?? json['table_id']?.toString(),
            floor: json['floor']?.toString(),
            customerName: json['customer_name']?.toString() ?? 'Walk-in Guest',
            customerPhone: json['customer_phone']?.toString() ?? '',
            items: items,
            subtotal: (rawSubtotal is num) ? rawSubtotal.toDouble() : (double.tryParse(rawSubtotal.toString()) ?? 0.0),
            discount: (rawDiscount is num) ? rawDiscount.toDouble() : (double.tryParse(rawDiscount.toString()) ?? 0.0),
            gstAmount: (rawGst is num) ? rawGst.toDouble() : (double.tryParse(rawGst.toString()) ?? 0.0),
            grandTotal: (rawGrand is num) ? rawGrand.toDouble() : (double.tryParse(rawGrand.toString()) ?? 0.0),
            createdAt: createdAt,
            notes: json['notes']?.toString(),
          );
        }).toList();
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

    try {
      final res = await _dio.post(
        '/api/restaurant/orders/$orderId/transitions',
        queryParameters: {'payload': status},
        data: {'target_status': status, 'status': status},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error transitioning order status on backend: $e');
      return false;
    }
  }
}

