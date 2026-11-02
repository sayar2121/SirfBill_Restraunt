import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'pos_category_selector.dart';
import 'pos_menu_grid.dart';

/// Reusable Left Menu Catalog Section for the Restaurant POS Billing Screen.
class PosMenuSection extends StatelessWidget {
  final bool isLoading;
  final String activeCategoryId;
  final List<MenuCategory> categories;
  final List<PosMenuItem> catalog;
  final List<PosMenuItem> filteredItems;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<PosMenuItem> onAddItem;
  final VoidCallback onReloadMenu;

  const PosMenuSection({
    super.key,
    required this.isLoading,
    required this.activeCategoryId,
    required this.categories,
    required this.catalog,
    required this.filteredItems,
    required this.onSelectCategory,
    required this.onAddItem,
    required this.onReloadMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PosCategorySelector(
          activeCategoryId: activeCategoryId,
          categories: categories.isNotEmpty ? categories : null,
          onSelectCategory: onSelectCategory,
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : (catalog.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          const Text(
                            'No menu items found in backend database.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add dishes in Menu Management or seed restaurant items via backend API.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: onReloadMenu,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh Menu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : PosMenuGrid(
                      items: filteredItems,
                      onAddItem: onAddItem,
                    )),
        ),
      ],
    );
  }
}
