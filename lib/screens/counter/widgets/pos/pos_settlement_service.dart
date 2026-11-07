import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/kitchen_display_provider.dart';
import '../../../../providers/restaurant_order_provider.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../providers/restaurant_report_provider.dart';
import '../../../../providers/restaurant_table_provider.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../utils/kot_printer_helper.dart';
import 'pos_bill_receipt_modal.dart';

/// Handles the full settlement flow: Order creation/append -> Settle -> Sync Providers -> Thermal Print.
class PosSettlementService {
  PosSettlementService._();

  static Future<void> completeSettlement({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState state,
    required String selectedMode,
    required Map<String, dynamic>? shopSettings,
    required Shop? activeOutlet,
    required List<DiningTable> tables,
    required VoidCallback onReloadMenu,
  }) async {
    debugPrint('[Settlement] START — context.mounted=${context.mounted}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating order & settling payment...')),
    );

    String orderId;
    String orderNumber;

    // ── Step 1: Create or append to existing order ───────────────────────────
    if (state.activeOrderId != null) {
      orderId = state.activeOrderId!;
      orderNumber = state.activeOrderNumber ?? 'ORD-$orderId';

      final List<PosCartItem> deltaItems = [];
      final initialItems = state.initialCart ?? const <PosCartItem>[];
      for (final cartItem in state.cart) {
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
        // Non-fatal: if appending fails, continue with existing order items.
        try {
          await RestaurantPosService.appendItemsToOrder(
            orderId: orderId,
            newItems: deltaItems,
            expectedVersion: state.activeOrderVersion ?? 1,
          );
        } catch (e) {
          debugPrint('Warning: appendItemsToOrder failed (continuing): $e');
        }
      }
    } else {
      final payMethod = selectedMode.contains('UPI')
          ? 'UPI'
          : (selectedMode.contains('Card') ? 'CARD' : 'CASH');

      // Fatal: if order creation fails, abort everything.
      Map<String, dynamic>? orderRes;
      try {
        orderRes = await RestaurantPosService.sendToKitchen(
          orderType: state.orderType.name,
          tableId: state.orderType == OrderType.dineIn ? state.selectedTableId : null,
          cartItems: state.cart,
          customerName: state.customerName,
          customerPhone: state.customerPhone,
          orderNotes: state.orderNotes,
          paymentMethod: payMethod,
        );
      } catch (e) {
        debugPrint('Error creating order: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating order: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (orderRes == null || orderRes['id'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create order on server. Please check the logs.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      orderId = orderRes['id'].toString();
      orderNumber = orderRes['order_number']?.toString() ?? 'ORD-$orderId';
    }

    debugPrint('[Settlement] Step 2 — orderId=$orderId orderNumber=$orderNumber');
    // ── Step 2: Settle payment ────────────────────────────────────────────────
    // Non-fatal: if settle fails (e.g. already settled, 422 from backend),
    // we still want to clear the cart and show the receipt.
    final payMethod = selectedMode.contains('UPI')
        ? 'UPI'
        : (selectedMode.contains('Card') ? 'CARD' : 'CASH');
    bool settleSuccess = false;
    try {
      settleSuccess = await RestaurantPosService.settleOrder(
        orderId: orderId,
        grandTotal: state.grandTotal,
        paymentMode: payMethod,
        discountAmount: state.discountAmount,
      );
    } catch (e) {
      debugPrint('Warning: settleOrder failed (continuing to print receipt): $e');
    }

    debugPrint('[Settlement] Step 3 — settleSuccess=$settleSuccess');
    // ── Step 3: Update kitchen display & refresh all providers ───────────────
    final kotItems = state.cart.map((c) => KotItem(
      id: c.item.id,
      name: c.item.name,
      quantity: c.quantity,
      notes: c.notes,
    )).toList();

    ref.read(kitchenDisplayProvider.notifier).addTicket(
      KitchenTicket(
        id: orderId,
        kotNumber: 'KOT-${orderNumber.replaceAll("#", "").replaceAll("ORD-", "")}',
        orderNumber: orderNumber,
        orderType: state.orderType,
        tableLabel: state.selectedTableId,
        serverName: state.orderType == OrderType.takeaway
            ? 'Takeaway POS'
            : (state.customerName.isNotEmpty ? state.customerName : 'Walk-in Guest'),
        status: KotStatus.newOrder,
        createdAt: DateTime.now(),
        items: kotItems,
        specialInstruction: state.orderNotes,
      ),
    );

    ref.read(restaurantOrderProvider.notifier).loadOrders();
    ref.read(restaurantTableProvider.notifier).loadTables();
    ref.read(kitchenDisplayProvider.notifier).loadTickets(silent: true);
    ref.read(customerProvider.notifier).loadCustomers();
    ref.read(restaurantReportProvider.notifier).loadReportData();
    onReloadMenu();

    // ── Step 3b: If Dine-In table order was settled and paid, free the table to Available/Vacant ─
    if (state.orderType == OrderType.dineIn && state.selectedTableId != null) {
      try {
        await RestaurantPosService.updateTableStatus(state.selectedTableId!, TableStatus.available);
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      } catch (e) {
        debugPrint('Warning: Freeing table status failed: $e');
      }
    }

    debugPrint('[Settlement] Step 4 — calling clearCart(clearCustomer: true)');
    // ── Step 4: Clear cart and customer IMMEDIATELY after order is confirmed ─
    // This MUST happen before any async PDF/print work so the cart and customer
    // search bar are always reset for the next bill.
    ref.read(restaurantPosProvider.notifier).clearCart(clearCustomer: true);

    debugPrint('[Settlement] Step 5 — context.mounted=${context.mounted}, calling _executePrinting');
    // ── Step 5: Generate PDF and show receipt modal ──────────────────────────
    if (context.mounted) {
      await _executePrinting(
        context: context,
        ref: ref,
        state: state,
        orderId: orderId,
        orderNumber: orderNumber,
        settleSuccess: settleSuccess,
        shopSettings: shopSettings,
        activeOutlet: activeOutlet,
        tables: tables,
        cartSnapshot: kotItems,
      );
    }
  }

  static Future<void> _executePrinting({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState state,
    required String orderId,
    required String orderNumber,
    required bool settleSuccess,
    required Map<String, dynamic>? shopSettings,
    required Shop? activeOutlet,
    required List<DiningTable> tables,
    required List<KotItem> cartSnapshot,
  }) async {
    debugPrint('[Settlement] _executePrinting START — orderType=${state.orderType}');
    // Use the cart snapshot captured before clearCart().
    final posCartSnapshot = state.cart;
    final subtotal = state.subtotal;
    final discount = state.discountAmount;
    final tax = state.gstAmount;
    final grandTotal = state.grandTotal;
    final invoiceNo = orderNumber;
    final custName = state.customerName.isNotEmpty ? state.customerName : 'Walk-in Guest';
    final custPhone = state.customerPhone;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(settleSuccess
            ? (state.orderType == OrderType.takeaway
                ? 'Takeaway Payment Done! Preparing receipt...'
                : 'Order $invoiceNo Settled! Preparing receipt...')
            : 'Order $invoiceNo Created! Preparing receipt...'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );

    // Resolve outlet info.
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

    // ── Generate PDF bytes ───────────────────────────────────────────────────
    Uint8List? printDocBytes;
    try {
      // Find matching table label and floor for Dine-in
      String? tableLabel;
      String? floor = state.selectedFloor;
      if (state.orderType == OrderType.dineIn && state.selectedTableId != null) {
        final matchingTable = tables.where((t) => t.id == state.selectedTableId).firstOrNull;
        if (matchingTable != null) {
          tableLabel = matchingTable.label;
          if (matchingTable.floor.isNotEmpty) floor = matchingTable.floor;
        } else {
          tableLabel = state.selectedTableId;
        }
      }

      // Generate the exact same high-quality thermal bill template for both Takeaway & Dine-in
      final kotNumber = 'KOT-${invoiceNo.replaceAll("#", "").replaceAll("ORD-", "")}';
      printDocBytes = await KotPrinterHelper.generateCombinedTakeawayPdf(
        kotNumber: kotNumber,
        orderNumber: invoiceNo,
        orderType: state.orderType == OrderType.dineIn ? 'Dine-in' : (state.orderType == OrderType.delivery ? 'Delivery' : 'Takeaway'),
        tableLabel: tableLabel,
        floor: floor,
        customerName: custName,
        customerPhone: custPhone,
        orderNotes: state.orderNotes,
        items: posCartSnapshot,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        shopName: shopName,
        address: address,
        phone: phone,
        shopGstNo: shopGstNo,
        fssaiNo: fssaiNo,
        upiId: upiId,
        logoUrl: outlet?.logoUrl ?? shopSettings?['logo_url'],
      );
    } catch (e) {
      debugPrint('Warning: Local thermal receipt generation failed, trying backend PDF: $e');
      try {
        printDocBytes = await RestaurantPosService.fetchBackendBillPdfBytes(orderId);
      } catch (_) {}
    }

    // ── Show receipt modal ───────────────────────────────────────────────────
    if (context.mounted && printDocBytes != null) {
      final modalTitle = state.orderType == OrderType.takeaway
          ? 'Takeaway Receipt & KOT'
          : (state.orderType == OrderType.dineIn ? 'Dine-in Receipt & KOT' : 'Tax Invoice Receipt');

      await PosBillReceiptModal.show(
        context,
        orderNumber: invoiceNo,
        title: modalTitle,
        pdfBytes: printDocBytes,
        onDismiss: () {
          // Double safeguard: ensure cart & active order are cleared when receipt modal closes
          ref.read(restaurantPosProvider.notifier).clearCart(clearCustomer: true);
        },
      );
      // Double safeguard after modal awaits / closes
      ref.read(restaurantPosProvider.notifier).clearCart(clearCustomer: true);
    } else if (context.mounted && printDocBytes == null) {
      // PDF generation failed entirely — still inform the cashier.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $invoiceNo completed! (Receipt PDF unavailable)'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
