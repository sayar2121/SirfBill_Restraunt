import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';
import '../services/inventory_service.dart';
import '../services/restaurant_pos_service.dart';
import '../widgets/common_filter_pills.dart';

class RestaurantOrderState {
  final List<RestaurantOrder> orders;
  final OrderStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset? _datePreset;
  final DateTimeRange? customRange;
  final String searchQuery;
  final bool isLoading;

  DateRangePreset get datePreset => _datePreset ?? DateRangePreset.all;

  const RestaurantOrderState({
    required this.orders,
    this.statusFilter,
    this.typeFilter,
    DateRangePreset? datePreset,
    this.customRange,
    this.searchQuery = '',
    this.isLoading = false,
  }) : _datePreset = datePreset ?? DateRangePreset.all;

  bool _matchesDateFilter(DateTime orderDate) {
    final now = DateTime.now();

    switch (datePreset) {
      case DateRangePreset.all:
        return true;
      case DateRangePreset.today:
        return orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day;
      case DateRangePreset.thisWeek:
        // Start of week (Monday)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(monday.year, monday.month, monday.day);
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return orderDate.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
            orderDate.isBefore(endOfWeek);
      case DateRangePreset.thisMonth:
        return orderDate.year == now.year && orderDate.month == now.month;
      case DateRangePreset.thisYear:
        return orderDate.year == now.year;
      case DateRangePreset.custom:
        if (customRange == null) return true;
        final start = DateTime(customRange!.start.year, customRange!.start.month, customRange!.start.day);
        final end = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day, 23, 59, 59, 999);
        return orderDate.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            orderDate.isBefore(end.add(const Duration(milliseconds: 1)));
    }
  }

  List<RestaurantOrder> get filteredOrders {
    return orders.where((ord) {
      final matchesStatus = statusFilter == null || ord.status == statusFilter;
      final matchesType = typeFilter == null || ord.orderType == typeFilter;
      final matchesDate = _matchesDateFilter(ord.createdAt);
      final matchesSearch = searchQuery.isEmpty ||
          ord.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ord.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (ord.tableLabel != null && ord.tableLabel!.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesStatus && matchesType && matchesDate && matchesSearch;
    }).toList();
  }

  int get totalCount => filteredOrders.length;
  int get activeCount => filteredOrders.where((o) => o.status == OrderStatus.active).length;
  int get completedCount => filteredOrders.where((o) => o.status == OrderStatus.completed).length;
  int get holdCount => filteredOrders.where((o) => o.status == OrderStatus.hold).length;
  int get cancelledCount => filteredOrders.where((o) => o.status == OrderStatus.cancelled).length;

  double get todayRevenue => filteredOrders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0.0, (sum, o) => sum + o.grandTotal);

  RestaurantOrderState copyWith({
    List<RestaurantOrder>? orders,
    OrderStatus? Function()? statusFilter,
    OrderType? Function()? typeFilter,
    DateRangePreset? datePreset,
    DateTimeRange? Function()? customRange,
    String? searchQuery,
    bool? isLoading,
  }) {
    return RestaurantOrderState(
      orders: orders ?? this.orders,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      datePreset: datePreset ?? (_datePreset ?? DateRangePreset.all),
      customRange: customRange != null ? customRange() : this.customRange,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RestaurantOrderNotifier extends Notifier<RestaurantOrderState> {
  @override
  RestaurantOrderState build() {
    const initialState = RestaurantOrderState(
      orders: [],
      isLoading: true,
    );

    Future.microtask(() => loadOrders());

    return initialState;
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final outletId = await InventoryService.getShopId();
      debugPrint('[RestaurantOrderNotifier] Loading orders for outletId: $outletId');
      final backendOrders = await RestaurantPosService.fetchOrders(outletId: outletId);
      final backendTables = await RestaurantPosService.fetchTables(outletId: outletId);
      final tableMap = {for (final t in backendTables) t.id: t};

      final resolvedOrders = backendOrders.map((o) {
        if (o.tableId != null && tableMap.containsKey(o.tableId)) {
          final tbl = tableMap[o.tableId]!;
          return o.copyWith(
            tableLabel: tbl.label,
            floor: tbl.floor.isNotEmpty ? tbl.floor : o.floor,
          );
        }
        return o;
      }).toList();

      debugPrint('[RestaurantOrderNotifier] Fetched ${resolvedOrders.length} orders from backend');

      state = state.copyWith(
        orders: resolvedOrders,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading live orders in RestaurantOrderNotifier: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void addOrder(RestaurantOrder order) {
    state = state.copyWith(
      orders: [order, ...state.orders],
    );
  }

  void setStatusFilter(OrderStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void setTypeFilter(OrderType? type) {
    state = state.copyWith(typeFilter: () => type);
  }

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(datePreset: preset);
  }

  void setCustomRange(DateTimeRange? range) {
    state = state.copyWith(customRange: () => range);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    // 1. Optimistic update
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: status);
      }
      return o;
    }).toList();
    state = state.copyWith(orders: updated);

    // 2. Call backend transition if it's a real order
    try {
      String targetBackendStatus = 'OPEN';
      switch (status) {
        case OrderStatus.active:
          targetBackendStatus = 'SENT_TO_KITCHEN';
          break;
        case OrderStatus.completed:
          targetBackendStatus = 'SETTLED';
          break;
        case OrderStatus.hold:
          targetBackendStatus = 'HOLD';
          break;
        case OrderStatus.cancelled:
          targetBackendStatus = 'CANCELLED';
          break;
      }
      await RestaurantPosService.transitionOrderStatus(
        orderId: orderId,
        targetStatus: targetBackendStatus,
      );
    } catch (e) {
      debugPrint('Error transitioning order status on backend: $e');
    }
  }

  void updatePaymentStatus(String orderId, PaymentStatus status) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(paymentStatus: status);
      }
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }
}

final restaurantOrderProvider =
    NotifierProvider<RestaurantOrderNotifier, RestaurantOrderState>(() {
  return RestaurantOrderNotifier();
});
