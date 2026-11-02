import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/transaction_service.dart';
import '../../../../widgets/custom_pagination.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';
import 'accounts_common_widgets.dart';

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

  String _fmt(double val) =>
      NumberFormat.currency(symbol: '₹ ', decimalDigits: 2).format(val);

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await TransactionService.deleteTransaction(txn.id);
              widget.onRefresh();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
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
        // Filters Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AccountsWidgets.buildDynamicDropdown(
                context,
                widget.selectedPeriod,
                _periods,
                (String? newValue) {
                  if (newValue != null) {
                    setState(() => _currentPage = 1);
                    widget.onFilterChanged(period: newValue);
                  }
                },
              ),
              AccountsWidgets.buildDynamicDropdown(
                context,
                widget.selectedType,
                _types,
                (String? newValue) {
                  if (newValue != null) {
                    setState(() => _currentPage = 1);
                    widget.onFilterChanged(type: newValue);
                  }
                },
              ),
              AccountsWidgets.buildDynamicDropdown(
                context,
                widget.selectedCategory,
                widget.categories,
                (String? newValue) {
                  if (newValue != null) {
                    setState(() => _currentPage = 1);
                    widget.onFilterChanged(category: newValue);
                  }
                },
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 350,
                  minWidth: 200,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search,
                        size: 18,
                        color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                      ),
                      hintText: 'Search by description, customer, invoice no...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() => _currentPage = 1);
                      widget.onFilterChanged(query: value);
                    },
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  widget.onResetFilters();
                },
                icon: Icon(
                  Icons.refresh,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                label: Text(
                  'Reset',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transactions Table
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Debit (₹)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Credit (₹)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Balance (₹)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Action',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Body
                      if (widget.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '$globalIndex',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          txn.date,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          txn.time,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: txn.type == 'Income'
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                txn.type == 'Income'
                                                    ? Icons.arrow_outward
                                                    : Icons.arrow_downward,
                                                size: 12,
                                                color: txn.type == 'Income'
                                                    ? const Color(0xFF166534)
                                                    : const Color(0xFFB91C1C),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                txn.type,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: txn.type == 'Income'
                                                      ? const Color(0xFF166534)
                                                      : const Color(0xFFB91C1C),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      txn.category,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      txn.description,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      txn.type == 'Expense'
                                          ? _fmt(txn.amount)
                                          : '-',
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      txn.type == 'Income'
                                          ? _fmt(txn.amount)
                                          : '-',
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      _fmt(txn.runningBalance),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_red_eye_outlined,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          onPressed: () {
                                            AccountsWidgets
                                                .showTransactionDetails(
                                              context,
                                              txn,
                                            );
                                          },
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          onPressed: () =>
                                              _confirmDelete(context, txn),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

        // Pagination Bar
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
