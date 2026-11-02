import '../config/api_client.dart';
import 'package:intl/intl.dart';
import 'inventory_service.dart';

class TransactionModel {
  final String id;
  final String date;
  final String time;
  final String type; // 'INCOME', 'EXPENSE', 'TRANSFER'
  final String category;
  final String description;
  final double amount;
  final String paymentMode;
  double runningBalance = 0.0; // Initialized to prevent null errors
  final String? tenantId;

  TransactionModel({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
    this.runningBalance = 0.0,
    this.tenantId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String parsedDate = '';
    String parsedTime = '';

    if (json['date'] != null) {
      try {
        final rawStr = json['date'].toString();
        // If the date string has no timezone specified, parse it or treat as UTC if needed, then convert to local
        DateTime dt = DateTime.parse(rawStr);
        if (!dt.isUtc && rawStr.endsWith('Z')) {
          dt = dt.toUtc();
        }
        final localDt = dt.toLocal();
        parsedDate = DateFormat('dd MMM yyyy').format(localDt);
        parsedTime = DateFormat('hh:mm a').format(localDt);
      } catch (e) {
        parsedDate = json['date'];
      }
    }

    String categoryName = '';
    if (json['category'] != null && json['category'] is Map) {
      categoryName = json['category']['name'] ?? '';
    }

    String txnType = json['transaction_type'] ?? '';
    if (txnType.toUpperCase() == 'INCOME') {
      txnType = 'Income';

    } else if (txnType.toUpperCase() == 'EXPENSE') {
      txnType = 'Expense';
    } else if (txnType.toUpperCase() == 'TRANSFER') {
      txnType = 'Transfer';
    }

    return TransactionModel(
      id: json['id'] ?? '',
      date: parsedDate,
      time: parsedTime,
      type: txnType,
      category: categoryName,
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMode:
          'Cash', // Defaulting as backend doesn't seem to store it explicitly unless we use accounts
      tenantId: json['tenant_id'],
    );
  }
}

class TransactionService {
  static Future<void> saveTransaction(Map<String, dynamic> payload) async {
    try {
      final shopId = await InventoryService.getShopId();
      payload['tenant_id'] = shopId;
      payload['shop_id'] = shopId;
      final response = await ApiClient().dio.post(
        '/api/transactions',
        data: payload,
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw 'Failed to create transaction';
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<TransactionModel>> getTransactions({
    int skip = 0,
    int limit = 100,
    String? shopId,
  }) async {
    try {
      final actualShopId = shopId ?? await InventoryService.getShopId();
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'shop_id': actualShopId,
        'tenant_id': actualShopId,
      };
      
      final response = await ApiClient().dio.get(
        '/api/transactions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw 'Failed to load transactions';
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteTransaction(String id) async {
    try {
      final response = await ApiClient().dio.delete('/api/transactions/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw 'Failed to delete transaction';
      }
    } catch (e) {
      rethrow;
    }
  }
}
