import 'package:flutter/foundation.dart';

import '../config/api_client.dart';
import 'inventory_service.dart';

class DistributorService {
  final ApiClient _apiClient = ApiClient();

  // Get all distributors
  Future<List<dynamic>> getDistributors({String? search}) async {
    try {
      final shopId = await InventoryService.getShopId();
      final queryParams = <String, dynamic>{'shop_id': shopId, 'tenant_id': shopId};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _apiClient.dio.get(
        '/api/admin/distributors/',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      throw Exception('Failed to load distributors: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Info: Distributor access restricted or error fetching distributors: $e');
      }
      return [];
    }
  }

  // Add a new distributor
  Future<Map<String, dynamic>> addDistributor(Map<String, dynamic> data) async {
    try {
      final shopId = await InventoryService.getShopId();
      data['shop_id'] = shopId;
      data['tenant_id'] = shopId;
      final response = await _apiClient.dio.post(
        '/api/admin/distributors/',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to add distributor: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error adding distributor: $e');
      }
      rethrow;
    }
  }

  // Update a distributor
  Future<Map<String, dynamic>> updateDistributor(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        '/api/admin/distributors/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to update distributor: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error updating distributor: $e');
      }
      rethrow;
    }
  }

  // Delete a distributor
  Future<void> deleteDistributor(String id) async {
    try {
      final response = await _apiClient.dio.delete('/api/admin/distributors/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete distributor: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting distributor: $e');
      }
      rethrow;
    }
  }

  // Get distributor analytics
  Future<Map<String, dynamic>> getDistributorAnalytics(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/admin/distributors/$id/analytics');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to load distributor analytics: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching analytics: $e');
      }
      rethrow;
    }
  }
}
