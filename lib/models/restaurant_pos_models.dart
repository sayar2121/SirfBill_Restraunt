enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

enum TableStatus {
  available,
  occupied,
  reserved,
}

class DiningTable {
  final String id;
  final String label; // e.g. T1, T2
  final int capacity; // e.g. 4 Seater
  final TableStatus status;
  final String? occupiedDuration; // e.g. "00:45"
  final DateTime? occupiedSince; // Exact timestamp when table became occupied
  final String floor; // e.g. "Floor 1"
  final double currentBillAmount;
  final int activeOrderCount;

  const DiningTable({
    required this.id,
    required this.label,
    required this.capacity,
    required this.status,
    this.occupiedDuration,
    this.occupiedSince,
    required this.floor,
    this.currentBillAmount = 0.0,
    this.activeOrderCount = 0,
  });

  DiningTable copyWith({
    String? id,
    String? label,
    int? capacity,
    TableStatus? status,
    String? occupiedDuration,
    DateTime? occupiedSince,
    String? floor,
    double? currentBillAmount,
    int? activeOrderCount,
  }) {
    return DiningTable(
      id: id ?? this.id,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      occupiedDuration: occupiedDuration ?? this.occupiedDuration,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      floor: floor ?? this.floor,
      currentBillAmount: currentBillAmount ?? this.currentBillAmount,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
    );
  }
}

class MenuCategory {
  final String id;
  final String name;
  final String iconEmoji;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.iconEmoji,
  });

  MenuCategory copyWith({
    String? id,
    String? name,
    String? iconEmoji,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }
}

class PosMenuItem {
  final String id;
  final String name;
  final String? shortCode; // Auto-generated or custom e.g. "PBM", "CB"
  final String categoryId;
  final double price;
  final String? imageUrl;
  final String? badge; // "Popular", "Bestseller"
  final double taxPercent;
  final bool isAvailable;
  final bool isVeg; // true: Veg, false: Non-Veg
  final String? description;

  const PosMenuItem({
    required this.id,
    required this.name,
    this.shortCode,
    required this.categoryId,
    required this.price,
    this.imageUrl,
    this.badge,
    this.taxPercent = 5.0,
    this.isAvailable = true,
    this.isVeg = true,
    this.description,
  });

  PosMenuItem copyWith({
    String? id,
    String? name,
    String? shortCode,
    String? categoryId,
    double? price,
    String? imageUrl,
    String? badge,
    double? taxPercent,
    bool? isAvailable,
    bool? isVeg,
    String? description,
  }) {
    return PosMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      badge: badge ?? this.badge,
      taxPercent: taxPercent ?? this.taxPercent,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg ?? this.isVeg,
      description: description ?? this.description,
    );
  }
}

class PosCartItem {
  final PosMenuItem item;
  final int quantity;
  final String? notes; // e.g. "Medium Spicy, Extra Mint Sauce"
  final List<String> modifiers;

  const PosCartItem({
    required this.item,
    this.quantity = 1,
    this.notes,
    this.modifiers = const [],
  });

  double get totalPrice => item.price * quantity;

  PosCartItem copyWith({
    PosMenuItem? item,
    int? quantity,
    String? notes,
    List<String>? modifiers,
  }) {
    return PosCartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}

enum OrderStatus {
  active,
  completed,
  cancelled,
  hold,
  served,
}

enum PaymentStatus {
  paid,
  pending,
  refunded,
}

class RestaurantOrder {
  final String id;
  final String orderNumber; // e.g. #ORD-1042
  final OrderType orderType;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod; // e.g. "UPI", "Cash", "Card"
  final String? tableId;
  final String? tableLabel;
  final String? floor;
  final String customerName;
  final String customerPhone;
  final List<PosCartItem> items;
  final double subtotal;
  final double discount;
  final double gstAmount;
  final double grandTotal;
  final DateTime createdAt;
  final String? notes;

  const RestaurantOrder({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod = 'UPI',
    this.tableId,
    this.tableLabel,
    this.floor,
    this.customerName = 'Walk-in Guest',
    this.customerPhone = '',
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.gstAmount,
    required this.grandTotal,
    required this.createdAt,
    this.notes,
  });

  RestaurantOrder copyWith({
    String? id,
    String? orderNumber,
    OrderType? orderType,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? tableId,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? customerPhone,
    List<PosCartItem>? items,
    double? subtotal,
    double? discount,
    double? gstAmount,
    double? grandTotal,
    DateTime? createdAt,
    String? notes,
  }) {
    return RestaurantOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tableId: tableId ?? this.tableId,
      tableLabel: tableLabel ?? this.tableLabel,
      floor: floor ?? this.floor,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      gstAmount: gstAmount ?? this.gstAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

enum KotStatus {
  newOrder,
  preparing,
  ready,
  served,
}

class KotItem {
  final String id;
  final String name;
  final int quantity;
  final String? notes; // e.g. "Less Spicy", "No Onion"
  final bool isPrepared;
  final bool isRunningItem; // Highlight items added later to a running table order

  const KotItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.notes,
    this.isPrepared = false,
    this.isRunningItem = false,
  });

  KotItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? notes,
    bool? isPrepared,
    bool? isRunningItem,
  }) {
    return KotItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      isPrepared: isPrepared ?? this.isPrepared,
      isRunningItem: isRunningItem ?? this.isRunningItem,
    );
  }
}

class KitchenTicket {
  final String id;
  final String kotNumber; // e.g. "KOT #104"
  final String orderNumber; // e.g. "#ORD-1042"
  final OrderType orderType;
  final String? tableLabel;
  final String? floor;
  final String? serverName; // Waiter / Cashier
  final KotStatus status;
  final DateTime createdAt;
  final DateTime? prepStartedAt; // Time when order was accepted/prep started
  final List<KotItem> items;
  final String? specialInstruction;

  const KitchenTicket({
    required this.id,
    required this.kotNumber,
    required this.orderNumber,
    required this.orderType,
    this.tableLabel,
    this.floor,
    this.serverName = 'Staff',
    required this.status,
    required this.createdAt,
    this.prepStartedAt,
    required this.items,
    this.specialInstruction,
  });

  KitchenTicket copyWith({
    String? id,
    String? kotNumber,
    String? orderNumber,
    OrderType? orderType,
    String? tableLabel,
    String? floor,
    String? serverName,
    KotStatus? status,
    DateTime? createdAt,
    DateTime? prepStartedAt,
    List<KotItem>? items,
    String? specialInstruction,
  }) {
    return KitchenTicket(
      id: id ?? this.id,
      kotNumber: kotNumber ?? this.kotNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      tableLabel: tableLabel ?? this.tableLabel,
      floor: floor ?? this.floor,
      serverName: serverName ?? this.serverName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      prepStartedAt: prepStartedAt ?? this.prepStartedAt,
      items: items ?? this.items,
      specialInstruction: specialInstruction ?? this.specialInstruction,
    );
  }
}

