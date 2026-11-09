import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_client.dart';
import '../config/api_constants.dart';
import '../models/restaurant_pos_models.dart';
import 'inventory_service.dart';

class RestaurantPosService {
  static final Dio _dio = ApiClient().dio;

  /// Helper to ensure relative URLs and external CORS-blocked URLs (e.g. Wikimedia) resolve properly
  static String? resolveImageUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;
    var str = rawUrl.toString().trim();
    if (str.isEmpty) return null;

    // For Wikimedia Commons Special:FilePath images, append width thumbnail (width=400)
    // to avoid downloading huge 10MB-20MB original raw camera files!
    if (str.contains("commons.wikimedia.org/wiki/Special:FilePath") && !str.contains("width=")) {
      str = str.contains("?") ? "$str&width=400" : "$str?width=400";
    }

    final base = ApiConstants.baseUrl.endsWith("/")
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    // On Web, Wikimedia Commons blocks direct requests due to browser CORS, so route via backend proxy.
    // On native platforms (Windows desktop, macOS, Android, iOS), direct requests work without CORS limitations.
    if (kIsWeb && str.contains("wikimedia.org")) {
      return "$base/api/restaurant/menu/image-proxy?url=${Uri.encodeComponent(str)}";
    }

    if (str.startsWith("http://") || str.startsWith("https://")) {
      return str;
    }

