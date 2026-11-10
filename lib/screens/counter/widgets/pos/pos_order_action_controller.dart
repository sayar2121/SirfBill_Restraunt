import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/kitchen_display_provider.dart';
import '../../../../providers/restaurant_order_provider.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../providers/restaurant_table_provider.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../utils/kot_printer_helper.dart';
import 'pos_bill_receipt_modal.dart';

/// Controller handling order holding, clearing, and kitchen dispatch logic for POS
class PosOrderActionController {
  static Future<void> handleClearCart({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosNotifier posNotifier,
    required RestaurantPosState posState,
  }) async {
    if (posState.cart.isEmpty) return;

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

      await ref.read(restaurantOrderProvider.notifier).cancelOrder(orderId);

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

  static Future<void> handleSaveHold({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState posState,
    required VoidCallback onReloadMenu,
    required Future<void> Function(String tableId, RestaurantPosNotifier posNotifier, {bool showFeedback}) onSelectTable,
  }) async {
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
        // Reset KDS ticket status so newly added running items appear active in the kitchen
        ref.read(kitchenDisplayProvider.notifier).resetTicketForNewItems(posState.activeOrderId!);
        ref.read(restaurantOrderProvider.notifier).loadOrders();
        ref.read(restaurantTableProvider.notifier).loadTables();
        ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
        onReloadMenu();
        if (tableId != null) {
          await onSelectTable(
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
      onReloadMenu();

      if (posState.orderType == OrderType.dineIn && tableId != null) {
        await onSelectTable(
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

  static Future<void> handlePrintKot({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState posState,
    required List<DiningTable> liveTables,
    required VoidCallback onReloadMenu,
    Future<void> Function(String tableId, RestaurantPosNotifier posNotifier, {bool showFeedback})? onSelectTable,
  }) async {
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items first.')),
      );
      return;
    }

    final cartSnapshot = List<PosCartItem>.from(posState.cart);

    String? tableLabel;
    String? floor = posState.selectedFloor;
    if (posState.orderType == OrderType.dineIn && posState.selectedTableId != null) {
      final matchingTable = liveTables.where((t) => t.id == posState.selectedTableId).firstOrNull;
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

    // If this table already has an active order, append new items instead of failing to recreate
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

      final itemsToSend = deltaItems.isNotEmpty ? deltaItems : cartSnapshot;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispatching running items to Kitchen for order ${posState.activeOrderNumber ?? ""}...')),
      );

      await RestaurantPosService.appendItemsToOrder(
        orderId: posState.activeOrderId!,
        newItems: itemsToSend,
        expectedVersion: posState.activeOrderVersion ?? 1,
      );

      final orderNum = posState.activeOrderNumber ?? 'ORD';
      final kotNum = 'KOT-${orderNum.replaceAll("#", "")}';

      ref.read(kitchenDisplayProvider.notifier).resetTicketForNewItems(posState.activeOrderId!);
      ref.read(restaurantOrderProvider.notifier).loadOrders();
      ref.read(restaurantTableProvider.notifier).loadTables();
      ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
      onReloadMenu();

      final tableId = posState.selectedTableId;
      if (posState.orderType == OrderType.dineIn && tableId != null && onSelectTable != null) {
        await onSelectTable(
          tableId,
          ref.read(restaurantPosProvider.notifier),
          showFeedback: false,
        );
      }

      if (context.mounted) {
        KotPrinterHelper.printKotDirectly(
          context: context,
          kotNumber: kotNum,
          orderNumber: orderNum,
          orderType: orderTypeStr,
          tableLabel: tableLabel,
          floor: floor,
          customerName: custName,
          orderNotes: notes,
          items: itemsToSend,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KOT sent to kitchen for updated items on $orderNum!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      return;
    }

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
    onReloadMenu();
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

  /// Generates and previews/prints the Table Bill / Pre-Settlement Check for the customer before payment.
  /// The order remains active and the table remains occupied/reserved!
  static Future<void> handlePrintCustomerBill({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState posState,
    required List<DiningTable> liveTables,
    required Map<String, dynamic>? shopSettings,
    required Shop? activeOutlet,
    required VoidCallback onReloadMenu,
    required Future<void> Function(String tableId, RestaurantPosNotifier posNotifier, {bool showFeedback}) onSelectTable,
  }) async {
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items to print bill.')),
      );
      return;
    }

    final cartSnapshot = List<PosCartItem>.from(posState.cart);
    String orderId = posState.activeOrderId ?? '';
    String orderNumber = posState.activeOrderNumber ?? '';

    // If order is not yet created on backend, save it first so table is officially occupied
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving table order & generating customer bill...')),
      );

      final res = await RestaurantPosService.sendToKitchen(
        orderType: posState.orderType.name,
        tableId: posState.orderType == OrderType.dineIn ? posState.selectedTableId : null,
        cartItems: cartSnapshot,
        customerName: posState.customerName,
        customerPhone: posState.customerPhone,
        orderNotes: posState.orderNotes,
      );

      if (res != null && res['id'] != null) {
        orderId = res['id'].toString();
        orderNumber = res['order_number']?.toString() ?? 'ORD-$orderId';

        ref.read(restaurantOrderProvider.notifier).loadOrders();
        ref.read(restaurantTableProvider.notifier).loadTables();
        onReloadMenu();

        if (posState.orderType == OrderType.dineIn && posState.selectedTableId != null) {
          await onSelectTable(
            posState.selectedTableId!,
            ref.read(restaurantPosProvider.notifier),
            showFeedback: false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save order to table. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    } else {
      // Order already exists — if new delta items were added, append them first
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

      if (deltaItems.isNotEmpty) {
        try {
          await RestaurantPosService.appendItemsToOrder(
            orderId: orderId,
            newItems: deltaItems,
            expectedVersion: posState.activeOrderVersion ?? 1,
          );
          ref.read(kitchenDisplayProvider.notifier).resetTicketForNewItems(orderId);
          ref.read(restaurantOrderProvider.notifier).loadOrders();
          ref.read(restaurantTableProvider.notifier).loadTables();
          ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
          onReloadMenu();
        } catch (_) {}
      }
    }

    // Resolve outlet details for bill header
    Shop? outlet = activeOutlet;
    if (outlet == null) {
      try {
        final shops = await ShopService.getShops();
        final currentShopId = await InventoryService.getShopId();
        if (shops.isNotEmpty) {
          outlet = shops.firstWhere((s) => s.id == currentShopId, orElse: () => shops.first);
        }
      } catch (_) {}
    }

    final shopName = (outlet?.name.trim().isNotEmpty ?? false)
        ? outlet!.name.trim()
        : ((shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
            ? shopSettings!['shop_name'].toString()
            : 'SirfBill Restaurant');

    final hasOutletLocation = outlet != null && outlet.location.trim().isNotEmpty && outlet.location != 'N/A';
    final address = hasOutletLocation
        ? outlet.location
        : (shopSettings?['address']?.toString() ?? shopSettings?['shop_address']?.toString() ?? '');

    final hasOutletContact = outlet != null && outlet.contact.trim().isNotEmpty && outlet.contact != 'N/A';
    final phone = hasOutletContact
        ? outlet.contact
        : (shopSettings?['phone']?.toString() ?? shopSettings?['mobile']?.toString() ?? '');

    final shopGstNo = (outlet?.gstin?.trim().isNotEmpty ?? false)
        ? outlet!.gstin!
        : (shopSettings?['gst_number']?.toString() ??
            shopSettings?['shop_gst_no']?.toString() ??
            shopSettings?['gstin']?.toString() ??
            '');

    final fssaiNo = outlet?.fssai ??
        shopSettings?['fssai']?.toString() ??
        shopSettings?['cin_number']?.toString() ??
        shopSettings?['drug_licence']?.toString() ??
        '';

    final upiId = (outlet?.upiId != null && outlet!.upiId!.trim().isNotEmpty)
        ? outlet.upiId!.trim()
        : (shopSettings?['upi_id']?.toString() ?? '');

    String? tableLabel;
    String? floor = posState.selectedFloor;
    if (posState.orderType == OrderType.dineIn && posState.selectedTableId != null) {
      final matchingTable = liveTables.where((t) => t.id == posState.selectedTableId).firstOrNull;
      if (matchingTable != null) {
        tableLabel = matchingTable.label;
        if (matchingTable.floor.isNotEmpty) floor = matchingTable.floor;
      } else {
        tableLabel = posState.selectedTableId;
      }
    }

    Uint8List? printDocBytes;
    try {
      final kotNumber = 'KOT-${orderNumber.replaceAll("#", "").replaceAll("ORD-", "")}';
      printDocBytes = await KotPrinterHelper.generateCombinedTakeawayPdf(
        kotNumber: kotNumber,
        orderNumber: orderNumber,
        orderType: posState.orderType == OrderType.dineIn ? 'Dine-in (Pre-Bill)' : 'Customer Bill',
        tableLabel: tableLabel,
        floor: floor,
        customerName: posState.customerName.isNotEmpty ? posState.customerName : 'Guest',
        customerPhone: posState.customerPhone,
        orderNotes: posState.orderNotes,
        items: cartSnapshot,
        subtotal: posState.subtotal,
        discount: posState.discountAmount,
        tax: posState.gstAmount,
        grandTotal: posState.grandTotal,
        shopName: shopName,
        address: address,
        phone: phone,
        shopGstNo: shopGstNo,
        fssaiNo: fssaiNo,
        upiId: upiId,
        logoUrl: outlet?.logoUrl ?? shopSettings?['logo_url'],
      );
    } catch (e) {
      debugPrint('Warning: Local thermal bill generation failed: $e');
      try {
        printDocBytes = await RestaurantPosService.fetchBackendBillPdfBytes(orderId);
      } catch (_) {}
    }

    if (context.mounted && printDocBytes != null) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: orderNumber,
        title: tableLabel != null ? 'Table $tableLabel • Customer Bill' : 'Customer Bill',
        pdfBytes: printDocBytes,
      );
    }
  }
}

