import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant_pos_models.dart';
import '../../providers/menu_management_provider.dart';
import 'widgets/menu/menu_filter_header.dart';
import 'widgets/menu/menu_item_manage_tile.dart';
import 'widgets/menu/add_dish_modal.dart';
import 'widgets/menu/menu_item_detail_modal.dart';
import 'widgets/menu/bulk_menu_upload_modal.dart';
import 'widgets/pos/pos_menu_card.dart';
import '../../utils/app_image_cache_manager.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuManagementProvider);
    final menuNotifier = ref.read(menuManagementProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final items = menuState.filteredItems;

    // Precache first visible items in the throttled background queue
    if (items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final urls = <String>[];
        for (final item in items.take(20)) {
          final url = item.imageUrl?.trim() ?? PosMenuCard.foodImages[item.name];
          if (url != null && url.isNotEmpty) {
            urls.add(url);
          }
        }
        AppImageCacheManager.instance.precacheBatch(urls);
      });
    }

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Menu Filter Header (Categories, Stock Filters, Search, Add Dish)
          MenuFilterHeader(
            totalCount: menuState.totalItemsCount,
            availableCount: menuState.availableItemsCount,
            outOfStockCount: menuState.outOfStockCount,
            categories: menuState.categories,
            selectedCategoryId: menuState.selectedCategoryId,
            availabilityFilter: menuState.availabilityFilter,
            onSelectCategory: menuNotifier.selectCategory,
            onSelectAvailability: menuNotifier.setAvailabilityFilter,
            onSearch: menuNotifier.setSearchQuery,
            onAddDish: () => _showAddDishDialog(context, menuState.categories, menuNotifier),
            onBulkUpload: () => _showBulkUploadDialog(context, menuNotifier),
            onAddCategory: () => _showAddOrEditCategoryDialog(context, menuNotifier),
            onEditCategory: (cat) => _showAddOrEditCategoryDialog(context, menuNotifier, existingCategory: cat),
            onDeleteCategory: (cat) => _confirmDeleteCategory(context, menuNotifier, cat),
            onRefresh: () => menuNotifier.loadMenu(),
          ),

          // 2. Responsive Items Grid / List
          Expanded(
            child: menuState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'No food items match current filter',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDishDialog(context, menuState.categories, menuNotifier),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Food Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.84,
                    ),
                    itemBuilder: (context, index) {
                          final item = items[index];
                          final category = menuState.categories.firstWhere(
                            (c) => c.id == item.categoryId,
                            orElse: () => const MenuCategory(id: '', name: 'General', iconEmoji: '🍽️'),
                          );

                          return MenuItemManageTile(
                            item: item,
                            categoryName: '${category.iconEmoji} ${category.name}',
                            onTap: () => _showItemDetailDialog(
                              context,
                              item,
                              '${category.iconEmoji} ${category.name}',
                              menuState.categories,
                              menuNotifier,
                            ),
                            onToggleAvailability: () => menuNotifier.toggleItemAvailability(item.id),
                            onEdit: () => _showAddDishDialog(context, menuState.categories, menuNotifier, dish: item),
                            onDelete: () {
                              menuNotifier.deleteDish(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.name} removed from menu.')),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailDialog(
    BuildContext context,
    PosMenuItem item,
    String categoryName,
    List<MenuCategory> categories,
    MenuManagementNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MenuItemDetailModal(
        item: item,
        categoryName: categoryName,
        onEdit: () => _showAddDishDialog(context, categories, notifier, dish: item),
        onToggleAvailability: () => notifier.toggleItemAvailability(item.id),
        onDelete: () {
          notifier.deleteDish(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} removed from menu.')),
          );
        },
      ),
    );
  }

  void _showAddDishDialog(
    BuildContext context,
    List<MenuCategory> categories,
    MenuManagementNotifier notifier, {
    PosMenuItem? dish,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddDishModal(
        categories: categories,
        initialDish: dish,
        onAddNewCategory: () => _showAddOrEditCategoryDialog(context, notifier),
        onSave: (savedDish) {
          if (dish != null) {
            notifier.updateDish(savedDish);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${savedDish.name} updated successfully!')),
            );
          } else {
            notifier.addDish(
              name: savedDish.name,
              shortCode: savedDish.shortCode,
              categoryId: savedDish.categoryId,
              price: savedDish.price,
              badge: savedDish.badge,
              description: savedDish.description,
              imageUrl: savedDish.imageUrl,
              isVeg: savedDish.isVeg,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${savedDish.name} added to menu!')),
            );
          }
        },
      ),
    );
  }

  void _showAddOrEditCategoryDialog(
    BuildContext context,
    MenuManagementNotifier notifier, {
    MenuCategory? existingCategory,
  }) {
    final isEditing = existingCategory != null;
    final nameCtrl = TextEditingController(text: existingCategory?.name ?? '');
    String emoji = existingCategory?.iconEmoji ?? '🍽️';
    final emojiCtrl = TextEditingController(text: emoji);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.category_rounded,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Food Category' : 'Add Food Category',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter category name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Biryani, Tandoori, Drinks',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Choose Icon / Emoji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Main course / Indian
                          '🍛', '🍚', '🍲', '🥘', '🫓', '🍗', '🍖', '🥩',
                          // Fast Food & Snacks
                          '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥟', '🍤',
                          // Asian / Noodles / Soups
                          '🍜', '🍱', '🍣', '🍙', '🍢', '🧆', '🥣', '🥗',
                          // Desserts & Sweets
                          '🧁', '🍰', '🎂', '🍩', '🍪', '🍨', '🍧', '🍦', '🥞', '🧇', '🍮', '🍫',
                          // Beverages & Drinks
                          '☕', '🫖', '🥤', '🧋', '🍺', '🍻', '🍷', '🍸', '🍹', '🍾', '🥛', '🧃',
                          // Breakfast & Bakery
                          '🥐', '🥯', '🍞', '🥖', '🍳', '🧀',
                          // General Dining
                          '🍽️', '🍴', '🥄', '🥢', '🌶️', '🥑', '🥦', '🌽', '🍅', '🍄',
                        ].map((e) {
                          final isSelected = emoji == e;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                emoji = e;
                                emojiCtrl.text = e;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : null,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          emoji.isNotEmpty ? emoji : '🍽️',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: emojiCtrl,
                          onChanged: (val) {
                            setDialogState(() {
                              emoji = val.trim().isNotEmpty ? val.trim() : '🍽️';
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Or type custom emoji',
                            hintText: 'e.g. 🍷 or 🥙',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final catName = nameCtrl.text.trim();
                    final finalEmoji = emojiCtrl.text.trim().isNotEmpty
                        ? emojiCtrl.text.trim()
                        : (emoji.isNotEmpty ? emoji : '🍽️');
                    Navigator.pop(ctx);
                    if (isEditing) {
                      await notifier.updateCategory(
                        id: existingCategory.id,
                        name: catName,
                        iconEmoji: finalEmoji,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Category $catName updated successfully!')),
                        );
                      }
                    } else {
                      await notifier.addCategory(name: catName, iconEmoji: finalEmoji);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Category $catName added successfully!')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isEditing ? 'Update Category' : 'Save Category'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, MenuManagementNotifier notifier, MenuCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text('Delete "${category.name}"?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.iconEmoji} ${category.name}"? Food items in this category will not be deleted but can be reassigned.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await notifier.deleteCategory(category.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${category.name}" deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkUploadDialog(
    BuildContext context,
    MenuManagementNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BulkMenuUploadModal(
        onSuccess: () => notifier.loadMenu(),
      ),
    );
  }
}
