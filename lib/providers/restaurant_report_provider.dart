import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_report_models.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';
import '../services/billing_service.dart';
import '../widgets/common_filter_pills.dart';

class RestaurantReportState {
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final int activeTab; // 0: Sales Overview, 1: Item-wise Sales, 2: Audit Logs
  final SalesReportSummary summary;
  final List<TopSellingDish> topDishes;
  final List<AuditLogEntry> auditLogs;
  final List<RestaurantOrder> orders;
  final String auditSearchQuery;
  final bool isLoading;

  const RestaurantReportState({
    this.datePreset = DateRangePreset.all,
    this.customRange,
    this.activeTab = 0,
    required this.summary,
    required this.topDishes,
    required this.auditLogs,
    this.orders = const [],
    this.auditSearchQuery = '',
    this.isLoading = false,
  });

  String get dateRangeLabel {
    switch (datePreset) {
      case DateRangePreset.all:
        return 'All Time';
      case DateRangePreset.today:
        return 'Today (${DateFormat('dd MMM yyyy').format(DateTime.now())})';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month (${DateFormat('MMMM yyyy').format(DateTime.now())})';
      case DateRangePreset.thisYear:
        return 'This Year (${DateTime.now().year})';
      case DateRangePreset.custom:
        if (customRange != null) {
          final s = customRange!.start;
          final e = customRange!.end;
          return '${DateFormat('dd/MM/yyyy').format(s)} - ${DateFormat('dd/MM/yyyy').format(e)}';
        }
        return 'Custom Range';
    }
  }

  List<AuditLogEntry> get filteredAuditLogs {
    if (auditSearchQuery.isEmpty) return auditLogs;
    return auditLogs.where((log) {
      return log.action.toLowerCase().contains(auditSearchQuery.toLowerCase()) ||
          log.actorName.toLowerCase().contains(auditSearchQuery.toLowerCase()) ||
          log.details.toLowerCase().contains(auditSearchQuery.toLowerCase());
    }).toList();
  }

