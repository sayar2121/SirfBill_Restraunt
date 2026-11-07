import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';

class KitchenDisplayState {
  final List<KitchenTicket> tickets;
  final KotStatus? statusFilter;
  final OrderType? typeFilter;
  final String searchQuery;
  final bool? _isLoading;
  bool get isLoading => _isLoading ?? false;

  final bool onlyActive;
  final bool onlyDelayed;

  const KitchenDisplayState({
    required this.tickets,
    this.statusFilter,
    this.typeFilter,
    this.searchQuery = '',
    bool isLoading = false,
    this.onlyActive = false,
    this.onlyDelayed = false,
  }) : _isLoading = isLoading;

  List<KitchenTicket> get filteredTickets {
    return tickets.where((t) {
      if (onlyActive && t.status == KotStatus.served) {
        return false;
      }
      if (onlyDelayed) {
        final elapsedMins = DateTime.now().difference(t.createdAt).inMinutes;
        if (elapsedMins < 15 || t.status == KotStatus.served) {
          return false;
        }
      }
      final matchesStatus = statusFilter == null || t.status == statusFilter;
      final matchesType = typeFilter == null || t.orderType == typeFilter;
      final matchesSearch = searchQuery.isEmpty ||
          t.kotNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t.tableLabel != null && t.tableLabel!.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesStatus && matchesType && matchesSearch;
    }).toList();
  }

  int get totalCount => tickets.length;
  int get activeCount => tickets.where((t) => t.status != KotStatus.served).length;
  int get newCount => tickets.where((t) => t.status == KotStatus.newOrder).length;
  int get preparingCount => tickets.where((t) => t.status == KotStatus.preparing).length;
  int get readyCount => tickets.where((t) => t.status == KotStatus.ready).length;
  int get servedCount => tickets.where((t) => t.status == KotStatus.served).length;
  int get delayedCount => tickets.where((t) {
        final mins = DateTime.now().difference(t.createdAt).inMinutes;
        return mins >= 15 && t.status != KotStatus.served;
      }).length;

  KitchenDisplayState copyWith({
    List<KitchenTicket>? tickets,
    KotStatus? Function()? statusFilter,
    OrderType? Function()? typeFilter,
    String? searchQuery,
    bool? isLoading,
    bool? onlyActive,
    bool? onlyDelayed,
  }) {
    return KitchenDisplayState(
      tickets: tickets ?? this.tickets,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      onlyActive: onlyActive ?? this.onlyActive,
      onlyDelayed: onlyDelayed ?? this.onlyDelayed,
    );
  }
}

class KitchenDisplayNotifier extends Notifier<KitchenDisplayState> {
  // Store client-side prepared item checkboxes keyed by "ticketId_itemId"
  final Map<String, bool> _preparedItemMap = {};
  // Store client-side kitchen ticket status override keyed by "orderId"
  final Map<String, KotStatus> _ticketStatusMap = {};
  Timer? _pollingTimer;

