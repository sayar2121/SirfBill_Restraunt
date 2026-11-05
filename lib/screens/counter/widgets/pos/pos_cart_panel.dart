import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/kitchen_display_provider.dart';
import '../../../../providers/restaurant_order_provider.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../providers/restaurant_table_provider.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../utils/kot_printer_helper.dart';
import 'pos_billing_dialogs.dart';
import 'pos_bill_summary.dart';
import 'pos_bottom_action_bar.dart';
import 'pos_cart_item_tile.dart';
import 'pos_customer_bar.dart';
import 'pos_table_selector.dart';

/// Reusable Cart & Checkout Panel for the Restaurant POS Billing Screen.
class PosCartPanel extends ConsumerStatefulWidget {
  final List<DiningTable> liveTables;
  final List<PosMenuItem> catalog;
  final Map<String, dynamic>? shopSettings;
  final Shop? activeOutlet;
  final Future<void> Function() onRefreshTables;
  final Future<void> Function(String tableId, RestaurantPosNotifier posNotifier, {bool showFeedback}) onSelectTable;
  final VoidCallback onReloadMenu;
  final bool isMobile;

  const PosCartPanel({
    super.key,
    required this.liveTables,
    required this.catalog,
    required this.shopSettings,
    required this.activeOutlet,
    required this.onRefreshTables,
    required this.onSelectTable,
    required this.onReloadMenu,
    this.isMobile = false,
  });

  @override
  ConsumerState<PosCartPanel> createState() => _PosCartPanelState();
}

class _PosCartPanelState extends ConsumerState<PosCartPanel> {
  final ScrollController _cartScrollController = ScrollController();

