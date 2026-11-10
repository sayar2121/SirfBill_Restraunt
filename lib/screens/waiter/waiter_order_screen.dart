import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/restaurant_pos_models.dart';
import '../../providers/kitchen_display_provider.dart';
import '../../providers/restaurant_order_provider.dart';
import '../../providers/restaurant_table_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/restaurant_pos_service.dart';
import '../../utils/kot_printer_helper.dart';
import 'widgets/waiter_app_bar.dart';
import 'widgets/waiter_table_strip.dart';
import 'widgets/waiter_category_strip.dart';
import 'widgets/waiter_menu_card.dart';
import 'widgets/waiter_cart_panel.dart';

/// Touch-optimized Waiter Order Taking Screen
/// Designed specifically for Waitstaff / Captains to select tables,
/// punch items from the menu, and automatically dispatch orders to both POS and Kitchen.
class WaiterOrderScreen extends ConsumerStatefulWidget {
  const WaiterOrderScreen({super.key});

  @override
  ConsumerState<WaiterOrderScreen> createState() => _WaiterOrderScreenState();
}

class _WaiterOrderScreenState extends ConsumerState<WaiterOrderScreen> {
  String _waiterName = 'Waiter';
  String _activeFloor = '';
  String? _selectedTableId;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Real-time tracking of active orders on seated tables
  String? _activeOrderId;
  String? _activeOrderNumber;
  int? _activeOrderVersion;
  List<PosCartItem> _initialCart = [];

  // Responsive controls: Mobile tab index & Desktop draggable cart width
  int _mobileTabIndex = 0;
  double _cartWidth = 360.0;

  List<PosMenuItem> _catalog = [];
  List<MenuCategory> _categories = [];
  Timer? _refreshTimer;

  // Cart managed locally or synced with POS provider for this table
  final List<PosCartItem> _cart = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWaiterInfo();
    _loadMenuAndTables();

