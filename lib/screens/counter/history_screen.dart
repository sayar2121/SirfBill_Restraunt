import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../services/billing_history_service.dart';

import 'widgets/history/history_header.dart';
import 'widgets/history/history_stats_cards.dart';
import 'widgets/history/history_filter_bar.dart';
import 'widgets/history/history_table.dart';
import 'widgets/history/history_export_helper.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _activeDateRange = 'Today';
  String _selectedType = 'All';
  String _selectedPaymentMode = 'All';
  String _searchQuery = '';
  int _currentPage = 1;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).reloadHistory();
    });
    BillingHistoryService.historyUpdated.addListener(_onHistoryUpdated);
  }

  void _onHistoryUpdated() {
    ref.read(historyProvider.notifier).reloadHistory();
  }

  @override
  void dispose() {
    BillingHistoryService.historyUpdated.removeListener(_onHistoryUpdated);
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredTransactions(
    List<Map<String, dynamic>> allTransactions, {
    String? overrideDateRange,
  }) {
    return HistoryExportHelper.filterTransactions(
      allTransactions,
      activeDateRange: _activeDateRange,
      selectedType: _selectedType,
      selectedPaymentMode: _selectedPaymentMode,
      searchQuery: _searchQuery,
      customDateRange: _customDateRange,
      overrideDateRange: overrideDateRange,
    );
  }

  void _resetFilters() {
    setState(() {
      _activeDateRange = 'Today';
      _selectedType = 'All';
      _selectedPaymentMode = 'All';
      _searchQuery = '';
      _currentPage = 1;
      _customDateRange = null;
    });
  }

  void _handleExportSelected(
    String value,
    List<Map<String, dynamic>> allTransactions,
  ) {
    final parts = value.split('_');
    final format = parts[0];
    final action = parts[1];

    List<Map<String, dynamic>> targetData;
    if (action == 'All') {
      targetData = allTransactions;
    } else if (action == 'Filtered') {
      targetData = _filteredTransactions(allTransactions);
    } else {
      final dateRangeMap = {
        'Today': 'Today',
        'Week': 'This Week',
        'Month': 'This Month',
        'Year': 'This Year',
      };
      final dateRange = dateRangeMap[action];
      targetData = _filteredTransactions(
        allTransactions,
        overrideDateRange: dateRange,
      );
    }

    if (format == 'Excel') {
      HistoryExportHelper.exportToExcel(context, targetData);
    } else {
      HistoryExportHelper.exportToPdf(context, targetData);
    }
  }

  void _viewBill(SavedBill bill) async {
    Map<String, dynamic> shopSettings = {};
    final settingsAsync = ref.read(settingsProvider);
    if (settingsAsync.value != null) {
      shopSettings = settingsAsync.value!;
    } else {
      try {
        shopSettings = await ref.read(settingsProvider.future);
      } catch (_) {
        shopSettings = {};
      }
    }

    if (!mounted) return;
    HistoryExportHelper.viewBill(context, bill, shopSettings);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (historyState) {
        final filtered = _filteredTransactions(historyState.transactions);
        const int itemsPerPage = 10;
        final int totalRecords = filtered.length;
        final int totalPages = (totalRecords / itemsPerPage).ceil() == 0
            ? 1
            : (totalRecords / itemsPerPage).ceil();

        final int startIdx = (_currentPage - 1) * itemsPerPage;
        final int endIdx = (startIdx + itemsPerPage > totalRecords)
            ? totalRecords
            : startIdx + itemsPerPage;
        final pagedTransactions = filtered.isNotEmpty
            ? filtered.sublist(startIdx, endIdx)
            : <Map<String, dynamic>>[];

        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                HistoryHeader(
                  onRefresh: () =>
                      ref.read(historyProvider.notifier).reloadHistory(),
                  onExportSelected: (val) =>
                      _handleExportSelected(val, historyState.transactions),
                ),
                const SizedBox(height: 24),

                // Stats Cards
                HistoryStatsRow(filtered: filtered),
                const SizedBox(height: 24),

                // Filters Row
                HistoryFilterBar(
                  activeDateRange: _activeDateRange,
                  selectedType: _selectedType,
                  selectedPaymentMode: _selectedPaymentMode,
                  customDateRange: _customDateRange,
                  onDateRangeChanged: (val) => setState(() {
                    _activeDateRange = val;
                    _currentPage = 1;
                  }),
                  onCustomDateRangeChanged: (val) => setState(() {
                    _customDateRange = val;
                  }),
                  onTypeChanged: (val) => setState(() {
                    _selectedType = val;
                    _currentPage = 1;
                  }),
                  onPaymentModeChanged: (val) => setState(() {
                    _selectedPaymentMode = val;
                    _currentPage = 1;
                  }),
                  onSearchChanged: (val) => setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  }),
                  onReset: _resetFilters,
                ),
                const SizedBox(height: 16),

                // Data Table
                HistoryTable(
                  pagedTransactions: pagedTransactions,
                  totalRecords: totalRecords,
                  totalPages: totalPages,
                  currentPage: _currentPage,
                  startIdx: startIdx,
                  endIdx: endIdx,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  onViewBill: (bill) => _viewBill(bill as SavedBill),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
