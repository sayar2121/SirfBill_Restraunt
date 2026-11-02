import 'package:flutter/material.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/rack_service.dart';
import '../../../../services/category_service.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';
import 'inventory_row.dart';
import 'inventory_sortable_header.dart';

class InventoryTableWidget extends StatelessWidget {
  final List<InventoryItem> sortedItems;
  final List<Rack> racks;
  final List<Category> categories;
  final List<dynamic> distributors;
  final bool isDesktopWidth;
  final BoxConstraints screenConstraints;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final ScrollController headController;
  final ScrollController bodyController;
  final ScrollController horizontalController;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<InventoryItem> onEditItem;
  final ValueChanged<String> onDeleteItem;

  const InventoryTableWidget({
    super.key,
    required this.sortedItems,
    required this.racks,
    required this.categories,
    this.distributors = const [],
    required this.isDesktopWidth,
    required this.screenConstraints,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.headController,
    required this.bodyController,
    required this.horizontalController,
    required this.hasMore,
    required this.onLoadMore,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (sortedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'There is nothing in the inventory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Click "Add Item" or "Upload Inventory" above to add products.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED LEFT COLUMN
        SizedBox(
          width: isDesktopWidth ? 280 : 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 48,
                color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktopWidth ? 24 : 8,
                ),
                child: InventorySortableHeader(
                  title: 'Item Name',
                  sortColumn: sortColumn,
                  sortAscending: sortAscending,
                  onSort: onSort,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: headController,
                  itemCount: sortedItems.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    if (index == sortedItems.length) {
                      return const SizedBox(height: 80);
                    }
                    final item = sortedItems[index];
                    return InventoryRowLeftWidget(
                      item: item,
                      onTap: () => onEditItem(item),
                      isDesktopWidth: isDesktopWidth,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // SCROLLABLE RIGHT COLUMNS
        Expanded(
          child: HorizontalMouseTouchpadScroll(
            controller: horizontalController,
            child: Scrollbar(
              controller: horizontalController,
              thumbVisibility: true,
              thickness: 8,
              child: SingleChildScrollView(
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: isDesktopWidth
                      ? (screenConstraints.maxWidth - 64 - 280 > 1128
                          ? screenConstraints.maxWidth - 64 - 280
                          : 1128)
                      : (screenConstraints.maxWidth - 64 - 140 > 1096
                          ? screenConstraints.maxWidth - 64 - 140
                          : 1096),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 48,
                        color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktopWidth ? 24 : 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 120,
                              child: InventorySortableHeader(
                                title: 'Category',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 120,
                              child: InventorySortableHeader(
                                title: 'Added/Updated',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 100,
                              child: InventorySortableHeader(
                                title: 'Stock',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 80,
                              child: InventorySortableHeader(
                                title: 'Rack',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 100,
                              child: InventorySortableHeader(
                                title: 'Buying Price',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 100,
                              child: InventorySortableHeader(
                                title: 'Price (₹)',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 80,
                              child: InventorySortableHeader(
                                title: 'GST (%)',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 120,
                              child: InventorySortableHeader(
                                title: 'Distributor',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 100,
                              child: InventorySortableHeader(
                                title: 'Expiry Date',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            Expanded(
                              flex: 120,
                              child: InventorySortableHeader(
                                title: 'Status',
                                sortColumn: sortColumn,
                                sortAscending: sortAscending,
                                onSort: onSort,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: bodyController,
                          itemCount: sortedItems.length + 1,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            if (index == sortedItems.length) {
                              if (hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: onLoadMore,
                                      child: const Text('Load More'),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(height: 80);
                            }

                            final item = sortedItems[index];
                            final rackName = racks
                                .firstWhere(
                                  (r) => r.id == item.rackId,
                                  orElse: () => Rack(id: '', rackNumber: '-'),
                                )
                                .rackNumber;
                            final categoryName = categories
                                .firstWhere(
                                  (c) => c.id == item.categoryId,
                                  orElse: () => Category(id: '', name: 'N/A'),
                                )
                                .name;
                            final distMatch = distributors.firstWhere(
                              (d) =>
                                  d['id']?.toString() ==
                                  item.distributorId?.toString(),
                              orElse: () => null,
                            );
                            final distributorName = (item.distributor != null &&
                                    item.distributor!.isNotEmpty)
                                ? item.distributor
                                : distMatch?['name']?.toString();

                            return InventoryRowRightWidget(
                              item: item,
                              rackName: rackName,
                              categoryName: categoryName,
                              distributorName: distributorName,
                              onTap: () => onEditItem(item),
                              onEdit: () => onEditItem(item),
                              onDelete: () => onDeleteItem(item.id),
                              isDesktopWidth: isDesktopWidth,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
