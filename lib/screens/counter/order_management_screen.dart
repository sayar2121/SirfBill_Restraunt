import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant_pos_models.dart';
import '../../providers/restaurant_order_provider.dart';
import '../../services/restaurant_pos_service.dart';
import '../../services/shop_settings_service.dart';
import '../../services/auth_service.dart';
import '../../utils/pdf_thermal_generator.dart';
import 'widgets/billing/kot_print_dialog.dart';
import 'widgets/orders/order_card.dart';
import 'widgets/orders/order_filter_header.dart';
import 'widgets/orders/order_detail_modal.dart';
import 'widgets/pos/pos_bill_receipt_modal.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(restaurantOrderProvider);
    final orderNotifier = ref.read(restaurantOrderProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final orders = orderState.filteredOrders;

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Order Filters Header (Status, Type, Date Range, Search, New POS Order CTA)
          OrderFilterHeader(
            totalCount: orderState.totalCount,
            activeCount: orderState.activeCount,
            completedCount: orderState.completedCount,
            holdCount: orderState.holdCount,
            statusFilter: orderState.statusFilter,
            typeFilter: orderState.typeFilter,
            datePreset: orderState.datePreset,
            customRange: orderState.customRange,
            isLoading: orderState.isLoading,
            onRefresh: () => orderNotifier.loadOrders(),
            onSelectStatus: orderNotifier.setStatusFilter,
            onSelectType: orderNotifier.setTypeFilter,
            onSelectDatePreset: orderNotifier.setDatePreset,
            onSelectCustomRange: orderNotifier.setCustomRange,
            onSearch: orderNotifier.setSearchQuery,
            onNewOrder: () => context.go('/counter/billing'),
          ),

          // 2. Responsive Order Matrix
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => orderNotifier.loadOrders(),
              color: const Color(0xFF10B981),
              child: orderState.isLoading && orders.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text(
                                'No orders found',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/counter/billing'),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Create New Order'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            int crossAxisCount;
                            double childAspectRatio;

                            if (width < 600) {
                              crossAxisCount = 1;
                              childAspectRatio = 1.85;
                            } else if (width < 960) {
                              crossAxisCount = 2;
                              childAspectRatio = 1.35;
                            } else if (width < 1380) {
                              crossAxisCount = 3;
                              childAspectRatio = 1.25;
                            } else if (width < 1720) {
                              crossAxisCount = 4;
                              childAspectRatio = 1.30;
                            } else {
                              crossAxisCount = 5;
                              childAspectRatio = 1.35;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: orders.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return OrderCard(
                                  order: order,
                                  onTap: () => _showOrderDetailDialog(
                                      context, order, orderNotifier),
                                  onComplete: () =>
                                      orderNotifier.updateOrderStatus(
                                          order.id, OrderStatus.completed),
                                  onPrintKot: () => _showOrderKotDialog(context, order),
                                  onPrintBill: () =>
                                      _printOrderBill(context, order),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderKotDialog(BuildContext context, RestaurantOrder order) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order has no items for KOT.')),
      );
      return;
    }

    final kotNumber = 'KOT-${order.orderNumber.replaceAll("#", "")}';
    KotPrintDialog.show(
      context,
      kotNumber: kotNumber,
      orderNumber: order.orderNumber,
      orderType: order.orderType.name,
      tableLabel: order.tableLabel,
      floor: order.floor,
      customerName: order.customerName,
      orderNotes: order.notes,
      items: order.items,
      timestamp: order.createdAt,
    );
  }

  void _showOrderDetailDialog(
    BuildContext context,
    RestaurantOrder order,
    RestaurantOrderNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OrderDetailModal(
        order: order,
        onUpdateStatus: (status) =>
            notifier.updateOrderStatus(order.id, status),
        onPrintKot: () {
          Navigator.pop(ctx);
          _showOrderKotDialog(context, order);
        },
        onPrintBill: () {
          Navigator.pop(ctx);
          _printOrderBill(context, order);
        },
      ),
    );
  }

  Future<void> _printOrderBill(BuildContext context, RestaurantOrder order) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Print Dialog for ${order.orderNumber}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // 1. Try to fetch official backend thermal bill PDF bytes
    Uint8List? thermalPdfBytes = await RestaurantPosService.fetchBackendBillPdfBytes(order.id);

    // 2. Fall back to frontend generator if backend PDF is not reachable
    if (thermalPdfBytes == null) {
      Map<String, dynamic>? shopSettings;
      try {
        shopSettings = await ShopSettingsService.getSettings();
      } catch (_) {}

      final authName = await AuthService.getUserName();
      final shopName = (shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
          ? shopSettings!['shop_name'].toString()
          : ((authName != null && authName.trim().isNotEmpty) ? authName : 'SirfBill Restaurant');

      final address = shopSettings?['address']?.toString() ??
          shopSettings?['shop_address']?.toString() ??
          'Restaurant Counter';
      final phone = shopSettings?['phone']?.toString() ??
          shopSettings?['mobile']?.toString() ??
          '';
      final shopGstNo = shopSettings?['gst_number']?.toString() ??
          shopSettings?['shop_gst_no']?.toString() ??
          shopSettings?['gstin']?.toString() ??
          '';
      final upiId = shopSettings?['upi_id']?.toString() ?? '';
      final cinNumber = shopSettings?['cin_number']?.toString() ??
          shopSettings?['drug_licence']?.toString() ??
          '';

      // Consolidate identical items by item id
      final Map<String, Map<String, dynamic>> consolidatedItems = {};
      for (final ci in order.items) {
        final key = ci.item.id;
        if (consolidatedItems.containsKey(key)) {
          consolidatedItems[key]!['quantity'] =
              (consolidatedItems[key]!['quantity'] as int) + ci.quantity;
          consolidatedItems[key]!['total'] =
              (consolidatedItems[key]!['total'] as double) + ci.totalPrice;
        } else {
          consolidatedItems[key] = {
            'name': ci.item.name,
            'quantity': ci.quantity,
            'price': ci.item.price,
            'total': ci.totalPrice,
            'gst': ci.item.taxPercent,
            'discount': 0.0,
          };
        }
      }

      String tableInfo = order.orderType.name.toUpperCase();
      if (order.tableLabel != null && order.tableLabel!.isNotEmpty) {
        tableInfo = 'Table ${order.tableLabel}';
      }
      final displayCustomer = '${order.customerName} • $tableInfo';

      thermalPdfBytes = await PdfThermalGenerator.generateThermalBill(
        items: consolidatedItems.values.toList(),
        subtotal: order.subtotal,
        discount: order.discount,
        tax: order.gstAmount,
        grandTotal: order.grandTotal,
        roundedTotal: order.grandTotal.roundToDouble(),
        invoiceNumber: order.orderNumber,
        customerName: displayCustomer,
        customerPhone: order.customerPhone,
        shopName: shopName,
        address: address,
        phone: phone,
        shopGstNo: shopGstNo,
        upiId: upiId,
        cinNumber: cinNumber,
      );
    }

    // 3. Open On-Screen Bill Receipt Modal (with direct Print & Close)
    if (context.mounted) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: order.orderNumber,
        title: 'Tax Invoice Receipt',
        pdfBytes: thermalPdfBytes,
      );
    }
  }
}
