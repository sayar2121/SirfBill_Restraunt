import '../config/api_client.dart';

class AccountingExtendedService {
  static Future<Map<String, dynamic>> getReceivables() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/accounts/extended/receivables',
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return {"receivables": [], "total_receivables": 0.0};
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching receivables: $e');
      return {"receivables": [], "total_receivables": 0.0};
    }
  }

  static Future<Map<String, dynamic>> getPayables() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/accounts/extended/payables',
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return {"payables": [], "total_payables": 0.0};
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching payables: $e');
      return {"payables": [], "total_payables": 0.0};
    }
  }

  static Future<List<dynamic>> getLedger() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/accounts/extended/ledger',
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching ledger: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getPnL(
    String? startDate,
    String? endDate,
  ) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/accounts/extended/reports/pnl',
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return {"total_income": 0.0, "total_expense": 0.0, "net_profit": 0.0};
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching PnL: $e');
      return {"total_income": 0.0, "total_expense": 0.0, "net_profit": 0.0};
    }
  }
}