  @override
  KitchenDisplayState build() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      loadTickets(silent: true);
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    // Initial fetch from backend
    Future.microtask(() => loadTickets());
    return const KitchenDisplayState(tickets: [], isLoading: true);
  }

  /// Fetch live orders from backend and map them into active KDS tickets
  Future<void> loadTickets({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final outletId = await InventoryService.getShopId();
      final backendOrders = await RestaurantPosService.fetchOrders(outletId: outletId);
      final backendTables = await RestaurantPosService.fetchTables(outletId: outletId);
      final tableMap = {for (final t in backendTables) t.id: t};

      final List<KitchenTicket> mappedTickets = [];

      for (int i = 0; i < backendOrders.length; i++) {
        final order = backendOrders[i];

        // Resolve table details if present
        String? resolvedTable = order.tableLabel;
        String? resolvedFloor = order.floor;
        if (order.tableId != null && tableMap.containsKey(order.tableId)) {
          final tbl = tableMap[order.tableId]!;
          resolvedTable = tbl.label;
          if (resolvedFloor == null || resolvedFloor.isEmpty) {
            resolvedFloor = tbl.floor;
          }
        }

        // Map OrderStatus to KotStatus:
        // Lifecycle progression: New Order -> In Prep -> Ready -> Served
        KotStatus kotStatus;
        if (_ticketStatusMap.containsKey(order.id)) {
          kotStatus = _ticketStatusMap[order.id]!;
        } else {
          switch (order.status) {
            case OrderStatus.active:
              kotStatus = KotStatus.newOrder;
              break;
            case OrderStatus.hold:
              kotStatus = KotStatus.preparing;
              break;
            case OrderStatus.completed:
              // Recently placed orders (today) start in New Order or In-Prep on KDS until served!
              final ageHours = DateTime.now().difference(order.createdAt).inHours;
              if (ageHours < 6) {
                kotStatus = KotStatus.newOrder;
              } else {
                kotStatus = KotStatus.served;
              }
              break;
            case OrderStatus.cancelled:
              continue; // Skip cancelled orders on KDS
          }
        }

        // Map line items to KotItem
        final List<KotItem> kotItems = order.items.map((it) {
          final itemKey = '${order.id}_${it.item.id}';
          final isPrepared = _preparedItemMap[itemKey] ?? (kotStatus == KotStatus.served);
          return KotItem(
            id: it.item.id,
            name: it.item.name,
            quantity: it.quantity,
            notes: it.notes,
            isPrepared: isPrepared,
          );
        }).toList();

        // Server / source display
        String serverName = order.customerName;
        if (order.orderType == OrderType.takeaway) {
          serverName = 'Takeaway POS';
        } else if (order.orderType == OrderType.delivery) {
          serverName = 'Delivery Counter';
        }

        // Derive KOT number from real order number
        String kotNum = order.orderNumber.replaceAll('#', '').replaceAll('ORD-', 'KOT-');
        if (!kotNum.startsWith('KOT-')) {
          kotNum = 'KOT-${order.orderNumber.replaceAll("#", "")}';
        }

        mappedTickets.add(
          KitchenTicket(
            id: order.id,
            kotNumber: kotNum,
            orderNumber: order.orderNumber,
            orderType: order.orderType,
            tableLabel: resolvedTable,
            floor: resolvedFloor,
            serverName: serverName,
            status: kotStatus,
            createdAt: order.createdAt,
            items: kotItems,
            specialInstruction: order.notes,
          ),
        );
      }

      // Sort tickets: Newest orders first (createdAt descending), with in-prep prioritized
      mappedTickets.sort((a, b) {
        final aServed = a.status == KotStatus.served;
        final bServed = b.status == KotStatus.served;
        if (aServed != bServed) {
          return aServed ? 1 : -1; // Active tickets first
        }
        return b.createdAt.compareTo(a.createdAt); // Newest first
      });

      debugPrint('[KDS] Successfully mapped ${mappedTickets.length} real orders into KDS tickets');
      state = state.copyWith(tickets: mappedTickets, isLoading: false);
    } catch (e) {
      debugPrint('Error loading KDS tickets from backend: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Add a ticket directly into state so new POS orders appear instantly
  void addTicket(KitchenTicket ticket) {
    final existing = state.tickets.where((t) => t.id != ticket.id).toList();
    state = state.copyWith(tickets: [ticket, ...existing]);
  }

  void setStatusFilter(KotStatus? status) {
    state = state.copyWith(statusFilter: () => status, onlyActive: false, onlyDelayed: false);
  }

  void filterActiveOnly() {
    state = state.copyWith(statusFilter: () => null, onlyActive: true, onlyDelayed: false);
  }

  void filterDelayedOnly() {
    state = state.copyWith(statusFilter: () => null, onlyActive: false, onlyDelayed: true);
  }

  void showAll() {
    state = state.copyWith(statusFilter: () => null, onlyActive: false, onlyDelayed: false);
  }

  void setTypeFilter(OrderType? type) {
    state = state.copyWith(typeFilter: () => type);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  /// Update Ticket Status locally and synchronize with backend
  Future<void> updateTicketStatus(String ticketId, KotStatus nextStatus) async {
    _ticketStatusMap[ticketId] = nextStatus;

    // 1. Optimistic UI update
    final updated = state.tickets.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(status: nextStatus);
      }
      return t;
    }).toList();
    state = state.copyWith(tickets: updated);

    // 2. Synchronize transition with backend API
    try {
      String backendStatus = 'OPEN';
      switch (nextStatus) {
        case KotStatus.newOrder:
          backendStatus = 'OPEN';
          break;
        case KotStatus.preparing:
          backendStatus = 'SENT_TO_KITCHEN';
          break;
        case KotStatus.ready:
          backendStatus = 'HOLD';
          break;
        case KotStatus.served:
          // In food service lifecycle, "Served" means food is on the table, NOT settled/paid!
          // We keep the backend order status as 'HOLD' or 'OPEN' (so the table remains occupied and
          // bill payment remains available in POS).
          backendStatus = 'HOLD';
          break;
      }
      await RestaurantPosService.transitionOrderStatus(
        orderId: ticketId,
        targetStatus: backendStatus,
      );
    } catch (e) {
      debugPrint('Error syncing KDS status with backend: $e');
    }
  }

  /// Toggle item preparation checkbox
  void toggleItemPrepared(String ticketId, String itemId) {
    final itemKey = '${ticketId}_$itemId';
    final current = _preparedItemMap[itemKey] ?? false;
    _preparedItemMap[itemKey] = !current;

    final updated = state.tickets.map((t) {
      if (t.id == ticketId) {
        final updatedItems = t.items.map((it) {
          if (it.id == itemId) {
            return it.copyWith(isPrepared: !it.isPrepared);
          }
          return it;
        }).toList();
        return t.copyWith(items: updatedItems);
      }
      return t;
    }).toList();
    state = state.copyWith(tickets: updated);
  }
}

final kitchenDisplayProvider =
    NotifierProvider<KitchenDisplayNotifier, KitchenDisplayState>(() {
  return KitchenDisplayNotifier();
});
