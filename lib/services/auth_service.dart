import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'user_role';
  static const String _userNameKey = 'user_name';

  /// Admin login using email and password
  static Future<bool> adminLogin(String email, String password) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/auth/admin-login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token']);
        await prefs.setString(_userIdKey, data['user_id']);
        await prefs.setString(_roleKey, data['role']);
        if (data['name'] != null) {
          await prefs.setString(_userNameKey, data['name']);
        }
        
        try {
          // If the user has an assigned outlet returned by the backend, prioritize it
          final assignedId = data['assigned_outlet_id']?.toString() ??
              (data['outlet'] != null ? data['outlet']['id']?.toString() : null) ??
              data['outlet_id']?.toString();

          if (assignedId != null && assignedId.isNotEmpty) {
            await prefs.setString('selected_shop_id', assignedId);
            await prefs.setString('assigned_outlet_id', assignedId);
            if (data['outlet'] != null && data['outlet']['name'] != null) {
              await prefs.setString('assigned_outlet_name', data['outlet']['name'].toString());
            }
          } else {
            await prefs.remove('assigned_outlet_id');
            await prefs.remove('assigned_outlet_name');
            final shopsResp = await ApiClient().dio.get('/api/admin/shops');
            if (shopsResp.statusCode == 200 && shopsResp.data != null) {
              final List<dynamic> shops = shopsResp.data;
              if (shops.isNotEmpty) {
                await prefs.setString('selected_shop_id', shops.first['id'].toString());
              }
            }
          }
        } catch (_) {
          // Ignore if fetching shops fails, as they can manually select it later
        }

        return true;
      } else {
        throw 'Invalid User ID or Password. Please try again.';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw e.response?.data['detail'] ??
            'Invalid User ID or Password. Please try again.';
      }
      throw 'Unable to connect to the server. Please check your internet connection.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Unable to connect to the server. Please check your internet connection.';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove('assigned_outlet_id');
    await prefs.remove('assigned_outlet_name');
    await InventoryService.clearShopId();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }
}
