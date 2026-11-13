import 'package:flutter/material.dart';
import '../../../../services/transaction_service.dart';
import '../../../../widgets/custom_pagination.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';
import 'transactions_table_components.dart';

class TransactionsView extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<String> categories;
  final bool isLoading;
  final String selectedPeriod;
  final String selectedType;
  final String selectedCategory;
  final String searchQuery;
  final TextEditingController searchController;
  final Function({
    String? period,
    String? type,
    String? category,
    String? query,
  }) onFilterChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onRefresh;

  const TransactionsView({
    super.key,
    required this.transactions,
    required this.categories,
    required this.isLoading,
    required this.selectedPeriod,
    required this.selectedType,
    required this.selectedCategory,
    required this.searchQuery,
    required this.searchController,
    required this.onFilterChanged,
    required this.onResetFilters,
    required this.onRefresh,
  });

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  late final ScrollController _tableHorizontalController;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final List<String> _periods = const [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  final List<String> _types = const [
    'All Types',
    'Income',
    'Expense',
  ];

  @override
  void initState() {
    super.initState();
    _tableHorizontalController = ScrollController();
  }

  @override
  void dispose() {
    _tableHorizontalController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, TransactionModel txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await TransactionService.deleteTransaction(txn.id);
              widget.onRefresh();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRecords = widget.transactions.length;
    final totalPages = (totalRecords / _itemsPerPage).ceil() == 0
        ? 1
        : (totalRecords / _itemsPerPage).ceil();

    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _itemsPerPage;
    final endIdx = (startIdx + _itemsPerPage > totalRecords)
        ? totalRecords
        : startIdx + _itemsPerPage;
    final pagedTxns = widget.transactions.isNotEmpty
        ? widget.transactions.sublist(startIdx, endIdx)
        : <TransactionModel>[];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 1. Filters Bar
        TransactionFilterBar(
          selectedPeriod: widget.selectedPeriod,
          selectedType: widget.selectedType,
          selectedCategory: widget.selectedCategory,
          periods: _periods,
          types: _types,
          categories: widget.categories,
          searchController: widget.searchController,
          onFilterChanged: ({category, period, query, type}) {
            setState(() => _currentPage = 1);
            widget.onFilterChanged(
              category: category,
              period: period,
              query: query,
              type: type,
            );
          },
          onResetFilters: () {
            setState(() => _currentPage = 1);
            widget.onResetFilters();
          },
        ),

        // 2. Transactions Table
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth > 800
                ? constraints.maxWidth
                : 800.0;

            return HorizontalMouseTouchpadScroll(
              controller: _tableHorizontalController,
              child: SingleChildScrollView(
                controller: _tableHorizontalController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table Headers
                      const TransactionTableHeader(),

                      // Table Body
                      if (widget.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (pagedTxns.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No transactions found. Add one to get started!',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedTxns.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final txn = pagedTxns[index];
                            final globalIndex = startIdx + index + 1;
                            return TransactionTableRowTile(
                              txn: txn,
                              globalIndex: globalIndex,
                              onDelete: () => _confirmDelete(context, txn),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // 3. Pagination Bar
        if (totalRecords > 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Text(
                  'Showing ${startIdx + 1} to $endIdx of $totalRecords records',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                    fontSize: 12,
                  ),
                ),
                CustomPagination(
                  currentPage: safePage,
                  totalPages: totalPages,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