    // Auto-refresh tables and orders state every 5 seconds for real-time live sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
        ref.read(restaurantOrderProvider.notifier).loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWaiterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ??
        prefs.getString('role_login_name') ??
        'Waiter';
    if (mounted) {
      setState(() => _waiterName = name);
    }
  }

  Future<void> _loadMenuAndTables() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedShopId = prefs.getString('selected_shop_id');
      final assignedOutletId = prefs.getString('assigned_outlet_id');
      final targetShopId = (assignedOutletId != null && assignedOutletId.isNotEmpty)
          ? assignedOutletId
          : (savedShopId != null && savedShopId.isNotEmpty
              ? savedShopId
              : await InventoryService.getShopId());

      if (targetShopId.isNotEmpty) {
        await InventoryService.setShopId(targetShopId);
        await prefs.setString('selected_shop_id', targetShopId);
      }

      // Fetch real-time menu items and categories for the active outlet
      final items = await RestaurantPosService.fetchMenuItems(outletId: targetShopId);
      final categories = await RestaurantPosService.fetchCategories(outletId: targetShopId);

      // Refresh live dining tables and live order tickets
      await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      await ref.read(restaurantOrderProvider.notifier).loadOrders();

      if (mounted) {
        setState(() {
          _catalog = items;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectTable(DiningTable table) async {
    setState(() {
      _selectedTableId = table.id;
      _activeOrderId = null;
      _activeOrderNumber = null;
      _activeOrderVersion = 1;
      _initialCart = [];
      _cart.clear();
      _notesController.clear();
    });

    // 1. Fetch live order from dedicated table endpoint
    Map<String, dynamic>? active = await RestaurantPosService.fetchActiveOrderByTable(table.id);

    // If order is completed, cancelled or paid, treat table as empty
    if (active != null) {
      final statusStr = (active['status'] ?? active['order_status'] ?? '').toString().toUpperCase();
      final paymentStatusStr = (active['payment_status'] ?? '').toString().toUpperCase();
      if (statusStr.contains('CANCEL') ||
          statusStr.contains('SETTLE') ||
          statusStr.contains('COMPLET') ||
          paymentStatusStr.contains('PAID')) {
        active = null;
      }
    }

    // 2. Fallback: match from live orders in restaurantOrderProvider
    if (active == null || active['lines'] == null || (active['lines'] as List).isEmpty) {
      final orders = ref.read(restaurantOrderProvider).orders;
      final targetLabelLower = table.label.trim().toLowerCase();
      final matchingOrder = orders.where((ord) {
        final matchesId = ord.tableId == table.id || ord.tableLabel == table.id;
        final matchesLabel = ord.tableLabel != null &&
            ord.tableLabel!.trim().toLowerCase() == targetLabelLower;
        return (matchesId || matchesLabel) &&
            ord.paymentStatus != PaymentStatus.paid &&
            ord.status != OrderStatus.cancelled &&
            ord.status != OrderStatus.completed;
      }).firstOrNull;

      if (matchingOrder != null) {
        active = await RestaurantPosService.fetchOrderById(matchingOrder.id);
      }
    }

    // If an active order exists on this table, load its real live dishes!
    if (active != null && active['lines'] is List && (active['lines'] as List).isNotEmpty) {
      final List lines = active['lines'];
      final List<PosCartItem> loadedItems = [];

      for (final l in lines) {
        final itemId = l['item_id']?.toString() ?? '';
        final itemName = l['item_name']?.toString() ?? 'Item';
        final qty = (l['quantity'] is num) ? (l['quantity'] as num).toInt() : 1;
        final unitPrice = double.tryParse(l['unit_price']?.toString() ?? '0') ?? 0.0;
        final taxRate = double.tryParse(l['tax_rate']?.toString() ?? '5') ?? 5.0;

        final matched = _catalog.where((c) => c.id == itemId).firstOrNull ??
            PosMenuItem(
              id: itemId,
              name: itemName,
              price: unitPrice,
              categoryId: 'all',
              taxPercent: taxRate,
            );

        loadedItems.add(PosCartItem(
          item: matched,
          quantity: qty,
          notes: l['special_instructions']?.toString(),
        ));
      }

      if (mounted) {
        setState(() {
          _activeOrderId = active!['id']?.toString();
          _activeOrderNumber = active['order_number']?.toString();
          _activeOrderVersion = (active['version'] is num)
              ? (active['version'] as num).toInt()
              : 1;
          _cart.clear();
          _cart.addAll(loadedItems);
          _initialCart = List.from(loadedItems);
          if (active['notes'] != null && active['notes'].toString().isNotEmpty) {
            _notesController.text = active['notes'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded live order for ${table.label} (${_activeOrderNumber ?? ""})'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _addItem(PosMenuItem item) {
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Table first before adding dishes.'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final idx = _cart.indexWhere((c) => c.item.id == item.id);
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
      } else {
        _cart.add(PosCartItem(item: item, quantity: 1));
      }
    });
  }

  void _decrementItem(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity - 1);
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _incrementItem(int index) {
    setState(() {
      _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity + 1);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _incrementByItem(PosMenuItem item) {
    _addItem(item);
  }

  void _decrementByItem(PosMenuItem item) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.item.id == item.id);
      if (idx >= 0) {
        if (_cart[idx].quantity > 1) {
          _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity - 1);
        } else {
          _cart.removeAt(idx);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      if (_activeOrderId != null && _activeOrderId!.isNotEmpty && _initialCart.isNotEmpty) {
        _cart.clear();
        _cart.addAll(_initialCart.map((e) => e.copyWith()).toList());
      } else {
        _cart.clear();
        _notesController.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart cleared'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF64748B),
      ),
    );
  }

  double get _cartTotal =>
      _cart.fold(0.0, (sum, i) => sum + (i.item.price * i.quantity));

  Future<void> _submitOrderToKitchenAndPos() async {
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table first.')),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Please add dishes.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final tables = ref.read(restaurantTableProvider).tables;
    final matchedTable = tables.where((t) => t.id == _selectedTableId).firstOrNull;
    final tableLabel = matchedTable?.label ?? 'Table $_selectedTableId';
    final floor = matchedTable?.floor ?? '1st Floor';
    final notes = _notesController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    final outletId = prefs.getString('selected_shop_id') ??
        prefs.getString('assigned_outlet_id') ??
        await InventoryService.getShopId();

    try {
      // 1. If this table already has an active order on backend, compute delta running items
      if (_activeOrderId != null && _initialCart.isNotEmpty) {
        final List<PosCartItem> deltaItems = [];
        for (final cartItem in _cart) {
          final initMatch = _initialCart
              .where((initItem) => initItem.item.id == cartItem.item.id)
              .firstOrNull;
          final initQty = initMatch?.quantity ?? 0;
          final diff = cartItem.quantity - initQty;
          if (diff > 0) {
            deltaItems.add(cartItem.copyWith(quantity: diff));
          }
        }

        if (deltaItems.isEmpty) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new running items to add to this order.'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        // Append new running items to existing active order on backend
        await RestaurantPosService.appendItemsToOrder(
          orderId: _activeOrderId!,
          newItems: deltaItems,
          expectedVersion: _activeOrderVersion ?? 1,
        );

        final orderNum = _activeOrderNumber ?? 'ORD';
        final kotNum = 'KOT-${orderNum.replaceAll("#", "")}';

        // Update KDS live status (already prepared items stay SERVED/DONE, delta items get NEW ADDED)
        ref.read(kitchenDisplayProvider.notifier).markRunningItemsForOrder(
          orderId: _activeOrderId!,
          existingPreparedItemIds: _initialCart.map((e) => e.item.id).toList(),
          newlyAddedItemIds: deltaItems.map((d) => d.item.id).toList(),
        );

        // Thermal print KOT for newly added running items
        if (mounted) {
          KotPrinterHelper.printKotDirectly(
            context: context,
            kotNumber: kotNum,
            orderNumber: orderNum,
            orderType: 'Dine-in Running Items (Waiter)',
            tableLabel: tableLabel,
            floor: floor,
            customerName: 'Waiter: $_waiterName',
            orderNotes: notes,
            items: deltaItems,
          );
        }
      } else {
        // 2. New Order on Empty Table -> Send full order to Kitchen & POS
        final res = await RestaurantPosService.sendToKitchen(
          orderType: 'DINE_IN',
          tableId: _selectedTableId,
          cartItems: _cart,
          customerName: 'Served by: $_waiterName',
          orderNotes: notes,
          outletId: outletId,
        );

        final orderNum = res?['order_number']?.toString() ??
            '#ORD-${DateTime.now().millisecondsSinceEpoch % 10000}';
        final kotNum = 'KOT-${orderNum.replaceAll("#", "")}';

        // Update KDS
        ref.read(kitchenDisplayProvider.notifier).markRunningItemsForOrder(
          orderId: res?['id']?.toString() ?? _selectedTableId!,
          existingPreparedItemIds: const [],
          newlyAddedItemIds: _cart.map((c) => c.item.id).toList(),
        );

        // Print KOT
        if (mounted) {
          KotPrinterHelper.printKotDirectly(
            context: context,
            kotNumber: kotNum,
            orderNumber: orderNum,
            orderType: 'Dine-in (Waiter)',
            tableLabel: tableLabel,
            floor: floor,
            customerName: 'Waiter: $_waiterName',
            orderNotes: notes,
            items: _cart,
          );
        }
      }

      // Synchronize live tables, orders and KDS tickets
      await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      await ref.read(restaurantOrderProvider.notifier).loadOrders();
      ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);

      if (mounted) {
        setState(() {
          _cart.clear();
          _initialCart.clear();
          _activeOrderId = null;
          _activeOrderNumber = null;
          _notesController.clear();
          _selectedTableId = null;
          _mobileTabIndex = 0;
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order placed & synchronized with POS & Kitchen for $tableLabel!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableState = ref.watch(restaurantTableProvider);
    final tables = tableState.tables;

    final filteredItems = _catalog.where((item) {
      final matchesCategory =
          _selectedCategory == 'all' || item.categoryId == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          (item.shortCode != null && item.shortCode!.toLowerCase().contains(q));
      return matchesCategory && matchesQuery;
    }).toList();

    final matchedTable = tables.where((t) => t.id == _selectedTableId).firstOrNull;
    final selectedTableLabel = matchedTable?.label ?? (_selectedTableId ?? '');

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 820;

    // Responsive Menu View Component with CustomScrollView to prevent RenderFlex overflow
    final menuView = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: WaiterTableStrip(
              tables: tables,
              selectedFloor: _activeFloor,
              selectedTableId: _selectedTableId,
              onSelectFloor: (f) => setState(() => _activeFloor = f),
              onSelectTable: _selectTable,
              onRefresh: () => ref
                  .read(restaurantTableProvider.notifier)
                  .loadTables(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: WaiterCategoryStrip(
            categories: _categories,
            selectedCategory: _selectedCategory,
            searchQuery: _searchQuery,
            onSelectCategory: (catId) =>
                setState(() => _selectedCategory = catId),
            onSearchChanged: (q) =>
                setState(() => _searchQuery = q),
            onClearSearch: () =>
                setState(() => _searchQuery = ''),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          sliver: filteredItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No menu items match your search',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try selecting another category or clearing search',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile
                        ? (screenWidth >= 540 ? 3 : (screenWidth >= 340 ? 2 : 1))
                        : (screenWidth >= 1200 ? 5 : (screenWidth >= 900 ? 4 : 3)),
                    childAspectRatio: isMobile
                        ? (screenWidth >= 540 ? 0.72 : (screenWidth >= 340 ? 0.76 : 1.4))
                        : (screenWidth >= 1200 ? 0.78 : (screenWidth >= 900 ? 0.76 : 0.72)),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final item = filteredItems[idx];
                      final cartMatch = _cart.where((c) => c.item.id == item.id).firstOrNull;
                      final cartQty = cartMatch?.quantity ?? 0;
                      return WaiterMenuCard(
                        item: item,
                        cartQuantity: cartQty,
                        onAdd: () => _addItem(item),
                        onIncrement: () => _incrementByItem(item),
                        onDecrement: () => _decrementByItem(item),
                      );
                    },
                    childCount: filteredItems.length,
                  ),
                ),
        ),
      ],
    );

    // Cart View Component
    final cartView = WaiterCartPanel(
      isWide: !isMobile,
      selectedTableId: _selectedTableId,
      selectedTableLabel: selectedTableLabel,
      cart: _cart,
      initialCart: _initialCart,
      activeOrderId: _activeOrderId,
      notesController: _notesController,
      isSubmitting: _isSubmitting,
      cartTotal: _cartTotal,
      onIncrement: _incrementItem,
      onDecrement: _decrementItem,
      onRemove: _removeItem,
      onClearCart: _clearCart,
      onSubmit: _submitOrderToKitchenAndPos,
    );

    final safeTab = _mobileTabIndex.clamp(0, 1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: WaiterAppBar(
        waiterName: _waiterName,
        onRefresh: _loadMenuAndTables,
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: safeTab,
              onTap: (idx) => setState(() => _mobileTabIndex = idx.clamp(0, 1)),
              selectedItemColor: const Color(0xFFF59E0B),
              unselectedItemColor: const Color(0xFF94A3B8),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Menu & Tables',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text('${_cart.length}'),
                    isLabelVisible: _cart.isNotEmpty,
                    backgroundColor: const Color(0xFFF59E0B),
                    child: const Icon(Icons.receipt_long_rounded),
                  ),
                  label: 'Order Cart (₹${_cartTotal.toStringAsFixed(0)})',
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (isMobile
              ? Stack(
                  children: [
                    IndexedStack(
                      index: safeTab,
                      children: [
                        menuView,
                        cartView,
                      ],
                    ),
                    // Floating Quick View Order Pill when viewing Menu with active items
                    if (safeTab == 0 && _cart.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFF59E0B),
                          child: InkWell(
                            onTap: () => setState(() => _mobileTabIndex = 1),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_cart.length} ${_cart.length == 1 ? 'item' : 'items'} on $selectedTableLabel',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Total: ₹${_cartTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Row(
                                    children: [
                                      Text(
                                        'View Order',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    // LEFT: Table Selector, Search, Category Chips & Menu Items
                    Expanded(child: menuView),

                    // Draggable Split Resizer Divider Handle
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _cartWidth = (_cartWidth - details.delta.dx).clamp(280.0, 560.0);
                          });
                        },
                        onDoubleTap: () {
                          setState(() {
                            _cartWidth = 360.0;
                          });
                        },
                        child: Container(
                          width: 12,
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // RIGHT: Order Cart Pad with adjustable width
                    SizedBox(
                      width: _cartWidth,
                      height: double.infinity,
                      child: cartView,
                    ),
                  ],
                )),
    );
  }
}
