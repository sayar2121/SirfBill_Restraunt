import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/counter_providers.dart';
import '../../providers/distributor_provider.dart';
import '../../services/inventory_service.dart';
import '../../widgets/custom_date_range_picker.dart';

import 'widgets/inventory/inventory_dialogs.dart';
import 'widgets/inventory/inventory_header_widget.dart';
import 'widgets/inventory/inventory_table_widget.dart';
import 'widgets/inventory/inventory_export_helper.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  late final ScrollController _headController;
  late final ScrollController _bodyController;
  late final ScrollController _horizontalController;
  bool _isSyncingScroll = false;

  String _selectedDateFilter = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  String _sortColumn = 'Item Name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _headController = ScrollController();
    _bodyController = ScrollController();
    _horizontalController = ScrollController();

    _headController.addListener(_onHeadScrolled);
    _bodyController.addListener(_onBodyScrolled);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _onHeadScrolled() {
    if (_isSyncingScroll) return;
    if (!_headController.hasClients || !_bodyController.hasClients) return;
    if (_headController.positions.length != 1 ||
        _bodyController.positions.length != 1) {
      return;
    }
    final offset = _headController.offset;
    if ((_bodyController.offset - offset).abs() > 0.5) {
      _isSyncingScroll = true;
      _bodyController.jumpTo(offset);
      _isSyncingScroll = false;
    }
  }

  void _onBodyScrolled() {
    if (_isSyncingScroll) return;
    if (!_headController.hasClients || !_bodyController.hasClients) return;
    if (_headController.positions.length != 1 ||
        _bodyController.positions.length != 1) {
      return;
    }
    final offset = _bodyController.offset;
    if ((_headController.offset - offset).abs() > 0.5) {
      _isSyncingScroll = true;
      _headController.jumpTo(offset);
      _isSyncingScroll = false;
    }
  }

  Future<void> _fetchData([String? query]) async {
    ref.read(inventoryProvider.notifier).loadInventory(
          searchQuery: query ?? _searchController.text,
          startDate: _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
          endDate: _endDate != null
              ? DateFormat('yyyy-MM-dd').format(_endDate!)
              : null,
        );
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => CustomDateRangePicker(
        initialRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDateFilter = 'Custom Range';
      });
      _fetchData();
    }
  }

  void _onDateFilterChanged(String filter) {
    setState(() {
      _selectedDateFilter = filter;
      final now = DateTime.now();
      switch (filter) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate;
          break;
        case 'This Week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
    if (filter != 'Custom Range') {
      _fetchData();
    } else {
      _selectDateRange();
    }
  }

  void _exportData(String format) {
    final items = ref.read(inventoryProvider).value ?? [];
    final racks = ref.read(rackProvider).value ?? [];
    final categories = ref.read(categoryProvider).value ?? [];
    final distributors = ref.read(distributorsProvider).value ?? [];
    final settings = ref.read(settingsProvider).value ?? {};

    InventoryExportHelper.exportData(
      context: context,
      format: format,
      items: items,
      racks: racks,
      categories: categories,
      distributors: distributors,
      settings: settings,
    );
  }

  Future<void> _confirmDeleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await InventoryService.deleteItem(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData(_searchController.text);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditItemDialog(InventoryItem item) {
    InventoryDialogs.showEditItemDialog(
      context,
      ref,
      item,
      () => _fetchData(),
    );
  }

  Widget _buildConditionalWrapper(bool isShort, Widget child) {
    return isShort
        ? SizedBox(height: 800, child: child)
        : Expanded(child: child);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _headController.removeListener(_onHeadScrolled);
    _bodyController.removeListener(_onBodyScrolled);
    _headController.dispose();
    _bodyController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final shopsAsync = ref.watch(shopProvider);
    final selectedShopId = ref.watch(selectedShopIdProvider);
    final racks = ref.watch(rackProvider).value ?? [];
    final categories = ref.watch(categoryProvider).value ?? [];
    final distributors = ref.watch(distributorsProvider).value ?? [];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, screenConstraints) {
          bool isScreenShort = screenConstraints.maxHeight < 850 ||
              screenConstraints.maxWidth < 1000;
          final isDesktopWidth = screenConstraints.maxWidth >= 1000;

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header
              InventoryHeaderWidget(
                shopsAsync: shopsAsync,
                selectedShopId: selectedShopId,
                onShopChanged: (String? newShopId) async {
                  if (newShopId != null && newShopId != selectedShopId) {
                    ref
                        .read(selectedShopIdProvider.notifier)
                        .updateShopId(newShopId);
                    await InventoryService.setShopId(newShopId);
                    ref.invalidate(rackProvider);
                    ref.invalidate(categoryProvider);
                    _fetchData();
                  }
                },
                onRetryShops: () =>
                    ref.read(inventoryProvider.notifier).loadInventory(),
                searchController: _searchController,
                onSearchChanged: (value) {
                  if (_searchDebounce?.isActive ?? false) {
                    _searchDebounce!.cancel();
                  }
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 350), () {
                    _fetchData(value);
                  });
                },
                onSearchSubmitted: (value) {
                  _searchDebounce?.cancel();
                  _fetchData(value);
                },
                onClearSearch: () {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  _fetchData('');
                },
                selectedDateFilter: _selectedDateFilter,
                onDateFilterChanged: _onDateFilterChanged,
                onSortSelected: (column, ascending) {
                  setState(() {
                    _sortColumn = column;
                    _sortAscending = ascending;
                  });
                },
                onExportSelected: _exportData,
                onRefresh: () => _fetchData(),
              ),

              // List Content
              _buildConditionalWrapper(
                isScreenShort,
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: inventoryAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                err.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(inventoryProvider.notifier)
                                    .loadInventory(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Center(
                              child: Text(
                                'No shop found or inventory is empty.',
                              ),
                            );
                          }

                          final sortedItems = InventoryExportHelper.sortItems(
                            items,
                            _sortColumn,
                            _sortAscending,
                          );

                          return InventoryTableWidget(
                            sortedItems: sortedItems,
                            racks: racks,
                            categories: categories,
                            distributors: distributors,
                            isDesktopWidth: isDesktopWidth,
                            screenConstraints: screenConstraints,
                            sortColumn: _sortColumn,
                            sortAscending: _sortAscending,
                            onSort: _onSort,
                            headController: _headController,
                            bodyController: _bodyController,
                            horizontalController: _horizontalController,
                            hasMore: ref
                                .read(inventoryProvider.notifier)
                                .hasMore,
                            onLoadMore: () => ref
                                .read(inventoryProvider.notifier)
                                .loadMore(),
                            onEditItem: _showEditItemDialog,
                            onDeleteItem: _confirmDeleteItem,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

          return isScreenShort
              ? SingleChildScrollView(child: content)
              : content;
        },
      ),
    );
  }
}
