import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../services/shop_service.dart';
import 'pos_billing_dialogs.dart';
import 'pos_cart_bottom_section.dart';
import 'pos_cart_header_section.dart';
import 'pos_cart_item_tile.dart';
import 'pos_order_action_controller.dart';

/// Reusable, modular Cart & Checkout Panel for the Restaurant POS Billing Screen.
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
          // 1. Fixed Header Section (Table Selector + Customer Bar + Active Order Banner + Clear Cart)
          PosCartHeaderSection(
            posState: posState,
            liveTables: widget.liveTables,
            customersList: customersList,
            onSelectFloor: posNotifier.selectFloor,
            onSelectTable: (tableId) => widget.onSelectTable(tableId, posNotifier),
            onRefreshTables: widget.onRefreshTables,
            onSelectCustomer: (cust) {
              final name = cust['name']?.toString() ?? '';
              final phone = cust['phone']?.toString() ?? '';
              posNotifier.setCustomer(name, phone);
            },
            onClearCustomer: () => posNotifier.setCustomer('', ''),
            onAddNewCustomer: () => PosBillingDialogs.showAddCustomerDialog(context, posNotifier),
            onClearCart: () => PosOrderActionController.handleClearCart(
              context: context,
              ref: ref,
              posNotifier: posNotifier,
              posState: posState,
            ),
          ),

          // 2. Scrollable Middle Cart Items Section
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
                      child: Text(
                        'No items in order cart',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
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

          // 3. Fixed Bottom Section (Notes + Bill Summary + Checkout Action Buttons)
          PosCartBottomSection(
            posState: posState,
            onNotesChanged: posNotifier.setOrderNotes,
            onAddDiscount: () => PosBillingDialogs.showDiscountDialog(context, posNotifier),
            onSaveHold: () => PosOrderActionController.handleSaveHold(
              context: context,
              ref: ref,
              posState: posState,
              onReloadMenu: widget.onReloadMenu,
              onSelectTable: widget.onSelectTable,
            ),
            onPrintKot: () => PosOrderActionController.handlePrintKot(
              context: context,
              ref: ref,
              posState: posState,
              liveTables: widget.liveTables,
              onReloadMenu: widget.onReloadMenu,
              onSelectTable: widget.onSelectTable,
            ),
            onPrintBill: () => PosOrderActionController.handlePrintCustomerBill(
              context: context,
              ref: ref,
              posState: posState,
              liveTables: widget.liveTables,
              shopSettings: widget.shopSettings,
              activeOutlet: widget.activeOutlet,
              onReloadMenu: widget.onReloadMenu,
              onSelectTable: widget.onSelectTable,
            ),
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
    );
  }
}
