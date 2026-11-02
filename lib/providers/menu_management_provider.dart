import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';

class MenuManagementState {
  final List<MenuCategory> categories;
  final List<PosMenuItem> items;
  final String selectedCategoryId;
  final String searchQuery;
  final bool? availabilityFilter; // null: all, true: available, false: out of stock
  final bool isLoading;

  const MenuManagementState({
    required this.categories,
    required this.items,
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.availabilityFilter,
    this.isLoading = false,
  });

  List<PosMenuItem> get filteredItems {
    return items.where((it) {
      final matchesCategory =
          selectedCategoryId == 'all' || it.categoryId == selectedCategoryId;
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          it.name.toLowerCase().contains(q) ||
          (it.shortCode != null && it.shortCode!.toLowerCase().contains(q)) ||
          (it.description != null && it.description!.toLowerCase().contains(q));
      final matchesAvailability =
          availabilityFilter == null || it.isAvailable == availabilityFilter;
      return matchesCategory && matchesSearch && matchesAvailability;
    }).toList();
  }

  int get totalItemsCount => items.length;
  int get availableItemsCount => items.where((i) => i.isAvailable).length;
  int get outOfStockCount => items.where((i) => !i.isAvailable).length;

  MenuManagementState copyWith({
    List<MenuCategory>? categories,
    List<PosMenuItem>? items,
    String? selectedCategoryId,
    String? searchQuery,
    bool? Function()? availabilityFilter,
    bool? isLoading,
  }) {
    return MenuManagementState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      availabilityFilter: availabilityFilter != null ? availabilityFilter() : this.availabilityFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MenuManagementNotifier extends Notifier<MenuManagementState> {
  @override
  MenuManagementState build() {
    Future.microtask(() => loadMenu());
    return const MenuManagementState(
      categories: [
        MenuCategory(id: 'all', name: 'All items', iconEmoji: '🍱'),
      ],
      items: [],
      isLoading: true,
    );
  }

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true);
    try {
      final outletId = await InventoryService.getShopId();
      final backendItems = await RestaurantPosService.fetchMenuItems(
        outletId: outletId,
        availableOnly: false,
      );
      final backendCategories = await RestaurantPosService.fetchCategories(
        outletId: outletId,
      );

      final cats = backendCategories.isNotEmpty
          ? backendCategories
          : const [
              MenuCategory(id: 'all', name: 'All items', iconEmoji: '🍱'),
              MenuCategory(id: 'beverages', name: 'Beverages', iconEmoji: '☕'),
              MenuCategory(id: 'starters', name: 'Starters', iconEmoji: '🍟'),
              MenuCategory(id: 'main', name: 'Main Course', iconEmoji: '🍛'),
              MenuCategory(id: 'chinese', name: 'Chinese', iconEmoji: '🥡'),
              MenuCategory(id: 'continental', name: 'Continental', iconEmoji: '🍕'),
              MenuCategory(id: 'desserts', name: 'Desserts', iconEmoji: '🧁'),
            ];

      state = state.copyWith(
        categories: cats,
        items: backendItems,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectCategory(String catId) {
    state = state.copyWith(selectedCategoryId: catId);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setAvailabilityFilter(bool? filter) {
    state = state.copyWith(availabilityFilter: () => filter);
  }

  Future<void> toggleItemAvailability(String itemId) async {
    final item = state.items.firstWhere((it) => it.id == itemId, orElse: () => state.items.first);
    final nextAvailability = !item.isAvailable;

    // Optimistic UI update
    final updated = state.items.map((it) {
      if (it.id == itemId) {
        return it.copyWith(isAvailable: nextAvailability);
      }
      return it;
    }).toList();
    state = state.copyWith(items: updated);

    await RestaurantPosService.toggleMenuItemAvailability(itemId, nextAvailability);
  }

  Future<void> addDish({
    required String name,
    String? shortCode,
    required String categoryId,
    required double price,
    String? badge,
    String? description,
    String? imageUrl,
    bool isVeg = true,
  }) async {
    String? outletId;
    try {
      outletId = await InventoryService.getShopId();
    } catch (_) {}

    final backendDish = await RestaurantPosService.createMenuItem(
      name: name,
      shortCode: shortCode,
      categoryId: categoryId,
      price: price,
      badge: badge,
      description: description,
      imageUrl: imageUrl,
      isVeg: isVeg,
      outletId: outletId,
    );

    if (backendDish != null) {
      await loadMenu();
    } else {
      final newId = '${DateTime.now().millisecondsSinceEpoch}';
      final newItem = PosMenuItem(
        id: newId,
        name: name,
        shortCode: shortCode,
        categoryId: categoryId,
        price: price,
        badge: badge,
        description: description,
        imageUrl: imageUrl,
        isAvailable: true,
        isVeg: isVeg,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  Future<void> updateDish(PosMenuItem updatedItem) async {
    final updated = state.items.map((it) {
      if (it.id == updatedItem.id) {
        return updatedItem;
      }
      return it;
    }).toList();
    state = state.copyWith(items: updated);

    await RestaurantPosService.updateMenuItem(updatedItem);
    await loadMenu();
  }

  Future<void> deleteDish(String itemId) async {
    state = state.copyWith(
      items: state.items.where((it) => it.id != itemId).toList(),
    );
    await RestaurantPosService.deleteMenuItem(itemId);
  }

  Future<void> addCategory({required String name, required String iconEmoji}) async {
    String? outletId;
    try {
      outletId = await InventoryService.getShopId();
    } catch (_) {}

    final backendCat = await RestaurantPosService.createCategory(
      name: name,
      iconEmoji: iconEmoji,
      outletId: outletId,
    );

    if (backendCat != null) {
      await loadMenu();
    } else {
      final newId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final newCat = MenuCategory(id: newId, name: name, iconEmoji: iconEmoji);
      state = state.copyWith(categories: [...state.categories, newCat]);
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String iconEmoji,
  }) async {
    // Optimistic UI update
    final updated = state.categories.map((c) {
      if (c.id == id) {
        return c.copyWith(name: name, iconEmoji: iconEmoji);
      }
      return c;
    }).toList();
    state = state.copyWith(categories: updated);

    await RestaurantPosService.updateCategory(
      id: id,
      name: name,
      iconEmoji: iconEmoji,
    );
    await loadMenu();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (categoryId == 'all') return;

    // Reset selectedCategoryId if currently selected
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: 'all');
    }

    final updated = state.categories.where((c) => c.id != categoryId).toList();
    state = state.copyWith(categories: updated);

    await RestaurantPosService.deleteCategory(categoryId);
    await loadMenu();
  }
}

final menuManagementProvider =
    NotifierProvider<MenuManagementNotifier, MenuManagementState>(() {
  return MenuManagementNotifier();
});
