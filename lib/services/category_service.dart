import 'package:dio/dio.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? tenantId;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.tenantId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      tenantId: json['tenant_id'],
    );
  }
}

class CategoryService {
  static Future<List<Category>> getCategories() async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.get('/api/admin/categories/$shopId', queryParameters: {'tenant_id': shopId, 'shop_id': shopId});
      
      if (response.statusCode == 200) {
        dynamic data = response.data;
        if (data is Map) {
          data = data['categories'] ?? data['items'] ?? data['data'] ?? data.values.first;
        }
        if (data is List) {
          return data.map((json) => Category.fromJson(json)).toList();
        }
        return [];
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      if (e is DioException) {
        throw Exception('DioError ${e.response?.statusCode} on ${e.requestOptions.path}: $e');
      }
      throw Exception('Error loading categories: $e');
    }
  }

  static Future<Category> createCategory(String name, String? description) async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.post(
        '/api/admin/categories/',
        data: {
          'shop_id': shopId,
          'tenant_id': shopId,
          'name': name,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Category.fromJson(response.data);
      }
      throw Exception('Failed to create category');
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      final response = await ApiClient().dio.delete('/api/admin/categories/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }
}
