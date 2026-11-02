import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../notifiers/accounts_notifier.dart';
import '../../services/export_service.dart';
import '../../services/transaction_service.dart';

import 'widgets/accounts/receivables_view.dart';
import 'widgets/accounts/payables_view.dart';
import 'widgets/accounts/accounts_header.dart';
import 'widgets/accounts/accounts_summary_cards.dart';
import 'widgets/accounts/accounts_tabs_card.dart';
import 'widgets/accounts/accounts_right_panel.dart';
import 'widgets/accounts/transactions_view.dart';
import 'widgets/accounts/add_transaction_dialog.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  int _activeTab = 0;
  final List<String> _tabs = const [
    'Transactions',
    'Receivables (Credit)',
    'Payables',
  ];

  String _selectedPeriod = 'All Time';
  String _selectedType = 'All Types';
  String _selectedCategory = 'All Categories';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  AccountsState get _state =>
      ref.watch(accountsProvider).value ?? AccountsState();
  List<TransactionModel> get _transactions => _state.transactions;
  List<String> get _categories => _state.categories;
  double get _totalIncome => _state.totalIncome;
  double get _totalExpenses => _state.totalExpenses;
  double get _netProfit => _state.netProfit;
  double get _cashInHand => _state.cashInHand;
  double get _bankBalance => _state.bankBalance;
  double get _outstandingReceivables => _state.outstandingReceivables;
  bool get _isLoading => ref.watch(accountsProvider).isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    ref.read(accountsProvider.notifier).loadTransactions(
      selectedPeriod: _selectedPeriod,
      selectedType: _selectedType,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  void _onFilterChanged({
    String? period,
    String? type,
    String? category,
    String? query,
  }) {
    setState(() {
      if (period != null) _selectedPeriod = period;
      if (type != null) _selectedType = type;
      if (category != null) _selectedCategory = category;
      if (query != null) _searchQuery = query;
    });
    _loadTransactions();
  }

  void _onResetFilters() {
    setState(() {
      _selectedPeriod = 'All Time';
      _selectedType = 'All Types';
      _selectedCategory = 'All Categories';
      _searchController.clear();
      _searchQuery = '';
    });
    _loadTransactions();
  }

  Future<void> _exportData(String format) async {
    final exportData = _transactions
        .map(
          (t) => {
            'Date': '${t.date} ${t.time}',
            'Description': t.description,
            'Category': t.category,
            'Type': t.type,
            'Amount': t.amount,
            'Running Balance': t.runningBalance,
            'Payment Mode': t.paymentMode,
          },
        )
        .toList();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'accounts_$timestamp';

    try {
      if (format == 'pdf') {
        await ExportService.exportToPDF(exportData, filename);
      } else if (format == 'excel') {
        await ExportService.exportToExcel(exportData, filename);
      } else if (format == 'csv') {
        await ExportService.exportToCSV(exportData, filename);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 1000;

          final Widget leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountsHeader(
                onExport: _exportData,
                onRefresh: _loadTransactions,
                onAddTransaction: () => showAddTransactionDialog(
                  context,
                  onSuccess: _loadTransactions,
                ),
              ),
              const SizedBox(height: 24),
              AccountsSummaryCards(
                totalIncome: _totalIncome,
                totalExpenses: _totalExpenses,
                netProfit: _netProfit,
                outstandingReceivables: _outstandingReceivables,
              ),
              const SizedBox(height: 24),
              AccountsTabsCard(
                activeTab: _activeTab,
                tabs: _tabs,
                onTabChanged: (index) => setState(() => _activeTab = index),
                child: _activeTab == 0
                    ? TransactionsView(
                        transactions: _transactions,
                        categories: _categories,
                        isLoading: _isLoading,
                        selectedPeriod: _selectedPeriod,
                        selectedType: _selectedType,
                        selectedCategory: _selectedCategory,
                        searchQuery: _searchQuery,
                        searchController: _searchController,
                        onFilterChanged: _onFilterChanged,
                        onResetFilters: _onResetFilters,
                        onRefresh: _loadTransactions,
                      )
                    : _activeTab == 1
                        ? const ReceivablesView()
                        : const PayablesView(),
              ),
            ],
          );

          final Widget rightSidebar = AccountsRightPanel(
            cashInHand: _cashInHand,
            bankBalance: _bankBalance,
            totalIncome: _totalIncome,
            totalExpenses: _totalExpenses,
            netProfit: _netProfit,
            recentTransactions: _transactions,
          );

          if (isDesktop) {
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: leftColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: rightSidebar),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 24),
                  rightSidebar,
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