  @override
  void dispose() {
    _cartScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleClearCart(
    BuildContext context,
    WidgetRef ref,
    RestaurantPosNotifier posNotifier,
    RestaurantPosState posState,
  ) async {
    if (posState.cart.isEmpty) return;

    // If clearing an active saved/held order on a table, cancel it so it doesn't reappear
    final orderId = posState.activeOrderId;
    final tableId = posState.selectedTableId;

    if (orderId != null) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Clear Saved Order?'),
          content: Text(
            'This table has an active order (${posState.activeOrderNumber ?? "saved"}).\n'
            'Do you want to cancel and clear this order from the table?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel & Clear Order'),
            ),
          ],
        ),
      );

      if (shouldCancel != true) return;

      // Cancel the order on backend & state
      await ref.read(restaurantOrderProvider.notifier).cancelOrder(orderId);

      // Release table status to AVAILABLE
      if (tableId != null) {
        await RestaurantPosService.updateTableStatus(tableId, TableStatus.available);
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      }
      ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
      ref.read(restaurantOrderProvider.notifier).loadOrders();
    }

    posNotifier.clearCart(clearCustomer: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared successfully.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleSaveHold(BuildContext context, WidgetRef ref, RestaurantPosState posState) async {
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items to hold.')),
      );
      return;
    }

    final cartSnapshot = List<PosCartItem>.from(posState.cart);
    final custName = posState.customerName;
    final notes = posState.orderNotes;
    final orderTypeStr = posState.orderType.name;

    // Check if updating an existing held order
    if (posState.activeOrderId != null) {
      final List<PosCartItem> deltaItems = [];
      final initialItems = posState.initialCart ?? const <PosCartItem>[];
      for (final cartItem in cartSnapshot) {
        final initialMatch = initialItems
            .where((initItem) => initItem.item.id == cartItem.item.id)
            .firstOrNull;
        final initialQty = initialMatch?.quantity ?? 0;
        final diffQty = cartItem.quantity - initialQty;
        if (diffQty > 0) {
          deltaItems.add(cartItem.copyWith(quantity: diffQty));
        }
      }

      if (deltaItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new items to add to this order.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adding ${deltaItems.length} new item(s) to order ${posState.activeOrderNumber ?? ""}...')),
      );

      final updateRes = await RestaurantPosService.appendItemsToOrder(
        orderId: posState.activeOrderId!,
        newItems: deltaItems,
        expectedVersion: posState.activeOrderVersion ?? 1,
      );

      if (updateRes != null) {
        final orderNum = posState.activeOrderNumber ?? 'Order';
        final tableId = posState.selectedTableId;
        ref.read(restaurantOrderProvider.notifier).loadOrders();
        ref.read(restaurantTableProvider.notifier).loadTables();
        widget.onReloadMenu();
        if (tableId != null) {
          await widget.onSelectTable(
            tableId,
            ref.read(restaurantPosProvider.notifier),
            showFeedback: false,
          );
        } else {
          ref.read(restaurantPosProvider.notifier).clearCart();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$orderNum successfully updated with latest items!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update existing order. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    // Creating new hold order
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving and holding table order...')),
    );

    final res = await RestaurantPosService.sendToKitchen(
      orderType: orderTypeStr,
      tableId: posState.orderType == OrderType.dineIn ? posState.selectedTableId : null,
      cartItems: cartSnapshot,
      customerName: custName,
      customerPhone: posState.customerPhone,
      orderNotes: notes,
    );

    if (res != null) {
      final orderNum = res['order_number']?.toString() ?? 'Order';
      final tableId = posState.selectedTableId;
      ref.read(restaurantOrderProvider.notifier).loadOrders();
      ref.read(restaurantTableProvider.notifier).loadTables();
      widget.onReloadMenu();

      if (posState.orderType == OrderType.dineIn && tableId != null) {
        // Keep the saved order loaded in the cart so it doesn't vanish while still seated on this table
        await widget.onSelectTable(
          tableId,
          ref.read(restaurantPosProvider.notifier),
          showFeedback: false,
        );
      } else {
        ref.read(restaurantPosProvider.notifier).clearCart();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$orderNum placed on Hold! Table is now OCCUPIED.'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save hold order on server.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handlePrintKot(BuildContext context, WidgetRef ref, RestaurantPosState posState) async {
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items first.')),
      );
      return;
    }

    final cartSnapshot = List<PosCartItem>.from(posState.cart);

    // Resolve human-readable table name/number (e.g. 'T1') from tables
    String? tableLabel;
    String? floor = posState.selectedFloor;
    if (posState.orderType == OrderType.dineIn && posState.selectedTableId != null) {
      final matchingTable = widget.liveTables.where((t) => t.id == posState.selectedTableId).firstOrNull;
      if (matchingTable != null) {
        tableLabel = matchingTable.label;
        if (matchingTable.floor.isNotEmpty) floor = matchingTable.floor;
      } else {
        tableLabel = posState.selectedTableId;
      }
    }

    final custName = posState.customerName;
    final notes = posState.orderNotes;
    final orderTypeStr = posState.orderType.name;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending KOT to Kitchen...')),
    );

    final res = await RestaurantPosService.sendToKitchen(
      orderType: orderTypeStr,
      tableId: posState.orderType == OrderType.dineIn ? posState.selectedTableId : null,
      cartItems: cartSnapshot,
      customerName: custName,
      customerPhone: posState.customerPhone,
      orderNotes: notes,
    );

    String generatedOrderNum = '#ORD-${DateTime.now().millisecondsSinceEpoch % 10000}';
    String generatedKotNum = 'KOT #${DateTime.now().millisecondsSinceEpoch % 1000}';

    if (res != null) {
      final orderId = res['id']?.toString() ?? 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}';
      generatedOrderNum = res['order_number']?.toString() ?? '#ORD-${orderId.substring(0, orderId.length > 6 ? 6 : orderId.length)}';
      generatedKotNum = 'KOT-${generatedOrderNum.replaceAll("#", "")}';

      ref.read(restaurantOrderProvider.notifier).addOrder(
        RestaurantOrder(
          id: orderId,
          orderNumber: generatedOrderNum,
          orderType: posState.orderType,
          status: OrderStatus.active,
          paymentStatus: PaymentStatus.pending,
          tableId: posState.selectedTableId,
          tableLabel: tableLabel,
          floor: floor,
          customerName: custName.isNotEmpty ? custName : 'Walk-in Guest',
          customerPhone: posState.customerPhone,
          items: cartSnapshot,
          subtotal: posState.subtotal,
          discount: posState.discountAmount,
          gstAmount: posState.gstAmount,
          grandTotal: posState.grandTotal,
          createdAt: DateTime.now(),
          notes: notes,
        ),
      );
      ref.read(kitchenDisplayProvider.notifier).addTicket(
        KitchenTicket(
          id: orderId,
          kotNumber: generatedKotNum,
          orderNumber: generatedOrderNum,
          orderType: posState.orderType,
          tableLabel: tableLabel,
          floor: floor,
          serverName: custName.isNotEmpty ? custName : 'Waitstaff',
          status: KotStatus.newOrder,
          createdAt: DateTime.now(),
          items: cartSnapshot.map((c) => KotItem(
            id: c.item.id,
            name: c.item.name,
            quantity: c.quantity,
            notes: c.notes,
          )).toList(),
          specialInstruction: notes,
        ),
      );
    }
    ref.read(restaurantOrderProvider.notifier).loadOrders();
    ref.read(restaurantTableProvider.notifier).loadTables();
    ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
    widget.onReloadMenu();
    ref.read(restaurantPosProvider.notifier).clearCart();

    if (context.mounted) {
      KotPrinterHelper.printKotDirectly(
        context: context,
        kotNumber: generatedKotNum,
        orderNumber: generatedOrderNum,
        orderType: orderTypeStr,
        tableLabel: tableLabel,
        floor: floor,
        customerName: custName,
        orderNotes: notes,
        items: cartSnapshot,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(restaurantPosProvider);
    final posNotifier = ref.read(restaurantPosProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final rightPaneBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final customersAsync = ref.watch(customerProvider);
    final customersList = customersAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: rightPaneBg,
        border: widget.isMobile ? null : Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // 1. FIXED TOP SECTION (Table Selector + Customer Bar + Active Order Banner)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Table Selector
                if (posState.orderType == OrderType.dineIn) ...[
                  PosTableSelector(
                    selectedFloor: posState.selectedFloor,
                    selectedTableId: posState.selectedTableId,
                    tables: widget.liveTables,
                    onSelectFloor: posNotifier.selectFloor,
                    onSelectTable: (tableId) => widget.onSelectTable(tableId, posNotifier),
                    onRefresh: widget.onRefreshTables,
                  ),
                  const SizedBox(height: 8),
                ],

                // Customer Bar
                PosCustomerBar(
                  customers: customersList,
                  selectedCustomerName: posState.customerName,
                  selectedCustomerPhone: posState.customerPhone,
                  onSelectCustomer: (cust) {
                    final name = cust['name']?.toString() ?? '';
                    final phone = cust['phone']?.toString() ?? '';
                    posNotifier.setCustomer(name, phone);
                  },
                  onClearCustomer: () {
                    posNotifier.setCustomer('', '');
                  },
                  onAddNew: () => PosBillingDialogs.showAddCustomerDialog(context, posNotifier),
                ),
                const SizedBox(height: 8),

                // Active Order Banner (when editing an existing order)
                if (posState.activeOrderNumber != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing Saved Order: ${posState.activeOrderNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              const Text(
                                'Add new items or modify, then tap "Update Order".',
                                style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HELD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Items Header with Cart Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items (${posState.cart.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    InkWell(
                      onTap: posState.cart.isEmpty
                          ? null
                          : () => _handleClearCart(context, ref, posNotifier, posState),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: posState.cart.isEmpty
                              ? Colors.transparent
                              : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: posState.cart.isEmpty
                                ? Colors.transparent
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_sweep_rounded,
                              size: 16,
                              color: posState.cart.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Clear Cart',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: posState.cart.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 10),
              ],
            ),
          ),

          // 2. SCROLLABLE MIDDLE SECTION (Only cart items list scrolls)
          Expanded(
            child: Scrollbar(
              controller: _cartScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 7.0,
              radius: const Radius.circular(8),
              child: posState.cart.isEmpty
                  ? const Center(
                      child: Text('No items in order cart', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    )
                  : ListView.builder(
                      controller: _cartScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: posState.cart.length,
                      itemBuilder: (context, index) {
                        final cartItem = posState.cart[index];
                        return PosCartItemTile(
                          index: index,
                          item: cartItem,
                          onIncrement: () => posNotifier.incrementQty(index),
                          onDecrement: () => posNotifier.decrementQty(index),
                          onRemove: () => posNotifier.removeItem(index),
                        );
                      },
                    ),
            ),
          ),

          // 3. FIXED BOTTOM SECTION (Notes + Financial Summary + Action Buttons)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: rightPaneBg,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Notes Field
                TextField(
                  onChanged: posNotifier.setOrderNotes,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF94A3B8)),
                    hintText: 'Add order notes (e.g. less spicy, no onion...)',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bill Financials Summary
                PosBillSummary(
                  subtotal: posState.subtotal,
                  discount: posState.discountAmount,
                  gstPercent: posState.gstPercent,
                  gstAmount: posState.gstAmount,
                  grandTotal: posState.grandTotal,
                  onAddDiscount: () => PosBillingDialogs.showDiscountDialog(context, posNotifier),
                ),
                const SizedBox(height: 8),

                // Action Bar (Save/Hold, Print KOT, Payment)
                PosBottomActionBar(
                  activeOrderLabel: posState.activeOrderNumber,
                  onSaveHold: () => _handleSaveHold(context, ref, posState),
                  onPrintKot: () => _handlePrintKot(context, ref, posState),
                  onProceedToPayment: () => PosBillingDialogs.showPaymentDialog(
                    context: context,
                    ref: ref,
                    state: posState,
                    shopSettings: widget.shopSettings,
                    activeOutlet: widget.activeOutlet,
                    tables: widget.liveTables,
                    onReloadMenu: widget.onReloadMenu,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
