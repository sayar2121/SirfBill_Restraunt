import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../services/accounting_extended_service.dart';
import '../services/billing_service.dart';
import '../providers/counter_providers.dart';

class AccountsState {
  final List<TransactionModel> transactions;
  final List<String> categories;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double cashInHand;
  final double bankBalance;
  final double outstandingReceivables;

  AccountsState({
    this.transactions = const [],
    this.categories = const ['All Categories'],
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.cashInHand = 0,
    this.bankBalance = 0,
    this.outstandingReceivables = 0,
  });

  AccountsState copyWith({
    List<TransactionModel>? transactions,
    List<String>? categories,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    double? cashInHand,
    double? bankBalance,
    double? outstandingReceivables,
  }) {
    return AccountsState(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      cashInHand: cashInHand ?? this.cashInHand,
      bankBalance: bankBalance ?? this.bankBalance,
      outstandingReceivables:
          outstandingReceivables ?? this.outstandingReceivables,
    );
  }
}

class AccountsNotifier extends AsyncNotifier<AccountsState> {
  @override
  Future<AccountsState> build() async {
    final shopId = ref.watch(selectedShopIdProvider);
    return _fetchData(shopId: shopId);
  }

  Future<void> loadTransactions({
    String selectedPeriod = 'All Time',
    String selectedType = 'All Types',
    String selectedCategory = 'All Categories',
    String searchQuery = '',
  }) async {
    final shopId = ref.read(selectedShopIdProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchData(
        shopId: shopId,
        selectedPeriod: selectedPeriod,
        selectedType: selectedType,
        selectedCategory: selectedCategory,
        searchQuery: searchQuery,
      ),
    );
  }

  Future<AccountsState> _fetchData({
    String? shopId,
    String selectedPeriod = 'All Time',
    String selectedType = 'All Types',
    String selectedCategory = 'All Categories',
    String searchQuery = '',
  }) async {
    final allTxns = await TransactionService.getTransactions(shopId: shopId);

    // Sync POS sales from POS History into Accounts transactions
    try {
      final posHistory = await BillingService.getPosHistory();
      final historyList = posHistory['history'] as List? ?? [];
      final existingDescriptions = allTxns.map((t) => t.description.toLowerCase()).toSet();

      for (var item in historyList) {
        final billNo = item['bill_no']?.toString() ?? '';
        final custName = item['customer_name']?.toString() ?? 'Walk-in';
        final description = 'Sale - Invoice #$billNo ($custName)';

        // Only add if not already in the transactions list
        final alreadyExists = existingDescriptions.any((desc) => desc.contains(billNo.toLowerCase()));
        if (!alreadyExists && billNo.isNotEmpty) {
          existingDescriptions.add(description.toLowerCase());
          String dateStr = item['date']?.toString() ?? '';
          dateStr = dateStr.replaceAll(' ', 'T');
          if (!dateStr.endsWith('Z')) {
            dateStr += 'Z';
          }
          final dt = (DateTime.tryParse(dateStr) ?? DateTime.now()).toLocal();
          
          allTxns.add(
            TransactionModel(
              id: 'pos_${item['id'] ?? billNo}',
              date: DateFormat('dd MMM yyyy').format(dt),
              time: DateFormat('hh:mm a').format(dt),
              type: 'Income',
              category: 'Sales',
              description: description,
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              paymentMode: item['payment_mode']?.toString() ?? 'Cash',
              tenantId: shopId,
            ),
          );
        }
      }
    } catch (e) {
      // In case POS history fails, proceed with transactions
    }

    // Sort all transactions newest first
    final DateFormat dateFmt = DateFormat('dd MMM yyyy');
    allTxns.sort((a, b) {
      try {
        final dA = dateFmt.parse(a.date);
        final dB = dateFmt.parse(b.date);
        return dB.compareTo(dA);
      } catch (_) {
        return 0;
      }
    });

    // Dynamically build category list from all transactions
    final Set<String> catSet = {};
    for (var t in allTxns) {
      if (t.category.isNotEmpty) catSet.add(t.category);
    }
    final List<String> loadedCategories = [
      'All Categories',
      ...catSet.toList()..sort(),
    ];

    // Validate selected category
    String safeCategory = selectedCategory;
    if (!loadedCategories.contains(safeCategory)) {
      safeCategory = 'All Categories';
    }

    final now = DateTime.now();
    final DateFormat format = DateFormat('dd MMM yyyy');

    List<TransactionModel> filteredTxns = [];

    for (var txn in allTxns) {
      try {
        final txnDate = format.parse(txn.date);
        bool include = false;

        switch (selectedPeriod) {
          case 'Today':
            include =
                txnDate.year == now.year &&
                txnDate.month == now.month &&
                txnDate.day == now.day;
            break;
          case 'This Week':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            include = txnDate.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            );
            break;
          case 'This Month':
            include = txnDate.year == now.year && txnDate.month == now.month;
            break;
          case 'This Year':
            include = txnDate.year == now.year;
            break;
          case 'All Time':
          default:
            include = true;
            break;
        }

        if (include &&
            selectedType != 'All Types' &&
            txn.type != selectedType) {
          include = false;
        }

        if (include &&
            safeCategory != 'All Categories' &&
            txn.category != safeCategory) {
          include = false;
        }

        if (include && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!txn.description.toLowerCase().contains(query) &&
              !txn.category.toLowerCase().contains(query)) {
            include = false;
          }
        }

        if (include) {
          filteredTxns.add(txn);
        }
      } catch (e) {
        if (selectedType != 'All Types' && txn.type != selectedType) continue;
        if (safeCategory != 'All Categories' && txn.category != safeCategory) {
          continue;
        }
        filteredTxns.add(txn);
      }
    }

    double runningBal = 0.0;
    for (int i = filteredTxns.length - 1; i >= 0; i--) {
      final txn = filteredTxns[i];
      if (txn.type == 'Income') {
        runningBal += txn.amount;
      } else if (txn.type == 'Expense') {
        runningBal -= txn.amount;
      }
      txn.runningBalance = runningBal;
    }

    double calculatedIncome = 0.0;
    double calculatedExpenses = 0.0;

    for (var txn in filteredTxns) {
      if (txn.type == 'Income') {
        calculatedIncome += txn.amount;
      } else if (txn.type == 'Expense') {
        calculatedExpenses += txn.amount;
      }
    }

    final summary = await AccountService.getSummary(shopId: shopId);
    final receivablesData = await AccountingExtendedService.getReceivables();
    final totalReceivables =
        receivablesData['total_receivables']?.toDouble() ?? 0.0;

    return AccountsState(
      categories: loadedCategories,
      transactions: filteredTxns,
      totalIncome: calculatedIncome,
      totalExpenses: calculatedExpenses,
      netProfit: calculatedIncome - calculatedExpenses,
      cashInHand: summary.cashInHand,
      bankBalance: summary.bankBalance,
      outstandingReceivables: totalReceivables,
    );
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    await TransactionService.saveTransaction(data);
    await loadTransactions();
  }
}
