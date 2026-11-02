import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';

class RestaurantPosState {
  final OrderType orderType;
  final String selectedFloor;
  final String? selectedTableId;
  final String activeCategoryId;
  final String searchQuery;
  final String customerName;
  final String customerPhone;
  final String orderNotes;
  final double discountPercent;
  final double gstPercent;
  final String? activeOrderId;
  final String? activeOrderNumber;
  final int? activeOrderVersion;
  final List<PosCartItem>? initialCart;
  final List<PosCartItem> cart;

  const RestaurantPosState({
    this.orderType = OrderType.dineIn,
    this.selectedFloor = 'Floor 1',
    this.selectedTableId,
    this.activeCategoryId = 'all',
    this.searchQuery = '',
    this.customerName = '',
    this.customerPhone = '',
    this.orderNotes = '',
    this.discountPercent = 0.0,
    this.gstPercent = 5.0,
    this.activeOrderId,
    this.activeOrderNumber,
    this.activeOrderVersion = 1,
    this.initialCart = const [],
    this.cart = const [],
  });

  List<PosCartItem> get safeInitialCart => initialCart ?? const [];

  double get subtotal =>
      cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount => (subtotal * discountPercent) / 100.0;

  double get gstAmount =>
      ((subtotal - discountAmount) * gstPercent) / 100.0;

  double get grandTotal => (subtotal - discountAmount) + gstAmount;

  RestaurantPosState copyWith({
    OrderType? orderType,
    String? selectedFloor,
    String? selectedTableId,
    String? activeCategoryId,
    String? searchQuery,
    String? customerName,
    String? customerPhone,
    String? orderNotes,
    double? discountPercent,
    double? gstPercent,
    String? Function()? activeOrderId,
    String? Function()? activeOrderNumber,
    int? activeOrderVersion,
    List<PosCartItem>? initialCart,
    List<PosCartItem>? cart,
  }) {
    return RestaurantPosState(
      orderType: orderType ?? this.orderType,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedTableId: selectedTableId ?? this.selectedTableId,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderNotes: orderNotes ?? this.orderNotes,
      discountPercent: discountPercent ?? this.discountPercent,
      gstPercent: gstPercent ?? this.gstPercent,
      activeOrderId: activeOrderId != null ? activeOrderId() : this.activeOrderId,
      activeOrderNumber: activeOrderNumber != null ? activeOrderNumber() : this.activeOrderNumber,
      activeOrderVersion: activeOrderVersion ?? this.activeOrderVersion ?? 1,
      initialCart: initialCart ?? this.initialCart ?? const [],
      cart: cart ?? this.cart,
    );
  }
}

class RestaurantPosNotifier extends Notifier<RestaurantPosState> {
  @override
  RestaurantPosState build() {
    return const RestaurantPosState(
      cart: [],
    );
  }

  void setOrderType(OrderType type) => state = state.copyWith(orderType: type);
  void selectFloor(String floor) => state = state.copyWith(selectedFloor: floor);
  void selectTable(String tableId) => state = state.copyWith(selectedTableId: tableId);
  void setCategory(String catId) => state = state.copyWith(activeCategoryId: catId);
  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);
  void setCustomer(String name, String phone) =>
      state = state.copyWith(customerName: name, customerPhone: phone);
  void setOrderNotes(String notes) => state = state.copyWith(orderNotes: notes);
  void setDiscount(double discount) => state = state.copyWith(discountPercent: discount);

  void addItem(PosMenuItem item, {String? notes}) {
    final index = state.cart.indexWhere((c) => c.item.id == item.id);
    if (index >= 0) {
      final updated = List<PosCartItem>.from(state.cart);
      updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = state.copyWith(cart: updated);
    } else {
      state = state.copyWith(
        cart: [
          ...state.cart,
          PosCartItem(item: item, quantity: 1, notes: notes),
        ],
      );
    }
  }

  void incrementQty(int index) {
    if (index < 0 || index >= state.cart.length) return;
    final updated = List<PosCartItem>.from(state.cart);
    updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
    state = state.copyWith(cart: updated);
  }

  void decrementQty(int index) {
    if (index < 0 || index >= state.cart.length) return;
    final updated = List<PosCartItem>.from(state.cart);
    if (updated[index].quantity > 1) {
      updated[index] = updated[index].copyWith(quantity: updated[index].quantity - 1);
      state = state.copyWith(cart: updated);
    } else {
      removeItem(index);
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.cart.length) return;
    final updated = List<PosCartItem>.from(state.cart)..removeAt(index);
    state = state.copyWith(cart: updated);
  }

  void setCart(
    List<PosCartItem> items, {
    String? customerName,
    String? customerPhone,
    String? notes,
    String? orderId,
    String? orderNumber,
    int? orderVersion,
  }) {
    state = state.copyWith(
      cart: items,
      initialCart: items,
      customerName: customerName ?? state.customerName,
      customerPhone: customerPhone ?? state.customerPhone,
      orderNotes: notes ?? state.orderNotes,
      activeOrderId: () => orderId,
      activeOrderNumber: () => orderNumber,
      activeOrderVersion: orderVersion ?? 1,
    );
  }

  void clearCart({bool clearCustomer = false}) {
    state = state.copyWith(
      cart: const [],
      initialCart: const [],
      activeOrderId: () => null,
      activeOrderNumber: () => null,
      activeOrderVersion: 1,
      customerName: clearCustomer ? '' : state.customerName,
      customerPhone: clearCustomer ? '' : state.customerPhone,
      orderNotes: clearCustomer ? '' : state.orderNotes,
    );
  }
}

final restaurantPosProvider =
    NotifierProvider<RestaurantPosNotifier, RestaurantPosState>(() {
  return RestaurantPosNotifier();
});
