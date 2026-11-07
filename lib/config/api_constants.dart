import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static String? _overriddenBaseUrl;

  /// Loads custom server URL saved by user in local storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_server_url');
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _overriddenBaseUrl = customUrl.trim();
    }
  }

  /// Sets and persists a custom server URL
  static Future<void> setCustomBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove('custom_server_url');
      _overriddenBaseUrl = null;
    } else {
      await prefs.setString('custom_server_url', trimmed);
      _overriddenBaseUrl = trimmed;
    }
  }

  static String get baseUrl {
    // 1. User-customized server IP or domain saved locally on this machine
    if (_overriddenBaseUrl != null && _overriddenBaseUrl!.isNotEmpty) {
      return _overriddenBaseUrl!;
    }

    // 2. Build-time argument (if supplied via --dart-define)
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // 3. DotEnv configuration (.env)
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }

    // 4. Default fallback
    return 'http://127.0.0.1:8000';
  }
}
