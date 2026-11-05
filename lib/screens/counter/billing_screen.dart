import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirfbill_restaurant/screens/counter/widgets/pos/pos_menu_card.dart';

import '../../models/restaurant_pos_models.dart';
import '../../providers/counter_providers.dart';
import '../../providers/restaurant_order_provider.dart';
import '../../providers/restaurant_pos_provider.dart';
import '../../providers/restaurant_table_provider.dart';
import '../../services/restaurant_pos_service.dart';
import '../../services/shop_service.dart';
import '../../services/shop_settings_service.dart';
import '../../services/windows_auto_updater.dart';
import '../../utils/app_image_cache_manager.dart';
import 'widgets/pos/pos_cart_panel.dart';
import 'widgets/pos/pos_menu_section.dart';
import 'widgets/pos/pos_top_bar.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  int _mobileTab = 0; // 0: Menu, 1: Cart
  List<PosMenuItem> _catalog = [];
  List<MenuCategory> _categories = [];
  List<DiningTable> _tables = [];
  Map<String, dynamic>? _shopSettings;
  Shop? _activeOutlet;
  bool _isLoading = true;
  Timer? _occupancyTimer;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
      ref.read(restaurantOrderProvider.notifier).loadOrders();
      if (!kIsWeb && Platform.isWindows) {
        WindowsAutoUpdater.checkAndShowUpdateIfAvailable(context);
      }
    });
    // Live table occupancy ticker - updates table occupancy timers smoothly every 15 seconds
    _occupancyTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _refreshTablesSilent();
      }
    });
  }

  @override
  void dispose() {
    _occupancyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);
    String? outletId;
    try {
      final prefs = await SharedPreferences.getInstance();
      outletId = prefs.getString('selected_shop_id');
    } catch (_) {}

    final items = await RestaurantPosService.fetchMenuItems(outletId: outletId);
    final categories = await RestaurantPosService.fetchCategories(outletId: outletId);
    await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
    final tables = ref.read(restaurantTableProvider).tables;

    Map<String, dynamic>? shopSettings;
    try {
      shopSettings = await ShopSettingsService.getSettings();
    } catch (e) {
      debugPrint('Error loading shop settings in billing: $e');
    }

    Shop? currentOutlet;
    try {
      final shops = await ShopService.getShops();
      if (shops.isNotEmpty) {
        currentOutlet = shops.firstWhere(
          (s) => s.id == outletId,
          orElse: () => shops.first,
        );
      }
    } catch (e) {
      debugPrint('Error loading active outlet in billing: $e');
    }

    if (mounted) {
      setState(() {
        _catalog = items;
        _categories = categories;
        _tables = tables;
        _shopSettings = shopSettings;
        _activeOutlet = currentOutlet;
        _isLoading = false;
      });

      // Warm up / precache menu images through the throttled AppImageCacheManager
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final urls = <String>[];
        for (final item in items.take(20)) {
          final url = item.imageUrl ?? PosMenuCard.foodImages[item.name];
          if (url != null && url.isNotEmpty) {
            urls.add(url);
          }
        }
        AppImageCacheManager.instance.precacheBatch(urls);
      });

      // Synchronize active table ID with real table ID from backend
      if (tables.isNotEmpty) {
        final currentTableId = ref.read(restaurantPosProvider).selectedTableId;
        final matchesExisting = tables.any((t) => t.id == currentTableId);
        if (!matchesExisting) {
          final firstTable = tables.first;
          ref.read(restaurantPosProvider.notifier).selectTable(firstTable.id);
          ref.read(restaurantPosProvider.notifier).selectFloor(firstTable.floor);
        }
      }
    }
  }

  Future<void> _refreshTables() async {
    await ref.read(restaurantTableProvider.notifier).loadTables();
    if (mounted) {
      setState(() => _tables = ref.read(restaurantTableProvider).tables);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table statuses refreshed.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _refreshTablesSilent() async {
    await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
    if (mounted) {
      setState(() => _tables = ref.read(restaurantTableProvider).tables);
    }
  }

  Future<void> _handleSelectTable(
    String tableId,
    RestaurantPosNotifier posNotifier, {
    bool showFeedback = true,
  }) async {
    posNotifier.selectTable(tableId);

    // Check if selected table has an active order (whether occupied or served)
    final tableSource = _tables.isNotEmpty ? _tables : ref.read(restaurantTableProvider).tables;
    final targetTable = tableSource.where((t) => t.id == tableId).firstOrNull;
    
    // 1. Attempt to load live order from dedicated table endpoint
    Map<String, dynamic>? activeOrder = await RestaurantPosService.fetchActiveOrderByTable(tableId);

    // If activeOrder is cancelled, settled or paid, do not treat it as active
    if (activeOrder != null) {
      final statusStr = (activeOrder['status'] ?? activeOrder['order_status'] ?? '').toString().toUpperCase();
      final paymentStatusStr = (activeOrder['payment_status'] ?? '').toString().toUpperCase();
      if (statusStr.contains('CANCEL') ||
          statusStr.contains('SETTLE') ||
          statusStr.contains('COMPLET') ||
          paymentStatusStr.contains('PAID')) {
        activeOrder = null;
      }
    }

    // 2. Fallback: If table endpoint returned null/empty, find any unsettled dine-in order for this table
    RestaurantOrder? matchingLiveOrder;
    if (activeOrder == null || activeOrder['lines'] == null || (activeOrder['lines'] as List).isEmpty) {
      final orders = ref.read(restaurantOrderProvider).orders;
      final targetLabelLower = targetTable?.label.trim().toLowerCase();
      matchingLiveOrder = orders.where((ord) {
        final matchesId = ord.tableId == tableId || ord.tableLabel == tableId;
        final matchesLabel = targetLabelLower != null &&
            ord.tableLabel != null &&
            ord.tableLabel!.trim().toLowerCase() == targetLabelLower;
        return (matchesId || matchesLabel) &&
            ord.paymentStatus != PaymentStatus.paid &&
            ord.status != OrderStatus.cancelled &&
            ord.status != OrderStatus.completed;
      }).firstOrNull;
    }

    if (activeOrder != null && activeOrder['lines'] is List && (activeOrder['lines'] as List).isNotEmpty) {
      final List lines = activeOrder['lines'];
      final List<PosCartItem> loadedItems = [];

      for (final line in lines) {
        final itemId = line['item_id']?.toString() ?? '';
        final itemName = line['item_name']?.toString() ?? 'Item';
        final qty = (line['quantity'] is num) ? (line['quantity'] as num).toInt() : 1;
        final unitPrice = double.tryParse(line['unit_price']?.toString() ?? '0') ?? 0.0;
        final taxRate = double.tryParse(line['tax_rate']?.toString() ?? '5') ?? 5.0;

        final existingIndex = loadedItems.indexWhere((c) => c.item.id == itemId);
        if (existingIndex >= 0) {
          loadedItems[existingIndex] = loadedItems[existingIndex].copyWith(
            quantity: loadedItems[existingIndex].quantity + qty,
          );
        } else {
          final catalogItem = _catalog.where((c) => c.id == itemId).firstOrNull ??
              PosMenuItem(
                id: itemId,
                name: itemName,
                price: unitPrice,
                categoryId: 'all',
                taxPercent: taxRate,
              );

          loadedItems.add(PosCartItem(
            item: catalogItem,
            quantity: qty,
            notes: line['special_instructions']?.toString(),
          ));
        }
      }

      if (loadedItems.isNotEmpty) {
        posNotifier.setCart(
          loadedItems,
          customerName: activeOrder['customer_name']?.toString(),
          customerPhone: activeOrder['customer_phone']?.toString(),
          notes: activeOrder['notes']?.toString(),
          orderId: activeOrder['id']?.toString(),
          orderNumber: activeOrder['order_number']?.toString(),
          orderVersion: (activeOrder['version'] is num) ? (activeOrder['version'] as num).toInt() : 1,
        );

        if (mounted && showFeedback) {
          final tableLabel = targetTable?.label ?? 'Table $tableId';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded active order for $tableLabel (${activeOrder['order_number']})'),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        return;
      }
    } else if (matchingLiveOrder != null && matchingLiveOrder.items.isNotEmpty) {
      // Fallback loaded from live orders provider (e.g. order marked served or held)
      posNotifier.setCart(
        matchingLiveOrder.items,
        customerName: matchingLiveOrder.customerName,
        customerPhone: matchingLiveOrder.customerPhone,
        notes: matchingLiveOrder.notes,
        orderId: matchingLiveOrder.id,
        orderNumber: matchingLiveOrder.orderNumber,
        orderVersion: 1,
      );

      if (mounted && showFeedback) {
        final tableLabel = targetTable?.label ?? 'Table $tableId';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded active order for $tableLabel (${matchingLiveOrder.orderNumber})'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      return;
    }

    // If there is no active order for this table, ensure cart & active order are cleared
    posNotifier.clearCart();
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(restaurantPosProvider);
    final posNotifier = ref.read(restaurantPosProvider.notifier);
    final tableState = ref.watch(restaurantTableProvider);
    final liveTables = tableState.tables.isNotEmpty ? tableState.tables : _tables;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final filteredItems = _catalog.where((item) {
      final matchesCategory = posState.activeCategoryId == 'all' ||
          item.categoryId == posState.activeCategoryId;
      final query = posState.searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          (item.shortCode != null && item.shortCode!.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    // Reusable Menu Section
    final menuWidget = PosMenuSection(
      isLoading: _isLoading,
      activeCategoryId: posState.activeCategoryId,
      categories: _categories,
      catalog: _catalog,
      filteredItems: filteredItems,
      onSelectCategory: posNotifier.setCategory,
      onAddItem: (item) => posNotifier.addItem(item),
      onReloadMenu: _loadMenuData,
    );

    // Reusable Cart Panel
    final cartWidget = PosCartPanel(
      liveTables: liveTables,
      catalog: _catalog,
      shopSettings: _shopSettings,
      activeOutlet: _activeOutlet,
      onRefreshTables: _refreshTables,
      onSelectTable: _handleSelectTable,
      onReloadMenu: _loadMenuData,
      isMobile: isMobile,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              height: 56,
              selectedIndex: _mobileTab,
              onDestinationSelected: (idx) => setState(() => _mobileTab = idx),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Badge(
                    label: Text('${posState.cart.length}'),
                    isLabelVisible: posState.cart.isNotEmpty,
                    child: const Icon(Icons.shopping_cart_rounded),
                  ),
                  label: 'Cart (₹${posState.grandTotal.toStringAsFixed(0)})',
                ),
              ],
            )
          : null,
      body: isMobile
          ? Column(
              children: [
                PosTopBar(
                  onBranchChanged: _loadMenuData,
                  onRefresh: _loadMenuData,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _mobileTab,
                    children: [menuWidget, cartWidget],
                  ),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final double cartWidth = totalWidth < 880
                    ? (totalWidth * 0.44).clamp(300.0, 360.0)
                    : (totalWidth < 1200 ? 380.0 : 440.0);

                return Row(
                  children: [
                    // LEFT PANE (Top bar + Category Selector + Menu Grid)
                    Expanded(
                      child: Column(
                        children: [
                          PosTopBar(
                            onBranchChanged: _loadMenuData,
                            onRefresh: _loadMenuData,
                          ),
                          Expanded(child: menuWidget),
                        ],
                      ),
                    ),

                    // RIGHT PANE (Full-height Cart & Order / Settlement Pane)
                    SizedBox(
                      width: cartWidth,
                      height: double.infinity,
                      child: cartWidget,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
