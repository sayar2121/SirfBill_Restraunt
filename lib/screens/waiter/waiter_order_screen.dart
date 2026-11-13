import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/restaurant_pos_models.dart';
import '../../providers/kitchen_display_provider.dart';
import '../../providers/restaurant_order_provider.dart';
import '../../providers/restaurant_table_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/kitchen_audio_service.dart';
import '../../services/restaurant_pos_service.dart';
import '../../services/shop_service.dart';
import '../../services/shop_settings_service.dart';
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
  String _restaurantName = '';
  String _activeFloor = '';
  String? _selectedTableId;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Real-time tracking of active orders on seated tables
  String? _activeOrderId;
  int? _activeOrderVersion;
  List<PosCartItem> _initialCart = [];

  // Responsive controls: Mobile tab index & Desktop draggable cart width
  int _mobileTabIndex = 0;
  double _cartWidth = 360.0;

  List<PosMenuItem> _catalog = [];
  List<MenuCategory> _categories = [];
  Timer? _refreshTimer;
  final Set<String> _notifiedReadyTicketIds = {};
  final Set<String> _servedTicketIds = {};

  // Cart managed locally or synced with POS provider for this table
  final List<PosCartItem> _cart = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWaiterInfo();
    _loadMenuAndTables();

    // Auto-refresh tables, orders, and kitchen tickets state every 3 seconds for real-time live sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
        ref.read(restaurantOrderProvider.notifier).loadOrders();
        ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
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

    String restaurantName = prefs.getString('assigned_outlet_name') ?? '';
    if (restaurantName.isEmpty) {
      restaurantName = prefs.getString('shop_name') ?? '';
    }
    if (restaurantName.isEmpty) {
      try {
        final settings = await ShopSettingsService.getSettings();
        final n = settings['shop_name']?.toString();
        if (n != null && n.trim().isNotEmpty) {
          restaurantName = n.trim();
        }
      } catch (_) {}
    }
    if (restaurantName.isEmpty) {
      try {
        final shops = await ShopService.getShops();
        final targetShopId = prefs.getString('selected_shop_id') ?? '';
        final matched = shops.where((s) => s.id == targetShopId).firstOrNull ?? shops.firstOrNull;
        if (matched != null && matched.name.isNotEmpty) {
          restaurantName = matched.name;
        }
      } catch (_) {}
    }
    if (restaurantName.isEmpty) {
      restaurantName = 'SirfBill Restaurant';
    }

    if (mounted) {
      setState(() {
        _waiterName = name;
        _restaurantName = restaurantName;
      });
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

      // Refresh live dining tables, orders, and KDS tickets
      await ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      await ref.read(restaurantOrderProvider.notifier).loadOrders();
      ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);

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
      _activeOrderVersion = 1;
      _initialCart = [];
      _cart.clear();
      _notesController.clear();
    });

    // 1. Fetch live order from dedicated table endpoint
    Map<String, dynamic>? active = await RestaurantPosService.fetchActiveOrderByTable(table.id);

    // If order is settled, cancelled or paid, treat table as empty
    if (active != null) {
      final statusStr = (active['status'] ?? active['order_status'] ?? '').toString().toUpperCase();
      final paymentStatusStr = (active['payment_status'] ?? '').toString().toUpperCase();
      if (statusStr.contains('CANCEL') ||
          statusStr.contains('SETTLE') ||
          statusStr.contains('VOID') ||
          paymentStatusStr.contains('PAID')) {
        active = null;
      }
    }

    // 2. Fallback: match from live orders in provider or fresh API fetch
    // Matches active, held, or served dine-in orders that haven't been paid/settled!
    RestaurantOrder? matchingOrder;
    List<RestaurantOrder> ordersList = ref.read(restaurantOrderProvider).orders;
    if (ordersList.isEmpty) {
      try {
        ordersList = await RestaurantPosService.fetchOrders(limit: 100);
      } catch (_) {}
    }

    final targetId = table.id.trim().toLowerCase();
    final targetLabel = table.label.trim().toLowerCase();
    final targetCleanNum = targetLabel.replaceAll(RegExp(r'[^0-9]'), '');

    for (final ord in ordersList) {
      if (ord.paymentStatus == PaymentStatus.paid ||
          ord.status == OrderStatus.cancelled) {
        continue;
      }

      final ordId = (ord.tableId ?? '').trim().toLowerCase();
      final ordLabel = (ord.tableLabel ?? '').trim().toLowerCase();
      final ordCleanNum = ordLabel.replaceAll(RegExp(r'[^0-9]'), '');

      bool isMatch = false;
      if (ordId.isNotEmpty && (ordId == targetId || ordId == targetLabel)) {
        isMatch = true;
      } else if (ordLabel.isNotEmpty && (ordLabel == targetLabel || ordLabel == targetId)) {
        isMatch = true;
      } else if (targetCleanNum.isNotEmpty && ordCleanNum.isNotEmpty && targetCleanNum == ordCleanNum) {
        isMatch = true;
      }

      if (isMatch) {
        matchingOrder = ord;
        break;
      }
    }

    if (active == null && matchingOrder != null) {
      try {
        active = await RestaurantPosService.fetchOrderById(matchingOrder.id);
      } catch (_) {}
    }

    // 3. Extract items from active payload OR from matchingOrder
    final List<PosCartItem> loadedItems = [];
    String? resolvedOrderId;
    String? resolvedOrderNumber;
    int resolvedVersion = 1;
    String? resolvedNotes;

    final rawLines = active?['lines'] ?? active?['items'] ?? active?['order_lines'];
    if (active != null && rawLines is List && rawLines.isNotEmpty) {
      resolvedOrderId = (active['id'] ?? active['order_id'])?.toString();
      resolvedOrderNumber = (active['order_number'] ?? active['order_no'])?.toString();
      resolvedVersion = (active['version'] is num)
          ? (active['version'] as num).toInt()
          : (int.tryParse(active['version']?.toString() ?? '1') ?? 1);
      resolvedNotes = active['notes']?.toString();

      for (final l in rawLines) {
        final itemId = (l['item_id'] ?? l['menu_item_id'] ?? l['id'] ?? '').toString();
        final itemName = (l['item_name'] ?? l['name'] ?? 'Item').toString();
        final rawQty = l['quantity'] ?? l['qty'] ?? 1;
        final qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
        final rawPrice = l['unit_price'] ?? l['price'] ?? 0.0;
        final unitPrice = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
        final rawTax = l['tax_rate'] ?? l['tax'] ?? 5.0;
        final taxRate = (rawTax is num) ? rawTax.toDouble() : (double.tryParse(rawTax.toString()) ?? 5.0);

        final existingIdx = loadedItems.indexWhere((c) => c.item.id == itemId);
        if (existingIdx >= 0) {
          loadedItems[existingIdx] = loadedItems[existingIdx].copyWith(
            quantity: loadedItems[existingIdx].quantity + qty,
          );
        } else {
          final matched = _catalog.where((c) => c.id == itemId).firstOrNull ??
              PosMenuItem(
                id: itemId,
                name: itemName,
                price: unitPrice,
                categoryId: l['category_id']?.toString() ?? 'all',
                taxPercent: taxRate,
              );

          loadedItems.add(PosCartItem(
            item: matched,
            quantity: qty,
            notes: (l['special_instructions'] ?? l['notes'])?.toString(),
          ));
        }
      }
    } else if (matchingOrder != null && matchingOrder.items.isNotEmpty) {
      resolvedOrderId = matchingOrder.id;
      resolvedOrderNumber = matchingOrder.orderNumber;
      resolvedNotes = matchingOrder.notes;
      try {
        final fresh = await RestaurantPosService.fetchOrderById(matchingOrder.id);
        if (fresh != null && fresh['version'] != null) {
          resolvedVersion = (fresh['version'] is num)
              ? (fresh['version'] as num).toInt()
              : (int.tryParse(fresh['version'].toString()) ?? 1);
        }
      } catch (_) {}
      loadedItems.addAll(matchingOrder.items.map((i) => i.copyWith()));
    }

    // 4. Update state with loaded existing order
    if (loadedItems.isNotEmpty && mounted) {
      setState(() {
        _activeOrderId = resolvedOrderId;
        _activeOrderVersion = resolvedVersion;
        _cart.clear();
        _cart.addAll(loadedItems);
        _initialCart = List.from(loadedItems);
        if (resolvedNotes != null && resolvedNotes.isNotEmpty) {
          _notesController.text = resolvedNotes;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded active order for ${table.label} (${resolvedOrderNumber ?? ""})'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
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
    final notes = _notesController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    final outletId = prefs.getString('selected_shop_id') ??
        prefs.getString('assigned_outlet_id') ??
        await InventoryService.getShopId();

    try {
      final wasExistingOrder = _activeOrderId != null && _initialCart.isNotEmpty;

      // 1. If this table already has an active order on backend, compute delta running items
      if (wasExistingOrder) {
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
        final updateRes = await RestaurantPosService.appendItemsToOrder(
          orderId: _activeOrderId!,
          newItems: deltaItems,
          expectedVersion: _activeOrderVersion ?? 1,
        );

        if (updateRes == null) {
          throw Exception('Backend could not update existing order. Please refresh and try again.');
        }

        // Explicitly ensure order status transitions back to SENT_TO_KITCHEN so KDS on any tablet displays it as active!
        try {
          await RestaurantPosService.transitionOrderStatus(
            orderId: _activeOrderId!,
            targetStatus: 'SENT_TO_KITCHEN',
          );
        } catch (_) {}

        // Update KDS live status (already prepared items stay SERVED/DONE, delta items get NEW ADDED)
        ref.read(kitchenDisplayProvider.notifier).markRunningItemsForOrder(
          orderId: _activeOrderId!,
          existingPreparedItemIds: _initialCart.map((e) => e.item.id).toList(),
          newlyAddedItemIds: deltaItems.map((d) => d.item.id).toList(),
        );
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

        // Update KDS
        ref.read(kitchenDisplayProvider.notifier).markRunningItemsForOrder(
          orderId: res?['id']?.toString() ?? _selectedTableId!,
          existingPreparedItemIds: const [],
          newlyAddedItemIds: _cart.map((c) => c.item.id).toList(),
        );
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
                    wasExistingOrder
                        ? 'Running items sent to Kitchen for $tableLabel!'
                        : 'Order placed & synchronized with POS & Kitchen for $tableLabel!',
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

  void _showReadyOrdersDialog(BuildContext context, List<KitchenTicket> readyTickets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.room_service_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ready for Service',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${readyTickets.length} order(s) cooked & ready to serve',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Ticket List
              Flexible(
                child: readyTickets.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No orders are currently awaiting service'),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: readyTickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final ticket = readyTickets[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ticket.tableLabel != null ? 'Table ${ticket.tableLabel}' : 'Takeaway',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ticket.orderNumber,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        Navigator.pop(sheetCtx);
                                        _servedTicketIds.add(ticket.id);
                                        _notifiedReadyTicketIds.add(ticket.id);
                                        KitchenAudioService.stop();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        }
                                        if (mounted) setState(() {});
                                        await ref.read(kitchenDisplayProvider.notifier).updateTicketStatus(
                                          ticket.id,
                                          KotStatus.served,
                                        );
                                        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
                                        ref.read(restaurantOrderProvider.notifier).loadOrders();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Order for Table ${ticket.tableLabel ?? ""} marked as Served!'),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Mark Served'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: ticket.items.map((item) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Text(
                                        '${item.quantity}x ${item.name}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableState = ref.watch(restaurantTableProvider);
    final tables = tableState.tables;

    // Live kitchen ticket status for ready orders
    final kdsState = ref.watch(kitchenDisplayProvider);
    final readyTickets = kdsState.tickets
        .where((t) => t.status == KotStatus.ready && !_servedTicketIds.contains(t.id))
        .toList();
    final readyTableLabels = readyTickets.map((t) => t.tableLabel?.trim()).whereType<String>().toSet();

    // Clean up notified and served IDs ONLY when tickets disappear entirely from active tickets
    final activeTicketIds = kdsState.tickets.map((t) => t.id).toSet();
    _notifiedReadyTicketIds.removeWhere((id) => !activeTicketIds.contains(id));
    _servedTicketIds.removeWhere((id) => !activeTicketIds.contains(id));

    // If an existing order has new running items added that kitchen hasn't prepared yet,
    // allow notification to fire again when those new items are cooked and marked ready!
    for (final ticket in kdsState.tickets) {
      final hasUnpreparedRunningItems = ticket.items.any((it) => it.isRunningItem && !it.isPrepared);
      if (hasUnpreparedRunningItems) {
        _servedTicketIds.remove(ticket.id);
        _notifiedReadyTicketIds.remove(ticket.id);
      }
    }

    // Trigger audible chime and toast notification when an order is marked ready by the kitchen
    final newlyReadyTickets = readyTickets
        .where((t) => !_notifiedReadyTicketIds.contains(t.id) && !_servedTicketIds.contains(t.id))
        .toList();
    if (newlyReadyTickets.isNotEmpty) {
      for (final t in newlyReadyTickets) {
        _notifiedReadyTicketIds.add(t.id);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        KitchenAudioService.playNewOrderAlert();
        final firstTicket = newlyReadyTickets.first;
        final targetTable = firstTicket.tableLabel != null && firstTicket.tableLabel!.isNotEmpty
            ? 'Table ${firstTicket.tableLabel}'
            : 'Order ${firstTicket.orderNumber}';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔔 $targetTable is READY!',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const Text(
                        'Food is cooked and ready for pickup from kitchen',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'SERVE NOW',
              textColor: Colors.white,
              onPressed: () => _showReadyOrdersDialog(context, readyTickets),
            ),
          ),
        );
      });
    }

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

    // Touch-optimized, pinned top control bar and scrollable dish catalog
    final menuView = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Order Ready Alert Banner (Visible when any kitchen order is ready for pickup & serving)
        if (readyTickets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.room_service_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          readyTickets.length == 1
                              ? 'Order Ready for Table ${readyTickets.first.tableLabel ?? "Dine-in"}!'
                              : '${readyTickets.length} Orders Ready to Serve!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          readyTickets.length == 1
                              ? '${readyTickets.first.items.length} item(s) cooked • Pick up from kitchen & serve'
                              : 'Ready for: ${readyTickets.map((t) => t.tableLabel ?? "").where((l) => l.isNotEmpty).join(", ")}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showReadyOrdersDialog(context, readyTickets),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Serve Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF059669),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 2. Sticky Table Strip (Anchored permanently at top)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: WaiterTableStrip(
            tables: tables,
            readyTableLabels: readyTableLabels,
            selectedFloor: _activeFloor,
            selectedTableId: _selectedTableId,
            onSelectFloor: (f) => setState(() => _activeFloor = f),
            onSelectTable: _selectTable,
            onRefresh: () => ref.read(restaurantTableProvider.notifier).loadTables(),
          ),
        ),

        // 3. Sticky Category Filters & Search Bar (Anchored permanently at top)
        WaiterCategoryStrip(
          categories: _categories,
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
          onSelectCategory: (catId) => setState(() => _selectedCategory = catId),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onClearSearch: () => setState(() => _searchQuery = ''),
        ),
        const SizedBox(height: 6),

        // 4. Scrollable Food Dishes Grid (Only this section scrolls underneath!)
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
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
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final menuWidth = constraints.maxWidth;
                    final int cols;
                    if (menuWidth >= 1150) {
                      cols = 5;
                    } else if (menuWidth >= 880) {
                      cols = 4;
                    } else if (menuWidth >= 580) {
                      cols = 3;
                    } else if (menuWidth >= 340) {
                      cols = 2;
                    } else {
                      cols = 1;
                    }

                    final cardWidth = (menuWidth - (cols - 1) * 10 - 28) / cols;
                    final cardHeight = (cardWidth * 10 / 16) + 78;
                    final ratio = (cardWidth / cardHeight).clamp(0.82, 1.15);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: ratio,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, idx) {
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
                    );
                  },
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
        restaurantName: _restaurantName,
        readyOrdersCount: readyTickets.length,
        onOpenReadyNotifications: () => _showReadyOrdersDialog(context, readyTickets),
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
