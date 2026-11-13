import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';
import '../services/kitchen_audio_service.dart';
import '../widgets/common_filter_pills.dart';

class KitchenDisplayState {
  final List<KitchenTicket> tickets;
  final KotStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset? _datePreset;
  final DateTimeRange? customRange;
  final String searchQuery;
  final bool? _isLoading;
  bool get isLoading => _isLoading ?? false;

  final bool onlyActive;
  final bool onlyDelayed;
  final bool isSoundEnabled;
  final KitchenTicket? pendingAlertTicket;

  DateRangePreset get datePreset => _datePreset ?? DateRangePreset.all;

  const KitchenDisplayState({
    required this.tickets,
    this.statusFilter,
    this.typeFilter,
    DateRangePreset? datePreset,
    this.customRange,
    this.searchQuery = '',
    bool isLoading = false,
    this.onlyActive = false,
    this.onlyDelayed = false,
    this.isSoundEnabled = true,
    this.pendingAlertTicket,
  })  : _datePreset = datePreset ?? DateRangePreset.all,
        _isLoading = isLoading;

  bool _matchesDateFilter(DateTime ticketDate) {
    final now = DateTime.now();

    switch (datePreset) {
      case DateRangePreset.all:
        return true;
      case DateRangePreset.today:
        return ticketDate.year == now.year &&
            ticketDate.month == now.month &&
            ticketDate.day == now.day;
      case DateRangePreset.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(monday.year, monday.month, monday.day);
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return ticketDate.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
            ticketDate.isBefore(endOfWeek);
      case DateRangePreset.thisMonth:
        return ticketDate.year == now.year && ticketDate.month == now.month;
      case DateRangePreset.thisYear:
        return ticketDate.year == now.year;
      case DateRangePreset.custom:
        if (customRange == null) return true;
        final start = DateTime(customRange!.start.year, customRange!.start.month, customRange!.start.day);
        final end = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day, 23, 59, 59, 999);
        return ticketDate.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            ticketDate.isBefore(end.add(const Duration(milliseconds: 1)));
    }
  }

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
      final matchesDate = _matchesDateFilter(t.createdAt);
      final matchesStatus = statusFilter == null || t.status == statusFilter;
      final matchesType = typeFilter == null || t.orderType == typeFilter;
      final matchesSearch = searchQuery.isEmpty ||
          t.kotNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t.tableLabel != null && t.tableLabel!.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesDate && matchesStatus && matchesType && matchesSearch;
    }).toList();
  }

  int get totalCount => tickets.where((t) => _matchesDateFilter(t.createdAt)).length;
  int get activeCount => tickets.where((t) => _matchesDateFilter(t.createdAt) && t.status != KotStatus.served).length;
  int get newCount => tickets.where((t) => _matchesDateFilter(t.createdAt) && t.status == KotStatus.newOrder).length;
  int get preparingCount => tickets.where((t) => _matchesDateFilter(t.createdAt) && t.status == KotStatus.preparing).length;
  int get readyCount => tickets.where((t) => _matchesDateFilter(t.createdAt) && t.status == KotStatus.ready).length;
  int get servedCount => tickets.where((t) => _matchesDateFilter(t.createdAt) && t.status == KotStatus.served).length;
  int get delayedCount => tickets.where((t) {
        if (!_matchesDateFilter(t.createdAt)) return false;
        final mins = DateTime.now().difference(t.createdAt).inMinutes;
        return mins >= 15 && t.status != KotStatus.served;
      }).length;

  KitchenDisplayState copyWith({
    List<KitchenTicket>? tickets,
    KotStatus? Function()? statusFilter,
    OrderType? Function()? typeFilter,
    DateRangePreset? datePreset,
    DateTimeRange? Function()? customRange,
    String? searchQuery,
    bool? isLoading,
    bool? onlyActive,
    bool? onlyDelayed,
    bool? isSoundEnabled,
    KitchenTicket? Function()? pendingAlertTicket,
  }) {
    return KitchenDisplayState(
      tickets: tickets ?? this.tickets,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      datePreset: datePreset ?? this.datePreset,
      customRange: customRange != null ? customRange() : this.customRange,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      onlyActive: onlyActive ?? this.onlyActive,
      onlyDelayed: onlyDelayed ?? this.onlyDelayed,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      pendingAlertTicket: pendingAlertTicket != null ? pendingAlertTicket() : this.pendingAlertTicket,
    );
  }
}

