import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../utils/format_utils.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';
import 'billing_dialogs.dart';
class BillingLeftPanel extends ConsumerStatefulWidget {
  final bool isDesktopWidth;
  final bool hasEnoughHeight;
  final List<Map<String, dynamic>> filteredItems;
  final List<String> categories;
  final int selectedCategoryIndex;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(int) onCategorySelected;
  final Function(String) onSearch;
  final Function(String)? onSubmitted;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final TextEditingController searchController;

  const BillingLeftPanel({
    super.key,
    required this.isDesktopWidth,
    required this.hasEnoughHeight,
    required this.filteredItems,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onAddToCart,
    required this.onCategorySelected,
    required this.onSearch,
    this.onSubmitted,
    required this.hasMore,
    required this.onLoadMore,
    required this.searchController,
  });


  @override
  ConsumerState<BillingLeftPanel> createState() => _BillingLeftPanelState();
}

class _BillingLeftPanelState extends ConsumerState<BillingLeftPanel> {
  late final ScrollController _headController;
  late final ScrollController _bodyController;
  late final ScrollController _horizontalController;
  ScrollController? _categoryChipsControllerInstance;
  ScrollController get _categoryChipsController =>
      _categoryChipsControllerInstance ??= ScrollController();
  bool _isSyncingScroll = false;

  void _onHeadScrolled() {
    if (_isSyncingScroll) return;
    if (!_headController.hasClients || !_bodyController.hasClients) return;
    if (_headController.positions.length != 1 || _bodyController.positions.length != 1) return;
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
    if (_headController.positions.length != 1 || _bodyController.positions.length != 1) return;
    final offset = _bodyController.offset;
    if ((_headController.offset - offset).abs() > 0.5) {
      _isSyncingScroll = true;
      _headController.jumpTo(offset);
      _isSyncingScroll = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _headController = ScrollController();
    _bodyController = ScrollController();
    _horizontalController = ScrollController();
    _categoryChipsControllerInstance = ScrollController();

    _headController.addListener(_onHeadScrolled);
    _bodyController.addListener(_onBodyScrolled);
  }

  @override
  void dispose() {
    _headController.removeListener(_onHeadScrolled);
    _bodyController.removeListener(_onBodyScrolled);
    _headController.dispose();
    _bodyController.dispose();
    _horizontalController.dispose();
    _categoryChipsControllerInstance?.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = widget.selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => widget.onCategorySelected(index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF64748B)),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionalExpanded(bool condition, Widget child) {
    if (condition) {
      return Expanded(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rackProvider);
    
    ref.watch(categoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Search & Action Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
                            onChanged: widget.onSearch,
                            onSubmitted: (val) {
                              if (widget.onSubmitted != null) {
                                widget.onSubmitted!(val);
                              } else {
                                widget.onSearch(val);
                              }
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'Search items (name, brand, barcode, batch, rack, HSN, price)...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.searchController,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) return const SizedBox.shrink();
                            return InkWell(
                              onTap: () {
                                widget.searchController.clear();
                                if (widget.onSubmitted != null) {
                                  widget.onSubmitted!('');
                                } else {
                                  widget.onSearch('');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.qr_code_scanner,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        BillingDialogs.showAddCustomItemDialog(
                          context,
                          (customItem) {
                            widget.onAddToCart(customItem);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Custom Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => context.go('/counter/inventory'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF22C55E)),
                            SizedBox(width: 6),
                            Text(
                              'View Stock',
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: HorizontalMouseTouchpadScroll(
              controller: _categoryChipsController,
              child: SingleChildScrollView(
                controller: _categoryChipsController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  children: widget.categories
                      .asMap()
                      .entries
                      .map((entry) => _buildFilterChip(entry.value, entry.key))
                      .toList(),
                ),
              ),
            ),
          ),

          // Items Table or Empty State
          _buildConditionalExpanded(
            widget.hasEnoughHeight,
            widget.filteredItems.isEmpty
                ? Center(
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade300
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add items in Inventory (F2) or use Custom Item to bill directly.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // FIXED LEFT COLUMN (Item Name)
                    Container(
                      width: widget.isDesktopWidth ? 200 : 120,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 40,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                            padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 12),
                            child: Text(
                              'Item Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _buildConditionalExpanded(
                            widget.hasEnoughHeight,
                            ListView.separated(
                              controller: _headController,
                              shrinkWrap: !widget.hasEnoughHeight,
                              physics: widget.hasEnoughHeight ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                              itemCount: widget.filteredItems.length + 1,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                              itemBuilder: (context, index) {
                                if (index == widget.filteredItems.length) {
                                  return const SizedBox(height: 68); // Match the Load More button height
                                }
                                final item = widget.filteredItems[index];
                                return Container(
                                  height: 48, // Fixed height to guarantee sync
                                  padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 0),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    (item['name'] ?? '').toString().split(' - Item')[0],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 12,
                                    ),
                                  ),
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
                        controller: _horizontalController,
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                            width: widget.isDesktopWidth ? 1000 : 700, // Fixed width for scrollable area
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 40,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                                padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('SKU / Barcode', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Batch No', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Expiry', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('HSN Code', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('GST (%)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                  ],
                                ),
                              ),
                              _buildConditionalExpanded(
                                widget.hasEnoughHeight,
                                ListView.separated(
                                  controller: _bodyController,
                                  shrinkWrap: !widget.hasEnoughHeight,
                                  physics: widget.hasEnoughHeight ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                                  itemCount: widget.filteredItems.length + 1,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                                  itemBuilder: (context, index) {
                                    if (index == widget.filteredItems.length) {
                                      if (widget.hasMore) {
                                        return Container(
                                          height: 68,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: OutlinedButton(
                                              onPressed: widget.onLoadMore,
                                              child: const Text('Load More'),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox(height: 68);
                                    }
                                    final item = widget.filteredItems[index];
                                    return Container(
                                      height: 48, // Fixed height to guarantee sync
                                      padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 0),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['brand'] ?? item['manufacturer'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['pack'] ?? item['sku'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['batch_number'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['expiry_date'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['hsn_code'] ?? '-', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text('₹${(item['mrp'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(
                                            flex: 2, 
                                            child: Align(
                                              alignment: Alignment.centerLeft, 
                                              child: Text(
                                                ((item['cgst'] as num? ?? 0) + (item['sgst'] as num? ?? 0)) > 0 
                                                    ? '${((item['cgst'] as num? ?? 0) + (item['sgst'] as num? ?? 0)).toStringAsFixed(1)}%' 
                                                    : '-', 
                                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), 
                                                overflow: TextOverflow.ellipsis
                                              )
                                            )
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: (item['stock'] ?? 0) <= 0 && (item['loose_stock'] ?? 0) <= 0 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F8F5), borderRadius: BorderRadius.circular(12)),
                                                  child: Text(FormatUtils.formatInventoryStock(item), style: TextStyle(color: (item['stock'] ?? 0) <= 0 && (item['loose_stock'] ?? 0) <= 0 ? Colors.red : const Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: ElevatedButton.icon(
                                                onPressed: ((item['stock'] ?? 0) > 0) ? () => widget.onAddToCart(item) : null,
                                                icon: const Icon(Icons.add_shopping_cart, size: 14),
                                                label: const Text('Add'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF22C55E),
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey.shade300,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: const Size(0, 32),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
