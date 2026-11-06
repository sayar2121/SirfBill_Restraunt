import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

class MenuFilterHeader extends StatefulWidget {
  final int totalCount;
  final int availableCount;
  final int outOfStockCount;
  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final bool? availabilityFilter;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<bool?> onSelectAvailability;
  final ValueChanged<String> onSearch;
  final VoidCallback onAddDish;
  final VoidCallback? onBulkUpload;
  final VoidCallback? onAddCategory;
  final ValueChanged<MenuCategory>? onEditCategory;
  final ValueChanged<MenuCategory>? onDeleteCategory;
  final VoidCallback? onRefresh;

  const MenuFilterHeader({
    super.key,
    required this.totalCount,
    required this.availableCount,
    required this.outOfStockCount,
    required this.categories,
    required this.selectedCategoryId,
    required this.availabilityFilter,
    required this.onSelectCategory,
    required this.onSelectAvailability,
    required this.onSearch,
    required this.onAddDish,
    this.onBulkUpload,
    this.onAddCategory,
    this.onEditCategory,
    this.onDeleteCategory,
    this.onRefresh,
  });

  @override
  State<MenuFilterHeader> createState() => _MenuFilterHeaderState();
}

class _MenuFilterHeaderState extends State<MenuFilterHeader> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Search, and Add Dish CTA
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;
              return Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menu & Catalog Management',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: isCompact ? 130 : 200,
                    height: 36,
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                        hintText: 'Search dishes...',
                        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onRefresh != null) ...[
                    IconButton(
                      onPressed: widget.onRefresh,
                      tooltip: 'Refresh Menu from Backend',
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF10B981)),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => _showManageCategoriesModal(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      isCompact ? 'Categories' : 'Manage Categories',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onBulkUpload != null) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onBulkUpload,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.table_view_rounded, size: 16),
                      label: Text(
                        isCompact ? 'Bulk' : 'Bulk Upload',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: widget.onAddDish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      isCompact ? 'Add' : 'Add Food Item',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Bottom Filter Row: Category Pills + In-stock / Out-of-stock Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Vertical Category Box Cards (Matches POS Selector Style)
                ...widget.categories.map((c) {
                  final isSelected = c.id == widget.selectedCategoryId;
                  final isAll = c.id == 'all';
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Container(
                      width: 96,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => widget.onSelectCategory(c.id),
                              child: SizedBox.expand(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        c.iconEmoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        c.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Edit / Delete action overlay in top corners for custom categories
                          if (!isAll && (widget.onEditCategory != null || widget.onDeleteCategory != null))
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.onEditCategory != null)
                                    Tooltip(
                                      message: 'Edit Category',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () => widget.onEditCategory?.call(c),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 12,
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (widget.onDeleteCategory != null)
                                    Tooltip(
                                      message: 'Delete Category',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () => widget.onDeleteCategory?.call(c),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 12,
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (widget.onAddCategory != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Container(
                      width: 96,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: widget.onAddCategory,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFF10B981)),
                              SizedBox(height: 5),
                              Text(
                                '+ Category',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1.2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: borderColor,
                ),
                const SizedBox(width: 8),

                // Unified Standard Status Filter Pills (Matching Orders & Tables)
                CommonStatusFilterPill(
                  label: 'All',
                  count: widget.totalCount,
                  isSelected: widget.availabilityFilter == null,
                  color: const Color(0xFF64748B),
                  onTap: () => widget.onSelectAvailability(null),
                ),
                const SizedBox(width: 8),
                CommonStatusFilterPill(
                  label: 'In Stock',
                  count: widget.availableCount,
                  isSelected: widget.availabilityFilter == true,
                  color: const Color(0xFF10B981),
                  onTap: () => widget.onSelectAvailability(true),
                ),
                const SizedBox(width: 8),
                CommonStatusFilterPill(
                  label: 'Out of Stock',
                  count: widget.outOfStockCount,
                  isSelected: widget.availabilityFilter == false,
                  color: const Color(0xFFEF4444),
                  onTap: () => widget.onSelectAvailability(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showManageCategoriesModal(BuildContext context) {
    final customCats = widget.categories.where((c) => c.id != 'all').toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Manage Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (widget.onAddCategory != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onAddCategory!();
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add New', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  elevation: 0,
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: customCats.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No custom categories created yet.\nClick "+ Category" to add one.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: customCats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final cat = customCats[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cat.iconEmoji, style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onEditCategory != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                              tooltip: 'Edit Category',
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onEditCategory!(cat);
                              },
                            ),
                          if (widget.onDeleteCategory != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              tooltip: 'Delete Category',
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onDeleteCategory!(cat);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
