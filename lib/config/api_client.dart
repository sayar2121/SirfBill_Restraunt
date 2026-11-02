import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/app_router.dart' as import_router;
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Only attach backend JWT Authorization token to backend requests, never to external URLs like GitHub
          final baseUri = Uri.tryParse(ApiConstants.baseUrl);
          final reqHost = options.uri.host;
          final isBackend = reqHost.isEmpty ||
              (baseUri != null && reqHost == baseUri.host) ||
              reqHost.contains('192.168.') ||
              reqHost.contains('127.0.0.1') ||
              reqHost.contains('localhost') ||
              reqHost.contains('naiyo24.com') ||
              reqHost.contains('vwings247.me');

          if (isBackend) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Centralized error logging
          // ignore: avoid_print
          print(
            'API Error [${e.response?.statusCode}]: ${e.requestOptions.path}',
          );
          // ignore: avoid_print
          print('Response Data: ${e.response?.data}');
          // ignore: avoid_print
          print('Message: ${e.message}');

          final baseUri = Uri.tryParse(ApiConstants.baseUrl);
          final reqHost = e.requestOptions.uri.host;
          final isBackend = reqHost.isEmpty ||
              (baseUri != null && reqHost == baseUri.host) ||
              reqHost.contains('192.168.') ||
              reqHost.contains('127.0.0.1') ||
              reqHost.contains('localhost') ||
              reqHost.contains('naiyo24.com') ||
              reqHost.contains('vwings247.me');

          if (isBackend && e.response?.statusCode == 401 && !e.requestOptions.path.contains('auth')) {
            // ignore: avoid_print
            print(
              'Unauthorized: Token expired or invalid. Logging out and redirecting.',
            );
            
            // Clear auth data and redirect
            SharedPreferences.getInstance().then((prefs) {
              prefs.remove('access_token');
              prefs.remove('user_id');
              prefs.remove('user_role');
              prefs.remove('selected_shop_id');
            });

            // Need to import goRouter from app_router.dart to navigate
            try {
              // We'll import app_router at the top of the file
              import_router.goRouter.go('/dashboard');
            } catch (_) {}
          }

          return handler.next(e);
        },
      ),
    );

    // Add PrettyDioLogger for debugging
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: false, // Set to false to avoid printing huge binary arrays
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }
}