class KitchenDisplayNotifier extends Notifier<KitchenDisplayState> {
  // Store client-side prepared item checkboxes keyed by "ticketId_itemId"
  static final Map<String, bool> _preparedItemMap = {};
  // Store client-side kitchen ticket status override keyed by "orderId"
  static final Map<String, KotStatus> _ticketStatusMap = {};
  // Store time when preparation was started / order accepted
  static final Map<String, DateTime> _prepStartTimeMap = {};
  // Store served quantities per item key: "${orderId}_${baseItemId}" -> quantity served
  static final Map<String, int> _servedItemQuantities = {};
  // Track total item count per order to detect running items added by waiter
  static final Map<String, int> _orderItemCountMap = {};
  // Track order IDs with newly added running items awaiting kitchen alert
  static final Set<String> _updatedOrderIds = {};
  static final Set<String> _runningItemKeys = {};
  // Track known ticket IDs to detect new incoming tickets and ring alert
  final Set<String> _knownTicketIds = {};
  bool _hasInitialLoaded = false;
  Timer? _pollingTimer;

  @override
  KitchenDisplayState build() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadTickets(silent: true);
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
      KitchenAudioService.stop();
    });

    // Initial fetch from backend - default sound to false (muted) so POS billing & normal tabs never ring audio!
    // Sound is only active when explicitly enabled in dedicated KDS mode (/kitchen).
    Future.microtask(() => loadTickets());
    return const KitchenDisplayState(
      tickets: [],
      isLoading: true,
      onlyActive: true,
      isSoundEnabled: false,
    );
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

        // Detect if waiter added running items to an existing order
        final totalItemCount = order.items.fold<int>(0, (sum, it) => sum + it.quantity);
        final previousCount = _orderItemCountMap[order.id];
        final bool hasNewItems = previousCount != null && totalItemCount > previousCount;
        _orderItemCountMap[order.id] = totalItemCount;

        if (hasNewItems) {
          _updatedOrderIds.add(order.id);
          _ticketStatusMap[order.id] = KotStatus.newOrder;
          _prepStartTimeMap.remove(order.id);
        }

        // Map OrderStatus to KotStatus:
        // Prioritize real-time backend order state (READY, SERVED) across all devices!
        KotStatus kotStatus;
        if (_ticketStatusMap[order.id] == KotStatus.served && !hasNewItems) {
          // If already marked served on this client (or backend) and no new items added, stay SERVED!
          kotStatus = KotStatus.served;
        } else if (order.status == OrderStatus.served && !hasNewItems) {
          // Explicitly marked SERVED on backend
          kotStatus = KotStatus.served;
          _ticketStatusMap[order.id] = KotStatus.served;
        } else if (order.status == OrderStatus.ready) {
          // Explicitly marked READY on backend (kitchen cooked it, ready for waiter to serve!)
          kotStatus = KotStatus.ready;
          _ticketStatusMap[order.id] = KotStatus.ready;
        } else if (_ticketStatusMap.containsKey(order.id)) {
          kotStatus = _ticketStatusMap[order.id]!;
        } else {
          final ageHours = DateTime.now().difference(order.createdAt).inHours;
          final isRecentOrder = ageHours < 12;

          switch (order.status) {
            case OrderStatus.ready:
              kotStatus = KotStatus.ready;
              break;
            case OrderStatus.active:
              kotStatus = KotStatus.newOrder;
              break;
            case OrderStatus.hold:
              // For Dine-in / held unpaid orders, keep them active in kitchen until served
              if (isRecentOrder) {
                kotStatus = KotStatus.newOrder;
              } else {
                kotStatus = KotStatus.served;
              }
              break;
            case OrderStatus.completed:
              // When POS confirms payment/settlement on Takeaway or Dine-In, kitchen still needs to PREPARE and SERVE it!
              // Only when kitchen staff marks it Served (or order is older than today), is it moved to served.
              if (isRecentOrder) {
                kotStatus = KotStatus.newOrder;
              } else {
                kotStatus = KotStatus.served;
              }
              break;
            case OrderStatus.served:
              // Explicitly served by kitchen staff!
              kotStatus = KotStatus.served;
              break;
            case OrderStatus.cancelled:
              continue; // Skip cancelled orders on KDS
          }
        }

        // Initialize served quantities if order came from backend in served status
        if (order.status == OrderStatus.served) {
          for (final it in order.items) {
            final key = '${order.id}_${it.item.id}';
            _servedItemQuantities.putIfAbsent(key, () => it.quantity);
            _preparedItemMap[key] = true;
          }
        }

        // Map line items to KotItem with granular tracking of served vs new running items
        final List<KotItem> kotItems = [];
        bool hasAnyUnprepared = false;

        for (final it in order.items) {
          final baseId = it.item.id;
          final itemKey = '${order.id}_$baseId';
          final servedQty = _servedItemQuantities[itemKey] ?? 0;
          final isExplicitlyToggled = _preparedItemMap[itemKey];

          if (kotStatus == KotStatus.served && !hasNewItems) {
            // Entire order was marked served and no running items were added
            kotItems.add(KotItem(
              id: baseId,
              name: it.item.name,
              quantity: it.quantity,
              notes: it.notes,
              isPrepared: true,
              isRunningItem: false,
            ));
            _servedItemQuantities[itemKey] = it.quantity;
            _preparedItemMap[itemKey] = true;
          } else if (servedQty > 0) {
            if (it.quantity > servedQty) {
              // Partial quantity was already served, extra quantity is new running items
              // 1. Portion that was already served:
              kotItems.add(KotItem(
                id: '${baseId}_served',
                name: it.item.name,
                quantity: servedQty,
                notes: it.notes,
                isPrepared: true,
                isRunningItem: false,
              ));
              // 2. Portion that is newly added:
              kotItems.add(KotItem(
                id: baseId,
                name: it.item.name,
                quantity: it.quantity - servedQty,
                notes: it.notes,
                isPrepared: false,
                isRunningItem: true,
              ));
              hasAnyUnprepared = true;
            } else {
              // Entire quantity was already served!
              kotItems.add(KotItem(
                id: baseId,
                name: it.item.name,
                quantity: it.quantity,
                notes: it.notes,
                isPrepared: isExplicitlyToggled ?? true,
                isRunningItem: false,
              ));
            }
          } else {
            // Brand new item added to the order
            final isPrep = isExplicitlyToggled ?? false;
            final isRunning = hasNewItems || _runningItemKeys.contains(itemKey);
            kotItems.add(KotItem(
              id: baseId,
              name: it.item.name,
              quantity: it.quantity,
              notes: it.notes,
              isPrepared: isPrep,
              isRunningItem: isRunning,
            ));
            if (!isPrep) {
              hasAnyUnprepared = true;
            }
          }
        }

        // If ticket has newly added / unprepared items, ensure its queue status is newOrder
        if (hasAnyUnprepared && (kotStatus == KotStatus.served || hasNewItems)) {
          kotStatus = KotStatus.newOrder;
          _ticketStatusMap[order.id] = KotStatus.newOrder;
          _prepStartTimeMap.remove(order.id);
        }

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
            prepStartedAt: _prepStartTimeMap[order.id],
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

      // Detect newly arrived tickets OR tickets with newly added running items
      KitchenTicket? firstNewTicket;
      if (_hasInitialLoaded) {
        final newlyArrived = mappedTickets.where(
          (t) => (!_knownTicketIds.contains(t.id) || _updatedOrderIds.contains(t.id)) && t.status != KotStatus.served,
        ).toList();
        if (newlyArrived.isNotEmpty) {
          firstNewTicket = newlyArrived.first;
          _updatedOrderIds.remove(firstNewTicket.id);
          if (state.isSoundEnabled) {
            KitchenAudioService.playNewOrderAlert(loop: true);
          }
        }
      }

      // Update known ticket set
      for (final t in mappedTickets) {
        _knownTicketIds.add(t.id);
      }
      _hasInitialLoaded = true;

      debugPrint('[KDS] Successfully mapped ${mappedTickets.length} real orders into KDS tickets');
      state = state.copyWith(
        tickets: mappedTickets,
        isLoading: false,
        pendingAlertTicket: firstNewTicket != null ? () => firstNewTicket : null,
      );
    } catch (e) {
      debugPrint('Error loading KDS tickets from backend: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Add a ticket directly into state so new POS orders appear instantly
  void addTicket(KitchenTicket ticket) {
    _knownTicketIds.add(ticket.id);
    final existing = state.tickets.where((t) => t.id != ticket.id).toList();
    state = state.copyWith(
      tickets: [ticket, ...existing],
      pendingAlertTicket: () => ticket,
    );

    if (state.isSoundEnabled && ticket.status != KotStatus.served) {
      KitchenAudioService.playNewOrderAlert(loop: true);
    }
  }

  void clearPendingAlert() {
    KitchenAudioService.stop();
    state = state.copyWith(pendingAlertTicket: () => null);
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
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

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(
      datePreset: preset,
      customRange: () => null,
      onlyActive: false,
      onlyDelayed: false,
    );
  }

  void setCustomRange(DateTimeRange? range) {
    state = state.copyWith(
      datePreset: DateRangePreset.custom,
      customRange: () => range,
      onlyActive: false,
      onlyDelayed: false,
    );
  }

  /// Update Ticket Status locally and synchronize with backend
  Future<void> updateTicketStatus(String ticketId, KotStatus nextStatus) async {
    _ticketStatusMap[ticketId] = nextStatus;

    // When advancing to 'preparing', record the acceptance timestamp so prep timer starts from 00:00!
    if (nextStatus == KotStatus.preparing && !_prepStartTimeMap.containsKey(ticketId)) {
      _prepStartTimeMap[ticketId] = DateTime.now();
    }

    // When marking ready or served, record all items as completed and update served quantities
    if (nextStatus == KotStatus.served || nextStatus == KotStatus.ready) {
      final ticket = state.tickets.where((t) => t.id == ticketId).firstOrNull;
      if (ticket != null) {
        for (final it in ticket.items) {
          final baseId = it.id.replaceAll('_served', '').replaceAll('_new', '');
          final itemKey = '${ticketId}_$baseId';
          _preparedItemMap['${ticketId}_${it.id}'] = true;
          _preparedItemMap[itemKey] = true;
          _servedItemQuantities[itemKey] = it.quantity;
          _runningItemKeys.remove('${ticketId}_${it.id}');
          _runningItemKeys.remove(itemKey);
        }
      }
    }

    // Stop audio alert if this ticket was the pending alert
    if (state.pendingAlertTicket?.id == ticketId) {
      KitchenAudioService.stop();
    }

    // 1. Optimistic UI update
    final updated = state.tickets.map((t) {
      if (t.id == ticketId) {
        final updatedItems = (nextStatus == KotStatus.served || nextStatus == KotStatus.ready)
            ? t.items.map((it) => it.copyWith(isPrepared: true, isRunningItem: false)).toList()
            : t.items;
        return t.copyWith(
          status: nextStatus,
          prepStartedAt: _prepStartTimeMap[ticketId] ?? t.prepStartedAt,
          items: updatedItems,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(
      tickets: updated,
      pendingAlertTicket: state.pendingAlertTicket?.id == ticketId ? () => null : null,
    );

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
          backendStatus = 'READY';
          break;
        case KotStatus.served:
          // In food service lifecycle, when kitchen marks "Served", transition backend status to SERVED
          backendStatus = 'SERVED';
          break;
      }
      await RestaurantPosService.transitionOrderStatus(
        orderId: ticketId,
        targetStatus: backendStatus,
      );

      // Important: When marking "Served", if this ticket belongs to a Dine-In table,
      // explicitly ensure the table stays OCCUPIED until the cashier completes payment!
      if (nextStatus == KotStatus.served) {
        final ticket = state.tickets.where((t) => t.id == ticketId).firstOrNull;
        if (ticket != null && ticket.orderType == OrderType.dineIn) {
          // Keep table marked as OCCUPIED so table occupancy is not lost when order is served
          final tableLabel = ticket.tableLabel;
          if (tableLabel != null && tableLabel.isNotEmpty) {
            final outletId = await InventoryService.getShopId();
            final tables = await RestaurantPosService.fetchTables(outletId: outletId);
            final match = tables.where((tbl) =>
                tbl.id == tableLabel ||
                tbl.label.toLowerCase() == tableLabel.toLowerCase()).firstOrNull;
            if (match != null) {
              await RestaurantPosService.updateTableStatus(match.id, TableStatus.occupied);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing KDS status with backend: $e');
    }
  }

  /// Toggle item preparation checkbox
  void toggleItemPrepared(String ticketId, String itemId) {
    final baseId = itemId.replaceAll('_served', '').replaceAll('_new', '');
    final itemKey = '${ticketId}_$baseId';
    final current = _preparedItemMap[itemKey] ?? false;
    _preparedItemMap[itemKey] = !current;
    _preparedItemMap['${ticketId}_$itemId'] = !current;

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

  /// Keep already-prepared items marked as DONE when new running items are added to a table order!
  /// Only the newly added items remain unchecked (NEW ADDED) so cooks know exactly what to prepare.
  void markRunningItemsForOrder({
    required String orderId,
    required List<String> existingPreparedItemIds,
    required List<String> newlyAddedItemIds,
  }) {
    _ticketStatusMap[orderId] = KotStatus.newOrder;
    _prepStartTimeMap.remove(orderId);
    _updatedOrderIds.add(orderId);

    // Keep existing items marked as prepared/done
    for (final id in existingPreparedItemIds) {
      final baseId = id.replaceAll('_served', '').replaceAll('_new', '');
      _preparedItemMap['${orderId}_$baseId'] = true;
      if (!_servedItemQuantities.containsKey('${orderId}_$baseId')) {
        _servedItemQuantities['${orderId}_$baseId'] = 1;
      }
    }
    // Mark newly added items as NOT prepared and flag them as running items
    for (final id in newlyAddedItemIds) {
      final baseId = id.replaceAll('_served', '').replaceAll('_new', '');
      _preparedItemMap['${orderId}_$baseId'] = false;
      _runningItemKeys.add('${orderId}_$baseId');
    }
  }

  /// Reset ticket status back to newOrder when running items are added to an existing/served order
  void resetTicketForNewItems(String orderId) {
    _ticketStatusMap.remove(orderId);
    _prepStartTimeMap.remove(orderId);
  }
}

final kitchenDisplayProvider =
    NotifierProvider<KitchenDisplayNotifier, KitchenDisplayState>(() {
  return KitchenDisplayNotifier();
});