    final path = str.startsWith("/") ? str : "/$str";
    return "$base$path";
  }

  static String? _resolveImageUrl(dynamic rawUrl) => resolveImageUrl(rawUrl);

  /// 1. Fetch live Menu Items from Backend
  static Future<List<PosMenuItem>> fetchMenuItems({String? outletId, bool availableOnly = false}) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/menu/items',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
          if (availableOnly) 'available_only': true,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['items'] ?? []);
        return list.map((json) {
          final isVegVal = json['is_veg'] ?? json['veg'] ?? (json['food_type'] == 'VEG' || json['type'] == 'VEG') ?? true;
          final rawImg = json['image_url'] ?? json['image'] ?? json['item_image'];
          final rawPrice = json['price'] ?? json['unit_price'] ?? json['selling_price'] ?? json['base_price'] ?? json['rate'] ?? json['amount'] ?? 0.0;
          final rawBadge = json['badge'] ?? json['tag'] ?? json['food_badge'];

          final rawShortCode = json['short_code'] ?? json['code'];

          return PosMenuItem(
            id: json['id']?.toString() ?? '',
            name: json['name'] ?? json['item_name'] ?? '',
            shortCode: rawShortCode?.toString(),
            categoryId: json['category_id']?.toString() ?? 'all',
            price: (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0),
            imageUrl: _resolveImageUrl(rawImg),
            badge: rawBadge?.toString(),
            taxPercent: (json['tax_percent'] ?? json['gst_rate'] ?? json['gst'] ?? 5.0).toDouble(),
            isAvailable: json['is_available'] ?? true,
            isVeg: isVegVal is bool ? isVegVal : (isVegVal.toString().toLowerCase() != 'false' && isVegVal.toString() != '0'),
            description: json['description'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching restaurant menu items from backend: $e');
    }
    return [];
  }

  /// 1b. Create Menu Item on Backend
  static Future<PosMenuItem?> createMenuItem({
    required String name,
    String? shortCode,
    required String categoryId,
    required double price,
    String? description,
    String? badge,
    String? imageUrl,
    bool isVeg = true,
    String? outletId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/menu/items',
        data: {
          'name': name,
          'item_name': name,
          if (shortCode != null && shortCode.trim().isNotEmpty) 'short_code': shortCode.trim().toUpperCase(),
          'category_id': categoryId,
          'price': price,
          'unit_price': price,
          'selling_price': price,
          'base_price': price,
          'rate': price,
          'description': description,
          'badge': badge,
          'tag': badge,
          if (imageUrl != null && imageUrl.isNotEmpty) ...{
            'image_url': imageUrl,
            'image': imageUrl,
          },
          'is_available': true,
          'is_veg': isVeg,
          'veg': isVeg,
          'food_type': isVeg ? 'VEG' : 'NON_VEG',
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = res.data is Map ? res.data : {};
        final rawImg = json['image_url'] ?? json['image'] ?? imageUrl;
        final rawPrice = json['price'] ?? json['unit_price'] ?? json['selling_price'] ?? json['base_price'] ?? price;
        final resShortCode = json['short_code'] ?? shortCode;
        return PosMenuItem(
          id: json['id']?.toString() ?? 'dish_${DateTime.now().millisecondsSinceEpoch}',
          name: json['name'] ?? name,
          shortCode: resShortCode?.toString(),
          categoryId: json['category_id']?.toString() ?? categoryId,
          price: (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? price),
          description: json['description'] ?? description,
          badge: json['badge'] ?? badge,
          imageUrl: _resolveImageUrl(rawImg),
          isAvailable: true,
          isVeg: isVeg,
        );
      }
    } catch (e) {
      debugPrint('Error creating menu item on backend: $e');
    }
    return null;
  }

  /// 1c. Update Menu Item on Backend
  static Future<bool> updateMenuItem(PosMenuItem item) async {
    try {
      final payload = {
        'name': item.name,
        'item_name': item.name,
        if (item.shortCode != null && item.shortCode!.trim().isNotEmpty)
          'short_code': item.shortCode!.trim().toUpperCase(),
        'category_id': item.categoryId,
        'price': item.price,
        'unit_price': item.price,
        'selling_price': item.price,
        'base_price': item.price,
        'rate': item.price,
        'description': item.description,
        'badge': item.badge,
        'tag': item.badge,
        'image_url': item.imageUrl,
        'image': item.imageUrl,
        'is_available': item.isAvailable,
        'is_veg': item.isVeg,
        'veg': item.isVeg,
        'food_type': item.isVeg ? 'VEG' : 'NON_VEG',
      };
      debugPrint('PUT /api/restaurant/menu/items/${item.id} with payload: $payload');
      final res = await _dio.put(
        '/api/restaurant/menu/items/${item.id}',
        data: payload,
      );
      debugPrint('PUT response [${res.statusCode}]: ${res.data}');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating menu item on backend: $e');
      return false;
    }
  }

  /// 1d. Toggle Availability on Backend
  static Future<bool> toggleMenuItemAvailability(String itemId, bool isAvailable) async {
    try {
      final res = await _dio.patch(
        '/api/restaurant/menu/items/$itemId/availability',
        data: {'is_available': isAvailable},
      );
      if (res.statusCode == 200 || res.statusCode == 204) return true;
    } catch (e) {
      debugPrint('PATCH availability failed, trying fallback update: $e');
    }

    // Fallback: update via main PUT/PATCH item endpoint
    try {
      final res = await _dio.put(
        '/api/restaurant/menu/items/$itemId',
        data: {'is_available': isAvailable},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error toggling menu item availability: $e');
      return false;
    }
  }

  /// 1e. Delete Menu Item on Backend
  static Future<bool> deleteMenuItem(String itemId) async {
    try {
      final res = await _dio.delete('/api/restaurant/menu/items/$itemId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting menu item on backend: $e');
      return false;
    }
  }

  /// 2. Fetch Menu Categories
  static Future<List<MenuCategory>> fetchCategories({String? outletId}) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/menu/categories',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['categories'] ?? []);
        final parsed = list.map((json) {
          final name = json['name'] ?? json['category_name'] ?? json['title'] ?? '';
          String emoji = json['icon_emoji'] ?? json['emoji'] ?? json['icon'] ?? '🍽️';
          return MenuCategory(
            id: json['id']?.toString() ?? '',
            name: name,
            iconEmoji: emoji,
          );
        }).toList();

        // Always ensure 'All Items' exists at the start
        if (!parsed.any((c) => c.id == 'all')) {
          parsed.insert(0, const MenuCategory(id: 'all', name: 'All Items', iconEmoji: '🍱'));
        }
        return parsed;
      }
    } catch (e) {
      debugPrint('Error fetching menu categories: $e');
    }
    return [];
  }

  /// 2b. Create Menu Category on Backend
  static Future<MenuCategory?> createCategory({
    required String name,
    required String iconEmoji,
    String? outletId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/menu/categories',
        data: {
          'name': name,
          'category_name': name,
          'icon_emoji': iconEmoji,
          'emoji': iconEmoji,
          'icon': iconEmoji,
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = res.data is Map ? res.data : {};
        final resEmoji = json['icon_emoji'] ?? json['emoji'] ?? json['icon'] ?? iconEmoji;
        return MenuCategory(
          id: json['id']?.toString() ?? name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
          name: json['name'] ?? json['category_name'] ?? name,
          iconEmoji: resEmoji,
        );
      }
    } catch (e) {
      debugPrint('Error creating menu category on backend: $e');
    }
    return null;
  }

  /// 2c. Update Menu Category on Backend
  static Future<bool> updateCategory({
    required String id,
    required String name,
    required String iconEmoji,
  }) async {
    try {
      final res = await _dio.put(
        '/api/restaurant/menu/categories/$id',
        data: {
          'name': name,
          'category_name': name,
          'icon_emoji': iconEmoji,
          'emoji': iconEmoji,
          'icon': iconEmoji,
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating category on backend: $e');
      return false;
    }
  }

  /// 2d. Delete Menu Category on Backend
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      final res = await _dio.delete('/api/restaurant/menu/categories/$categoryId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting category on backend: $e');
      return false;
    }
  }

  /// 2e. Bulk Upload Menu Items (.xlsx, .xls, .csv)
  static Future<Map<String, dynamic>> bulkUploadMenu({
    required String filename,
    List<int>? bytes,
    String? path,
    String? outletId,
  }) async {
    try {
      final effectiveOutletId = (outletId != null && outletId.isNotEmpty)
          ? outletId
          : await InventoryService.getShopId();

      MultipartFile multipartFile;
      if (bytes != null) {
        multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
      } else if (path != null) {
        multipartFile = await MultipartFile.fromFile(path, filename: filename);
      } else {
        throw Exception('File data is missing');
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        if (effectiveOutletId.isNotEmpty)
          'outlet_id': effectiveOutletId,
      });

      final res = await _dio.post(
        '/api/restaurant/menu/bulk-upload',
        data: formData,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return (res.data is Map<String, dynamic>)
            ? res.data as Map<String, dynamic>
            : {'success': true, 'message': 'Upload successful'};
      } else {
        throw Exception(res.data?['detail'] ?? 'Failed to bulk upload menu');
      }
    } catch (e) {
      debugPrint('Error in bulkUploadMenu: $e');
      rethrow;
    }
  }

  /// 2f. Download Sample Menu Template (.xlsx or .csv) with outlet-specific dropdowns
  static Future<List<int>> downloadSampleMenuTemplate({
    String? outletId,
    String format = 'xlsx',
  }) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/menu/sample-template',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
          'format': format,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.data is List<int>) {
        return res.data as List<int>;
      } else if (res.data is List) {
        return List<int>.from(res.data);
      }
      return List<int>.from(res.data);
    } catch (e) {
      debugPrint('Error downloading sample menu template: $e');
      rethrow;
    }
  }

  /// 3. Fetch Live Dining Tables & Occupancy
  static Future<List<DiningTable>> fetchTables({String? outletId}) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/tables',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['tables'] ?? []);

        // Fetch live orders to reconcile table occupancy accurately:
        // A table remains OCCUPIED if there is any active or served Dine-In order
        // that has not yet been paid/settled by the cashier.
        final Map<String, dynamic> tableUnsettledOrderMap = {};
        try {
          final ordersRes = await _dio.get(
            '/api/restaurant/orders',
            queryParameters: {
              if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
              'limit': 50,
            },
          );
          if (ordersRes.statusCode == 200 && ordersRes.data != null) {
            final List ordersList = ordersRes.data is List
                ? ordersRes.data
                : (ordersRes.data['orders'] ?? ordersRes.data['items'] ?? []);
            for (final o in ordersList) {
              final oType = (o['order_type'] ?? 'DINE_IN').toString().toUpperCase();
              if (!oType.contains('DINE')) continue;

              final oStatus = (o['status'] ?? '').toString().toUpperCase();
              if (oStatus.contains('CANCEL') ||
                  oStatus.contains('VOID') ||
                  oStatus.contains('SETTLE') ||
                  oStatus.contains('COMPLET')) {
                continue;
              }

              final paidAmt = double.tryParse((o['paid_amount'] ?? '0').toString()) ?? 0.0;
              final grandTotal = double.tryParse((o['grand_total'] ?? o['total'] ?? '0').toString()) ?? 0.0;
              // If not fully paid, this table is still occupied by guests
              if (grandTotal > 0 && paidAmt >= grandTotal) {
                continue;
              }

              final tid = o['table_id']?.toString();
              if (tid != null && tid.isNotEmpty && !tableUnsettledOrderMap.containsKey(tid)) {
                tableUnsettledOrderMap[tid] = o;
              }
            }
          }
        } catch (_) {}

        return list.map((json) {
          final tableId = json['id']?.toString() ?? '';
          final tableLabel = (json['table_number'] ?? json['label'] ?? json['name'] ?? '').toString();

          final rawStatus = (json['status'] ?? '').toString().toLowerCase();
          TableStatus status = TableStatus.available;
          if (rawStatus == 'occupied') {
            status = TableStatus.occupied;
          } else if (rawStatus == 'reserved') {
            status = TableStatus.reserved;
          } else if (rawStatus == 'vacant' || rawStatus == 'available') {
            status = TableStatus.available;
          }

          // Reconcile: If this table has an active/served unpaid order, keep it OCCUPIED
          final unsettledOrder = tableUnsettledOrderMap[tableId];
          if (unsettledOrder != null && status != TableStatus.occupied) {
            status = TableStatus.occupied;
          }

          final rawBill = unsettledOrder != null
              ? (unsettledOrder['grand_total'] ?? unsettledOrder['total'] ?? 0.0)
              : (json['active_order_grand_total'] ?? json['current_bill_amount'] ?? 0.0);
          final currentBill = (rawBill is num) ? rawBill.toDouble() : (double.tryParse(rawBill.toString()) ?? 0.0);
          final activeOrderCount = unsettledOrder != null
              ? 1
              : (json['active_order_count'] ?? (status == TableStatus.occupied ? 1 : 0));

          String? durationStr;
          final orderCreatedAtStr = unsettledOrder != null
              ? (unsettledOrder['created_at'] ?? unsettledOrder['order_time'])
              : (json['active_order_created_at'] ?? json['occupied_since']);
          if (status == TableStatus.occupied && orderCreatedAtStr != null) {
            try {
              final rawStr = orderCreatedAtStr.toString().trim();
              final isoUtc = (rawStr.endsWith('Z') || rawStr.contains('+'))
                  ? rawStr
                  : '${rawStr}Z';
              final orderTime = DateTime.parse(isoUtc).toLocal();
              final diff = DateTime.now().difference(orderTime);
              final totalSeconds = diff.inSeconds;
              if (totalSeconds < 60) {
                durationStr = '00:01';
              } else {
                final hours = diff.inHours.toString().padLeft(2, '0');
                final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
                durationStr = '$hours:$mins';
              }
            } catch (_) {
              durationStr = '00:01';
            }
          } else if (status == TableStatus.occupied) {
            durationStr = '00:01';
          }

          return DiningTable(
            id: tableId,
            label: tableLabel,
            capacity: json['capacity'] ?? 4,
            status: status,
            floor: json['floor'] ?? json['section'] ?? 'Floor 1',
            occupiedDuration: durationStr,
            currentBillAmount: currentBill,
            activeOrderCount: activeOrderCount is int ? activeOrderCount : int.tryParse(activeOrderCount.toString()) ?? (status == TableStatus.occupied ? 1 : 0),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dining tables: $e');
    }
    return [];
  }

  /// 3b. Create Dining Table on Backend
  static Future<DiningTable?> createTable({
    required String label,
    required int capacity,
    required String floor,
    String? outletId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/tables',
        data: {
          'table_number': label,
          'capacity': capacity,
          'floor': floor,
          'status': 'AVAILABLE',
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = res.data is Map ? res.data : {};
        return DiningTable(
          id: json['id']?.toString() ?? 'T_${DateTime.now().millisecondsSinceEpoch}',
          label: json['table_number'] ?? label,
          capacity: json['capacity'] ?? capacity,
          floor: json['floor'] ?? floor,
          status: TableStatus.available,
        );
      }
    } catch (e) {
      debugPrint('Error creating dining table on backend: $e');
    }
    return null;
  }

  /// 3c. Update Table Details on Backend (Label, Capacity, Floor)
  static Future<bool> updateTable({
    required String tableId,
    required String label,
    required int capacity,
    required String floor,
  }) async {
    try {
      final res = await _dio.put(
        '/api/restaurant/tables/$tableId',
        data: {
          'table_number': label,
          'capacity': capacity,
          'floor': floor,
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating table details on backend: $e');
      return false;
    }
  }

  /// 3d. Update Table Status on Backend
  static Future<bool> updateTableStatus(String tableId, TableStatus status) async {
    try {
      final statusStr = status == TableStatus.available
          ? 'AVAILABLE'
          : (status == TableStatus.occupied ? 'OCCUPIED' : 'RESERVED');
      final res = await _dio.patch(
        '/api/restaurant/tables/$tableId/status',
        data: {'status': statusStr, 'table_status': statusStr},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating table status on backend: $e');
      // If AVAILABLE failed, retry with VACANT for compatibility
      if (status == TableStatus.available) {
        try {
          final retryRes = await _dio.patch(
            '/api/restaurant/tables/$tableId/status',
            data: {'status': 'VACANT'},
          );
          return retryRes.statusCode == 200 || retryRes.statusCode == 204;
        } catch (_) {}
      }
      return false;
    }
  }

  /// 3e. Delete Table on Backend
  static Future<bool> deleteTable(String tableId) async {
    try {
      final res = await _dio.delete('/api/restaurant/tables/$tableId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting table on backend: $e');
      return false;
    }
  }

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

      // Backend expects RestaurantOrderCreate schema with 'lines' array
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

  /// 4b. Append / Update Items on an Existing Held Table Order
  static Future<Map<String, dynamic>?> appendItemsToOrder({
    required String orderId,
    required List<PosCartItem> newItems,
    int? expectedVersion = 1,
  }) async {
    try {
      final payload = {
        'expected_version': expectedVersion ?? 1,
        'lines': newItems.map((cartItem) {
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

      debugPrint('PATCH /api/restaurant/orders/$orderId/items payload: $payload');
      final res = await _dio.patch('/api/restaurant/orders/$orderId/items', data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        // Trigger kitchen ticket for newly added items
        try {
          await _dio.post('/api/restaurant/orders/$orderId/send-to-kitchen');
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

  /// 5. Settle Bill & Complete Payment
  static Future<bool> settleOrder({
    required String orderId,
    required double grandTotal,
    required String paymentMode,
    double discountAmount = 0.0,
    List<Map<String, dynamic>>? splitTenders,
  }) async {
    try {
      // Backend expects RestaurantMultiTenderCheckout with 'tenders' array
      final tenders = (splitTenders != null && splitTenders.isNotEmpty)
          ? splitTenders
          : [
              {
                'method': paymentMode.toUpperCase(),
                'amount': grandTotal,
              }
            ];

      final payload = {
        'tenders': tenders,
        'payment_mode': paymentMode.toUpperCase(),
        'payment_method': paymentMode.toUpperCase(),
        'tender_mode': paymentMode.toUpperCase(),
        if (discountAmount > 0) ...{
          'discount_type': 'FLAT',
          'discount_value': discountAmount,
          'discount_reason': 'POS Checkout Discount',
        },
      };

      debugPrint('POST /api/restaurant/orders/$orderId/settle payload: $payload');
      final res = await _dio.post('/api/restaurant/orders/$orderId/settle', data: payload);
      return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error settling restaurant bill [${e.response?.statusCode}]: ${e.response?.data}');
      } else {
        debugPrint('Error settling restaurant bill: $e');
      }
    }
    return false;
  }

  /// 6. Generate Dynamic UPI QR Code
  static Future<String?> generateUpiQr({
    required String orderId,
    required double amount,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/orders/payments/generate-upi-qr',
        data: {
          'order_id': orderId,
          'amount': amount,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data['qr_svg'] ?? res.data['qr_base64'] ?? res.data['upi_intent'];
      }
    } catch (e) {
      debugPrint('Error generating dynamic UPI QR: $e');
    }
    return null;
  }

  /// 7. Fetch Backend Thermal Bill Template (80mm HTML format)
  static Future<String?> fetchThermalBillHtml(String orderId) async {
    try {
      final res = await _dio.get('/api/restaurant/orders/$orderId/thermal-bill');
      if (res.statusCode == 200 && res.data != null) {
        return res.data.toString();
      }
    } catch (e) {
      debugPrint('Error fetching thermal bill HTML: $e');
    }
    return null;
  }

  /// 8. Trigger Backend Thermal Print Job and retrieve bill details (including bill_pdf_url)
  static Future<Map<String, dynamic>?> printThermalBill(String orderId) async {
    try {
      final res = await _dio.post('/api/restaurant/orders/$orderId/print-bill');
      if (res.statusCode == 200 && res.data != null && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('Error triggering backend thermal bill print: $e');
    }
    return null;
  }

  /// Download the exact official thermal PDF generated by the backend
  static Future<Uint8List?> fetchBackendBillPdfBytes(String orderId, {String? billPdfUrl}) async {
    try {
      String? url = billPdfUrl;
      if (url == null || url.isEmpty) {
        final printRes = await printThermalBill(orderId);
        url = printRes?['bill_pdf_url']?.toString();
      }

      if (url != null && url.isNotEmpty) {
        final fullUrl = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
        final response = await _dio.get(
          fullUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          return Uint8List.fromList(response.data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching backend bill PDF bytes: $e');
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
          
          // Parse Order Type
          final rawType = (json['order_type'] ?? 'DINE_IN').toString().toUpperCase();
          OrderType orderType = OrderType.dineIn;
          if (rawType.contains('TAKEAWAY') || rawType.contains('TAKE_AWAY') || rawType.contains('PARCEL')) {
            orderType = OrderType.takeaway;
          } else if (rawType.contains('DELIVERY')) {
            orderType = OrderType.delivery;
          }

          // Parse Order Status
          final rawStatus = (json['status'] ?? json['order_status'] ?? 'OPEN').toString().toUpperCase();
          OrderStatus orderStatus = OrderStatus.active;
          if (rawStatus == 'SERVED') {
            orderStatus = OrderStatus.served;
          } else if (rawStatus.contains('SETTLED') || rawStatus.contains('COMPLETE') || rawStatus.contains('PAID')) {
            orderStatus = OrderStatus.completed;
          } else if (rawStatus.contains('CANCEL')) {
            orderStatus = OrderStatus.cancelled;
          } else if (rawStatus.contains('HOLD')) {
            orderStatus = OrderStatus.hold;
          }

          // Parse Payment Status
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

          // Parse Items / Lines
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

          // Extract Payment Method accurately from settlement tenders, payment mode, or payments list
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

    // If target is SETTLED, use the dedicated settle endpoint if needed
    if (status == 'SETTLED') {
      try {
        final settleRes = await settleOrder(
          orderId: orderId,
          grandTotal: 0,
          paymentMode: 'CASH',
        );
        if (settleRes) return true;
      } catch (_) {}
    }

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

