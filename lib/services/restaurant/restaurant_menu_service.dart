import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../config/api_constants.dart';
import '../../models/restaurant_pos_models.dart';
import '../inventory_service.dart';

/// Service handling Menu items, categories, image resolution, and bulk upload operations
class RestaurantMenuService {
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
            imageUrl: resolveImageUrl(rawImg),
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
          imageUrl: resolveImageUrl(rawImg),
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
}

