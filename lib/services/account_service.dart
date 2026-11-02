import '../config/api_client.dart';
import 'inventory_service.dart';

class AccountSummaryModel {
  final double cashInHand;
  final double bankBalance;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  AccountSummaryModel({
    required this.cashInHand,
    required this.bankBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory AccountSummaryModel.fromJson(Map<String, dynamic> json) {
    return AccountSummaryModel(
      cashInHand: (json['cash_in_hand'] ?? 0.0).toDouble(),
      bankBalance: (json['bank_balance'] ?? 0.0).toDouble(),
      totalIncome: (json['total_income'] ?? 0.0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
      netProfit: (json['net_profit'] ?? 0.0).toDouble(),
    );
  }
}

class AccountModel {
  final String id;
  final String name;
  final String accountType;
  final double balance;
  final String? tenantId;

  AccountModel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balance,
    this.tenantId,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      accountType: json['account_type'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      tenantId: json['tenant_id'],
    );
  }
}

class AccountService {
  static Future<AccountSummaryModel> getSummary({String? shopId}) async {
    try {
      final actualShopId = shopId ?? await InventoryService.getShopId();
      final queryParams = {'shop_id': actualShopId, 'tenant_id': actualShopId};
      final response = await ApiClient().dio.get('/api/accounts/summary', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return AccountSummaryModel.fromJson(response.data);
      } else {
        throw 'Failed to load account summary';
      }
    } catch (e) {
      // Fallback default values if API fails
      return AccountSummaryModel(
        cashInHand: 0.0,
        bankBalance: 0.0,
        totalIncome: 0.0,
        totalExpenses: 0.0,
        netProfit: 0.0,
      );
    }
  }

  static Future<List<AccountModel>> getAccounts({String? shopId}) async {
    try {
      final actualShopId = shopId ?? await InventoryService.getShopId();
      final response = await ApiClient().dio.get(
        '/api/accounts',
        queryParameters: {'shop_id': actualShopId, 'tenant_id': actualShopId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AccountModel.fromJson(json)).toList();
      } else {
        throw 'Failed to load accounts';
      }
    } catch (e) {
      return [];
    }
  }
}
