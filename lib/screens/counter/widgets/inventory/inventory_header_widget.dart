import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InventoryHeaderWidget extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> shopsAsync;
  final String? selectedShopId;
  final ValueChanged<String?> onShopChanged;
  final VoidCallback onRetryShops;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String selectedDateFilter;
  final ValueChanged<String> onDateFilterChanged;
  final Function(String column, bool ascending) onSortSelected;
  final ValueChanged<String> onExportSelected;
  final VoidCallback onRefresh;

  const InventoryHeaderWidget({
    super.key,
    required this.shopsAsync,
    required this.selectedShopId,
    required this.onShopChanged,
    required this.onRetryShops,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedDateFilter,
    required this.onDateFilterChanged,
    required this.onSortSelected,
    required this.onExportSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      color: Colors.transparent,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  children: const [
                    TextSpan(text: 'Item '),
                    TextSpan(
                      text: 'Inventory',
                      style: TextStyle(color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your item stock, expiry, and availability in one place.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Shop Dropdown
              shopsAsync.when(
                data: (shops) {
                  if (shops.isEmpty) return const SizedBox();
                  return Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (() {
                          final id = selectedShopId ??
                              (shops.isNotEmpty ? shops.first['id'].toString() : null);
                          if (id != null &&
                              shops.any((shop) => shop['id'].toString() == id)) {
                            return id;
                          }
                          return shops.isNotEmpty
                              ? shops.first['id'].toString()
                              : null;
                        })(),
                        icon: Icon(
                          Icons.store,
                          size: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        onChanged: onShopChanged,
                        items: shops.map((shop) {
                          return DropdownMenuItem<String>(
                            value: shop['id'].toString(),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(shop['name'] ?? 'Unknown Shop'),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, stack) => IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  tooltip: 'Retry',
                  onPressed: onRetryShops,
                ),
              ),

              // Search Bar
              Container(
                width: 320,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onSubmitted: onSearchSubmitted,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Search anything (name, brand, barcode, batch, rack, HSN)...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return InkWell(
                          onTap: onClearSearch,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Date Filter Dropdown
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDateFilter,
                    icon: Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    onChanged: (value) {
                      if (value != null) onDateFilterChanged(value);
                    },
                    items: [
                      'All Time',
                      'Today',
                      'This Week',
                      'This Month',
                      'This Year',
                      'Custom Range',
                    ].map(
                      (filter) => DropdownMenuItem(
                        value: filter,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(filter),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),

              // Sort By Dropdown
              PopupMenuButton<String>(
                onSelected: (value) {
                  final parts = value.split('|');
                  onSortSelected(parts[0], parts[1] == 'asc');
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort By',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Item Name|asc',
                    child: Text('Item Name (A-Z)'),
                  ),
                  const PopupMenuItem(
                    value: 'Item Name|desc',
                    child: Text('Item Name (Z-A)'),
                  ),
                  const PopupMenuItem(
                    value: 'Added/Updated|desc',
                    child: Text('Added/Updated (Newest First)'),
                  ),
                  const PopupMenuItem(
                    value: 'Added/Updated|asc',
                    child: Text('Added/Updated (Oldest First)'),
                  ),
                  const PopupMenuItem(
                    value: 'Stock|asc',
                    child: Text('Stock (Low to High)'),
                  ),
                  const PopupMenuItem(
                    value: 'Stock|desc',
                    child: Text('Stock (High to Low)'),
                  ),
                  const PopupMenuItem(
                    value: 'Price (₹)|asc',
                    child: Text('Price (Low to High)'),
                  ),
                  const PopupMenuItem(
                    value: 'Price (₹)|desc',
                    child: Text('Price (High to Low)'),
                  ),
                  const PopupMenuItem(
                    value: 'Expiry Date|asc',
                    child: Text('Expiry Date (Earliest First)'),
                  ),
                  const PopupMenuItem(
                    value: 'Expiry Date|desc',
                    child: Text('Expiry Date (Latest First)'),
                  ),
                ],
              ),

              // Export Button
              PopupMenuButton<String>(
                onSelected: onExportSelected,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'CSV',
                    child: Text('Export as CSV'),
                  ),
                  const PopupMenuItem(
                    value: 'Excel',
                    child: Text('Export as Excel'),
                  ),
                  const PopupMenuItem(
                    value: 'PDF',
                    child: Text('Export as PDF'),
                  ),
                ],
              ),

              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                tooltip: 'Refresh',
              ),

              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/counter/inventory/upload'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add New Item',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
