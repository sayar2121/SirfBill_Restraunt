import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/restaurant_pos_models.dart';
import '../../providers/counter_providers.dart';
import '../../providers/kitchen_display_provider.dart';
import '../../providers/restaurant_order_provider.dart';
import '../../providers/restaurant_pos_provider.dart';
import '../../providers/restaurant_table_provider.dart';
import '../../services/auth_service.dart';
import '../../services/restaurant_pos_service.dart';
import '../../utils/kot_printer_helper.dart';
import '../counter/widgets/pos/pos_menu_card.dart';
import '../counter/widgets/pos/pos_table_selector.dart';

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

    // Auto-refresh tables state every 10 seconds so occupied tables stay up to date
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
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
      final items = await RestaurantPosService.fetchMenuItems();
      final categories = await RestaurantPosService.fetchCategories();
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
      _cart.clear();
      _notesController.clear();
    });

    // If table is already occupied, load its existing active order so waiter can add running items
    if (table.status == TableStatus.occupied) {
      final active = await RestaurantPosService.fetchActiveOrderByTable(table.id);
      if (active != null && active['lines'] is List) {
        final List lines = active['lines'];
        for (final l in lines) {
          final itemId = l['item_id']?.toString() ?? '';
          final itemName = l['item_name']?.toString() ?? 'Item';
          final qty = (l['quantity'] is num) ? (l['quantity'] as num).toInt() : 1;
          final unitPrice = double.tryParse(l['unit_price']?.toString() ?? '0') ?? 0.0;
          final matched = _catalog.where((c) => c.id == itemId).firstOrNull ??
              PosMenuItem(
                id: itemId,
                name: itemName,
                price: unitPrice,
                categoryId: 'all',
              );
          _cart.add(PosCartItem(
            item: matched,
            quantity: qty,
            notes: l['special_instructions']?.toString(),
          ));
        }
        if (mounted) setState(() {});
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

  double get _cartTotal =>
      _cart.fold(0.0, (sum, i) => sum + (i.item.price * i.quantity));

  Future<void> _submitOrderToKitchenAndPos() async {
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table.')),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Please add items.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final tables = ref.read(restaurantTableProvider).tables;
    final matchedTable = tables.where((t) => t.id == _selectedTableId).firstOrNull;
    final tableLabel = matchedTable?.label ?? 'Table $_selectedTableId';
    final floor = matchedTable?.floor ?? '1st Floor';
    final notes = _notesController.text.trim();

    try {
      // 1. Dispatch order to backend (which automatically marks table OCCUPIED & syncs POS)
      final res = await RestaurantPosService.sendToKitchen(
        orderType: 'DINE_IN',
        tableId: _selectedTableId,
        cartItems: _cart,
        customerName: 'Served by: $_waiterName',
        orderNotes: notes,
      );

      final orderNum = res?['order_number']?.toString() ??
          '#ORD-${DateTime.now().millisecondsSinceEpoch % 10000}';
      final kotNum = 'KOT-${orderNum.replaceAll("#", "")}';

      // 2. Add or refresh ticket in Kitchen Display System
      ref.read(kitchenDisplayProvider.notifier).markRunningItemsForOrder(
            orderId: res?['id']?.toString() ?? _selectedTableId!,
            existingPreparedItemIds: const [],
            newlyAddedItemIds: _cart.map((c) => c.item.id).toList(),
          );

      // 3. Print KOT if thermal printer is configured
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

      // 4. Reload Tables and Live Orders state
      await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      await ref.read(restaurantOrderProvider.notifier).loadOrders();
      ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);

      if (mounted) {
        setState(() {
          _cart.clear();
          _notesController.clear();
          _selectedTableId = null;
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
                    'Order for $tableLabel placed & sent to Kitchen! ($orderNum)',
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.room_service_rounded,
                  color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiter Order Pad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Staff: $_waiterName',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Menu & Tables',
            onPressed: _loadMenuAndTables,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) context.go('/dashboard');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return Row(
                  children: [
                    // LEFT: Menu Discovery & Table Picker
                    Expanded(
                      flex: isWide ? 65 : 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Table Selector Header Card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: PosTableSelector(
                              selectedFloor: _activeFloor,
                              selectedTableId: _selectedTableId,
                              tables: tables,
                              onSelectFloor: (f) => setState(() => _activeFloor = f),
                              onSelectTable: (tid) {
                                final match =
                                    tables.where((t) => t.id == tid).firstOrNull;
                                if (match != null) _selectTable(match);
                              },
                              onRefresh: () => ref
                                  .read(restaurantTableProvider.notifier)
                                  .loadTables(),
                            ),
                          ),

                          // 2. Search & Category Filter Pills
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.search_rounded,
                                          size: 18),
                                      hintText: 'Search dish name or code...',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Categories Horizontal Strip
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final isAll = index == 0;
                                final catId = isAll ? 'all' : _categories[index - 1].id;
                                final catName =
                                    isAll ? 'All Items' : _categories[index - 1].name;
                                final isSelected = _selectedCategory == catId;

                                return ChoiceChip(
                                  label: Text(catName),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = catId),
                                  selectedColor: const Color(0xFFF59E0B),
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 3. Grid of Food Dishes
                          Expanded(
                            child: filteredItems.isEmpty
                                ? const Center(child: Text('No menu items found'))
                                : GridView.builder(
                                    padding:
                                        const EdgeInsets.fromLTRB(14, 4, 14, 14),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isWide ? 4 : 3,
                                      childAspectRatio: 1.05,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: filteredItems.length,
                                    itemBuilder: (context, idx) {
                                      final item = filteredItems[idx];
                                      return PosMenuCard(
                                        item: item,
                                        onTap: () => _addItem(item),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT: Waiter Order Cart & Action Button
                    Container(
                      width: isWide ? 380 : 320,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _selectedTableId == null
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFFEF3C7),
                              border: const Border(
                                bottom: BorderSide(color: Color(0xFFFDE68A)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.table_bar_rounded,
                                  color: _selectedTableId == null
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTableId != null
                                        ? 'Active Table: ${tables.where((t) => t.id == _selectedTableId).firstOrNull?.label ?? _selectedTableId}'
                                        : 'No Table Selected (Tap Table above)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTableId == null
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cart Items List
                          Expanded(
                            child: _cart.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Order is empty.\nTap dishes to add to this table.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    itemCount: _cart.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 8),
                                    itemBuilder: (context, idx) {
                                      final item = _cart[idx];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.item.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${item.item.price.toStringAsFixed(0)} each',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    size: 20),
                                                color: const Color(0xFFEF4444),
                                                onPressed: () => _decrementItem(idx),
                                              ),
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 20),
                                                color: const Color(0xFF10B981),
                                                onPressed: () => _incrementItem(idx),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),

                          // Notes & Order Total Summary
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              border: Border(
                                top: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _notesController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText:
                                        'Order notes (e.g. less oil, extra chutney)...',
                                    prefixIcon: const Icon(Icons.note_alt_rounded,
                                        size: 16),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Estimated Total',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      '₹${_cartTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitOrderToKitchenAndPos,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.soup_kitchen_rounded),
                                  label: Text(
                                    _isSubmitting
                                        ? 'Dispatching Order...'
                                        : 'Place Order & Send KOT',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