  RestaurantReportState copyWith({
    DateRangePreset? datePreset,
    DateTimeRange? customRange,
    int? activeTab,
    SalesReportSummary? summary,
    List<TopSellingDish>? topDishes,
    List<AuditLogEntry>? auditLogs,
    List<RestaurantOrder>? orders,
    String? auditSearchQuery,
    bool? isLoading,
  }) {
    return RestaurantReportState(
      datePreset: datePreset ?? this.datePreset,
      customRange: customRange ?? this.customRange,
      activeTab: activeTab ?? this.activeTab,
      summary: summary ?? this.summary,
      topDishes: topDishes ?? this.topDishes,
      auditLogs: auditLogs ?? this.auditLogs,
      orders: orders ?? this.orders,
      auditSearchQuery: auditSearchQuery ?? this.auditSearchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RestaurantReportNotifier extends Notifier<RestaurantReportState> {
  List<RestaurantOrder> _allOrders = [];

  @override
  RestaurantReportState build() {
    // Schedule initial async load from backend database
    Future.microtask(() => loadReportData());

    return const RestaurantReportState(
      summary: SalesReportSummary(
        grossSales: 0,
        netSales: 0,
        totalDiscount: 0,
        totalGst: 0,
        totalOrders: 0,
        averageOrderValue: 0,
        upiSales: 0,
        cashSales: 0,
        cardSales: 0,
        dineInSales: 0,
        takeawaySales: 0,
        deliverySales: 0,
      ),
      topDishes: [],
      auditLogs: [],
      isLoading: true,
    );
  }

  String _resolveCategory(String name, String rawCat) {
    if (rawCat.isNotEmpty &&
        rawCat != 'all' &&
        rawCat != 'Dishes' &&
        !rawCat.contains('-')) {
      return rawCat;
    }
    final n = name.toLowerCase();
    if (n.contains('tikka') ||
        n.contains('kebab') ||
        n.contains('starter') ||
        n.contains('paneer tikka') ||
        n.contains('chicken tikka') ||
        n.contains('tandoor')) {
      return 'Tandoor & Starters';
    }
    if (n.contains('biryani') ||
        n.contains('biriyani') ||
        n.contains('rice') ||
        n.contains('pulao')) {
      return 'Biryani & Rice';
    }
    if (n.contains('pizza') ||
        n.contains('burger') ||
        n.contains('sandwich') ||
        n.contains('pasta') ||
        n.contains('roll') ||
        n.contains('fries')) {
      return 'Fast Food & Snacks';
    }
    if (n.contains('dal') ||
        n.contains('curry') ||
        n.contains('butter') ||
        n.contains('korma') ||
        n.contains('paneer') ||
        n.contains('masala') ||
        n.contains('mutton') ||
        n.contains('gravy') ||
        n.contains('tadka')) {
      return 'Main Course';
    }
    if (n.contains('naan') ||
        n.contains('roti') ||
        n.contains('paratha') ||
        n.contains('kulcha') ||
        n.contains('bread')) {
      return 'Breads';
    }
    if (n.contains('tea') ||
        n.contains('coffee') ||
        n.contains('shake') ||
        n.contains('lassi') ||
        n.contains('drink') ||
        n.contains('water') ||
        n.contains('beverage') ||
        n.contains('juice') ||
        n.contains('soda')) {
      return 'Beverages';
    }
    if (n.contains('ice cream') ||
        n.contains('sweet') ||
        n.contains('gulab') ||
        n.contains('halwa') ||
        n.contains('dessert') ||
        n.contains('kheer')) {
      return 'Desserts';
    }
    return 'Specialties';
  }

  Future<void> loadReportData() async {
    state = state.copyWith(isLoading: true);

    try {
      final outletId = await InventoryService.getShopId();
      _allOrders = await RestaurantPosService.fetchOrders(outletId: outletId);

      // Cross-reference with POS transactions history where payment_mode and items_detail are recorded
      try {
        final historyRes = await BillingService.getPosHistory();
        final historyList = historyRes['history'] as List? ?? [];
        if (historyList.isNotEmpty) {
          // Map of invoiceNo -> payment_mode & items
          final Map<String, String> billPaymentMap = {};
          final Map<String, List<PosCartItem>> billItemsMap = {};

          for (final h in historyList) {
            final billNo = h['bill_no']?.toString().toUpperCase() ?? '';
            final pMode = (h['payment_mode'] ?? h['payment_method'] ?? 'CASH').toString().toUpperCase();
            
            // Extract items if any
            final rawItems = h['items_detail'] ?? h['items'] ?? h['lines'] ?? [];
            final List<PosCartItem> parsedItems = [];
            if (rawItems is List) {
              for (final it in rawItems) {
                final rawQty = it['quantity'] ?? it['qty'] ?? 1;
                final qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
                final rawPrice = it['unit_price'] ?? it['price'] ?? it['rate'] ?? it['mrp'] ?? 0.0;
                final price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
                final itemName = it['name'] ?? it['item_name'] ?? it['menu_item_name'] ?? 'Item';
                final itemId = it['menu_item_id'] ?? it['item_id'] ?? it['inventory_item_id'] ?? it['id'] ?? '';
                final catId = it['category_id']?.toString() ?? it['category']?.toString() ?? 'all';

                parsedItems.add(
                  PosCartItem(
                    item: PosMenuItem(
                      id: itemId.toString(),
                      name: itemName.toString(),
                      categoryId: catId,
                      price: price,
                    ),
                    quantity: qty,
                  ),
                );
              }
            }

            if (billNo.isNotEmpty) {
              billPaymentMap[billNo] = pMode;
              final stripped = billNo.replaceAll('ORD-', '').replaceAll('BILL-', '').replaceAll('#', '');
              billPaymentMap[stripped] = pMode;

              if (parsedItems.isNotEmpty) {
                billItemsMap[billNo] = parsedItems;
                billItemsMap[stripped] = parsedItems;
              }
            }
          }

          // Map of invoiceNo -> POS history record
          final Map<String, Map<String, dynamic>> posHistoryMap = {};

          for (final h in historyList) {
            final billNo = h['bill_no']?.toString().toUpperCase() ?? '';
            final pMode = (h['payment_mode'] ?? h['payment_method'] ?? 'CASH').toString().toUpperCase();
            
            // Extract items if any
            final rawItems = h['items_detail'] ?? h['items'] ?? h['lines'] ?? [];
            final List<PosCartItem> parsedItems = [];
            if (rawItems is List) {
              for (final it in rawItems) {
                final rawQty = it['quantity'] ?? it['qty'] ?? 1;
                final qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
                final rawPrice = it['unit_price'] ?? it['price'] ?? it['rate'] ?? it['mrp'] ?? 0.0;
                final price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
                final itemName = it['name'] ?? it['item_name'] ?? it['menu_item_name'] ?? 'Item';
                final itemId = it['menu_item_id'] ?? it['item_id'] ?? it['inventory_item_id'] ?? it['id'] ?? '';
                final catId = it['category_id']?.toString() ?? it['category']?.toString() ?? 'all';

                parsedItems.add(
                  PosCartItem(
                    item: PosMenuItem(
                      id: itemId.toString(),
                      name: itemName.toString(),
                      categoryId: catId,
                      price: price,
                    ),
                    quantity: qty,
                  ),
                );
              }
            }

            if (billNo.isNotEmpty) {
              billPaymentMap[billNo] = pMode;
              final stripped = billNo.replaceAll('ORD-', '').replaceAll('BILL-', '').replaceAll('#', '');
              billPaymentMap[stripped] = pMode;

              if (parsedItems.isNotEmpty) {
                billItemsMap[billNo] = parsedItems;
                billItemsMap[stripped] = parsedItems;
              }

              final hMap = Map<String, dynamic>.from(h);
              hMap['parsed_items'] = parsedItems;
              posHistoryMap[billNo] = hMap;
              posHistoryMap[stripped] = hMap;
            }
          }

          final Set<String> matchedBillNumbers = {};

          // Enrich orders with real payment_mode and items if empty
          _allOrders = _allOrders.map((o) {
            final orderNum = o.orderNumber.toUpperCase();
            final strippedNum = orderNum.replaceAll('ORD-', '').replaceAll('BILL-', '').replaceAll('#', '');

            String resolvedPayment = o.paymentMethod;
            if (billPaymentMap.containsKey(orderNum)) {
              resolvedPayment = billPaymentMap[orderNum]!;
              matchedBillNumbers.add(orderNum);
            } else if (billPaymentMap.containsKey(strippedNum)) {
              resolvedPayment = billPaymentMap[strippedNum]!;
              matchedBillNumbers.add(strippedNum);
            }

            List<PosCartItem> resolvedItems = o.items;
            if (resolvedItems.isEmpty) {
              if (billItemsMap.containsKey(orderNum)) {
                resolvedItems = billItemsMap[orderNum]!;
              } else if (billItemsMap.containsKey(strippedNum)) {
                resolvedItems = billItemsMap[strippedNum]!;
              }
            }

            return o.copyWith(
              paymentMethod: resolvedPayment,
              items: resolvedItems,
            );
          }).toList();

          // Also include past POS sales from history that are not in restaurant orders
          for (final entry in posHistoryMap.entries) {
            final billKey = entry.key;
            if (matchedBillNumbers.contains(billKey)) continue;

            final h = entry.value;
            final billNo = h['bill_no']?.toString() ?? billKey;
            matchedBillNumbers.add(billNo.toUpperCase());
            matchedBillNumbers.add(billNo.toUpperCase().replaceAll('ORD-', '').replaceAll('BILL-', '').replaceAll('#', ''));

            String dateStr = (h['date'] ?? h['created_at'] ?? '').toString();
            dateStr = dateStr.replaceAll(' ', 'T');
            if (dateStr.isNotEmpty && !dateStr.endsWith('Z') && !dateStr.contains('+')) {
              dateStr += 'Z';
            }
            final createdAt = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();

            final items = (h['parsed_items'] as List<PosCartItem>?) ?? [];
            final grandTotal = (h['amount'] as num?)?.toDouble() ??
                (h['total'] as num?)?.toDouble() ??
                (h['grand_total'] as num?)?.toDouble() ??
                0.0;
            final subtotal = (h['subtotal'] as num?)?.toDouble() ?? grandTotal;
            final discount = (h['discount'] as num?)?.toDouble() ?? 0.0;
            final gst = (h['gst'] as num?)?.toDouble() ?? (h['tax'] as num?)?.toDouble() ?? 0.0;
            final custName = (h['customer_name'] ?? 'Walk-in Guest').toString();
            final custPhone = (h['customer_phone'] ?? '').toString();
            final pMode = (h['payment_mode'] ?? h['payment_method'] ?? 'CASH').toString().toUpperCase();

            _allOrders.add(
              RestaurantOrder(
                id: h['id']?.toString() ?? billNo,
                orderNumber: billNo.startsWith('#') || billNo.startsWith('ORD-') || billNo.startsWith('BILL-')
                    ? billNo
                    : '#$billNo',
                orderType: OrderType.takeaway,
                status: OrderStatus.completed,
                paymentStatus: PaymentStatus.paid,
                customerName: custName,
                customerPhone: custPhone,
                items: items,
                subtotal: subtotal,
                discount: discount,
                gstAmount: gst,
                grandTotal: grandTotal,
                createdAt: createdAt,
                paymentMethod: pMode,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Info: Cross-referencing POS history: $e');
      }

      _recalculateMetrics();
    } catch (e) {
      debugPrint('Error loading backend report data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _recalculateMetrics() {
    final now = DateTime.now();
    DateTime? rangeStart;
    DateTime? rangeEnd;

    switch (state.datePreset) {
      case DateRangePreset.all:
        rangeStart = null;
        rangeEnd = null;
        break;
      case DateRangePreset.today:
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case DateRangePreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        rangeStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case DateRangePreset.thisMonth:
        rangeStart = DateTime(now.year, now.month, 1);
        final nextMonth = (now.month == 12) ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
        rangeEnd = DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 23, 59, 59, 999);
        break;
      case DateRangePreset.thisYear:
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        break;
      case DateRangePreset.custom:
        rangeStart = state.customRange != null
            ? DateTime(state.customRange!.start.year, state.customRange!.start.month, state.customRange!.start.day)
            : null;
        rangeEnd = state.customRange != null
            ? DateTime(state.customRange!.end.year, state.customRange!.end.month, state.customRange!.end.day, 23, 59, 59, 999)
            : null;
        break;
    }

    // Filter orders by date range comparing in local calendar time
    final filteredOrders = _allOrders.where((order) {
      final orderDate = order.createdAt.toLocal();
      if (rangeStart != null && orderDate.isBefore(rangeStart)) {
        return false;
      }
      if (rangeEnd != null && orderDate.isAfter(rangeEnd)) {
        return false;
      }
      return true;
    }).toList();

    double grossSales = 0.0;
    double netSales = 0.0;
    double totalDiscount = 0.0;
    double totalGst = 0.0;
    int totalOrdersCount = 0;

    double upiSales = 0.0;
    double cashSales = 0.0;
    double cardSales = 0.0;

    double dineInSales = 0.0;
    double takeawaySales = 0.0;
    double deliverySales = 0.0;

    final Map<String, (int qty, double rev, String cat)> dishPerformance = {};
    final List<AuditLogEntry> generatedAuditLogs = [];

    int totalItemsSold = 0;
    final Set<String> customersSet = {};

    for (final o in filteredOrders) {
      // We consider settled / active orders for analytics
      if (o.status == OrderStatus.cancelled) {
        generatedAuditLogs.add(
          AuditLogEntry(
            id: o.id,
            action: 'Order Cancelled',
            actorName: o.customerName.isNotEmpty ? o.customerName : 'Staff',
            details: 'Order #${o.orderNumber} was cancelled.',
            timestamp: o.createdAt,
            severity: 'critical',
          ),
        );
        continue;
      }

      totalOrdersCount += 1;
      grossSales += o.grandTotal;
      netSales += o.subtotal;
      totalDiscount += o.discount;
      totalGst += o.gstAmount;

      if (o.customerPhone.isNotEmpty) {
        customersSet.add(o.customerPhone);
      } else if (o.customerName.isNotEmpty && o.customerName != 'Walk-in Guest') {
        customersSet.add(o.customerName);
      }

      // Payment method breakdown (UPI, CARD, CASH)
      final pMethod = o.paymentMethod.toUpperCase().trim();
      if (pMethod.contains('UPI') || pMethod.contains('QR') || pMethod.contains('GPAY') || pMethod.contains('PAYTM') || pMethod.contains('PHONEPE') || pMethod.contains('ONLINE') || pMethod.contains('NET_BANKING')) {
        upiSales += o.grandTotal;
      } else if (pMethod.contains('CARD') || pMethod.contains('DEBIT') || pMethod.contains('CREDIT') || pMethod.contains('POS') || pMethod.contains('EDC')) {
        cardSales += o.grandTotal;
      } else if (pMethod.contains('CASH') || pMethod.contains('MONEY') || pMethod == 'OFFLINE') {
        cashSales += o.grandTotal;
      } else {
        // Fallback default
        cashSales += o.grandTotal;
      }

      // Order type breakdown
      switch (o.orderType) {
        case OrderType.dineIn:
          dineInSales += o.grandTotal;
          break;
        case OrderType.takeaway:
          takeawaySales += o.grandTotal;
          break;
        case OrderType.delivery:
          deliverySales += o.grandTotal;
          break;
      }

      // Audit logs for settlement or hold
      if (o.status == OrderStatus.completed) {
        generatedAuditLogs.add(
          AuditLogEntry(
            id: o.id,
            action: 'Bill Settled',
            actorName: o.customerName.isNotEmpty && o.customerName != 'Walk-in Guest'
                ? o.customerName
                : 'Cashier POS',
            details: 'Order #${o.orderNumber} settled for ₹${o.grandTotal.toStringAsFixed(2)} via $pMethod (${o.orderType.name.toUpperCase()}).',
            timestamp: o.createdAt,
            severity: 'info',
          ),
        );
      } else if (o.status == OrderStatus.hold) {
        generatedAuditLogs.add(
          AuditLogEntry(
            id: o.id,
            action: 'Order Placed on Hold',
            actorName: o.customerName.isNotEmpty ? o.customerName : 'Staff',
            details: 'Order #${o.orderNumber} on table ${o.tableLabel ?? 'N/A'} held in pending billing.',
            timestamp: o.createdAt,
            severity: 'warning',
          ),
        );
      }

      // Track items sold
      for (final it in o.items) {
        final dName = it.item.name;
        final int dQty = it.quantity.toInt();
        final double dRev = it.totalPrice.toDouble();
        final resolvedCat = _resolveCategory(dName, it.item.categoryId);

        totalItemsSold += dQty;

        if (dishPerformance.containsKey(dName)) {
          final existing = dishPerformance[dName]!;
          dishPerformance[dName] = (existing.$1 + dQty, existing.$2 + dRev, existing.$3);
        } else {
          dishPerformance[dName] = (dQty, dRev, resolvedCat);
        }
      }
    }

    final averageOrderValue = totalOrdersCount > 0 ? (grossSales / totalOrdersCount) : 0.0;

    // Convert and sort top selling dishes by revenue
    final topDishesList = dishPerformance.entries.map((e) {
      return TopSellingDish(
        name: e.key,
        category: e.value.$3,
        quantitySold: e.value.$1,
        revenue: e.value.$2,
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Real aggregated dishes from backend database (never mock / demo items)
    final displayTopDishes = topDishesList;

    // Sort audit logs chronologically newest first
    generatedAuditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = state.copyWith(
      summary: SalesReportSummary(
        grossSales: grossSales,
        netSales: netSales,
        totalDiscount: totalDiscount,
        totalGst: totalGst,
        totalOrders: totalOrdersCount,
        averageOrderValue: averageOrderValue,
        totalItemsSold: totalItemsSold,
        uniqueCustomers: customersSet.length,
        upiSales: upiSales,
        cashSales: cashSales,
        cardSales: cardSales,
        dineInSales: dineInSales,
        takeawaySales: takeawaySales,
        deliverySales: deliverySales,
      ),
      topDishes: displayTopDishes,
      auditLogs: generatedAuditLogs,
      orders: filteredOrders,
      isLoading: false,
    );
  }

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(datePreset: preset);
    _recalculateMetrics();
  }

  void setCustomRange(DateTimeRange? range) {
    state = state.copyWith(
      datePreset: DateRangePreset.custom,
      customRange: range,
    );
    _recalculateMetrics();
  }

  void setActiveTab(int tabIndex) {
    state = state.copyWith(activeTab: tabIndex);
  }

  void setAuditSearchQuery(String query) {
    state = state.copyWith(auditSearchQuery: query);
  }
}

final restaurantReportProvider =
    NotifierProvider<RestaurantReportNotifier, RestaurantReportState>(() {
  return RestaurantReportNotifier();
});
