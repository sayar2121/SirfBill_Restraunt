import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';

class RestaurantTableState {
  final List<DiningTable> tables;
  final String selectedFloor;
  final TableStatus? statusFilter;
  final String searchQuery;
  final bool isLoading;

  const RestaurantTableState({
    required this.tables,
    this.selectedFloor = 'All Floors',
    this.statusFilter,
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<String> get availableFloors {
    final floors = <String>{'All Floors'};
    for (final t in tables) {
      if (t.floor.trim().isNotEmpty) {
        floors.add(t.floor.trim());
      }
    }
    return floors.toList();
  }

  List<DiningTable> get filteredTables {
    return tables.where((t) {
      final matchesFloor =
          selectedFloor == 'All Floors' || t.floor == selectedFloor;
      final matchesStatus =
          statusFilter == null || t.status == statusFilter;
      final matchesSearch = searchQuery.isEmpty ||
          t.label.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.floor.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFloor && matchesStatus && matchesSearch;
    }).toList();
  }

  int get totalCount => tables.length;
  int get availableCount =>
      tables.where((t) => t.status == TableStatus.available).length;
  int get occupiedCount =>
      tables.where((t) => t.status == TableStatus.occupied).length;
  int get reservedCount =>
      tables.where((t) => t.status == TableStatus.reserved).length;

  RestaurantTableState copyWith({
    List<DiningTable>? tables,
    String? selectedFloor,
    TableStatus? Function()? statusFilter,
    String? searchQuery,
    bool? isLoading,
  }) {
    return RestaurantTableState(
      tables: tables ?? this.tables,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RestaurantTableNotifier extends Notifier<RestaurantTableState> {
  @override
  RestaurantTableState build() {
    Future.microtask(() => loadTables());
    return const RestaurantTableState(
      tables: [],
      isLoading: true,
    );
  }

  Future<void> loadTables({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final outletId = await InventoryService.getShopId();
      final backendTables = await RestaurantPosService.fetchTables(outletId: outletId);
      state = state.copyWith(tables: backendTables, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFloor(String floor) {
    state = state.copyWith(selectedFloor: floor);
  }

  void setStatusFilter(TableStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addTable({
    required String label,
    required int capacity,
    required String floor,
  }) async {
    String? outletId;
    try {
      outletId = await InventoryService.getShopId();
    } catch (_) {}

    final backendTable = await RestaurantPosService.createTable(
      label: label,
      capacity: capacity,
      floor: floor,
      outletId: outletId,
    );

    if (backendTable != null) {
      // Reload fresh list from backend to get full live sync
      await loadTables();
    } else {
      // Fallback optimistic table
      final newTable = DiningTable(
        id: 'T_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        capacity: capacity,
        status: TableStatus.available,
        floor: floor,
      );
      state = state.copyWith(tables: [...state.tables, newTable]);
    }
  }

  Future<void> updateTable({
    required String tableId,
    required String label,
    required int capacity,
    required String floor,
  }) async {
    final updated = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          label: label,
          capacity: capacity,
          floor: floor,
        );
      }
      return table;
    }).toList();
    state = state.copyWith(tables: updated);

    await RestaurantPosService.updateTable(
      tableId: tableId,
      label: label,
      capacity: capacity,
      floor: floor,
    );
    await loadTables();
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    // 1. Optimistic UI update
    final updated = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: status,
          occupiedDuration: status == TableStatus.occupied ? '00:00:01' : null,
          occupiedSince: status == TableStatus.occupied ? DateTime.now() : null,
          currentBillAmount: status == TableStatus.available ? 0.0 : table.currentBillAmount,
          activeOrderCount: status == TableStatus.available ? 0 : table.activeOrderCount,
        );
      }
      return table;
    }).toList();
    state = state.copyWith(tables: updated);

    // 2. Sync with backend API
    await RestaurantPosService.updateTableStatus(tableId, status);
  }

  Future<void> deleteTable(String tableId) async {
    state = state.copyWith(
      tables: state.tables.where((t) => t.id != tableId).toList(),
    );
    await RestaurantPosService.deleteTable(tableId);
  }
}

final restaurantTableProvider =
    NotifierProvider<RestaurantTableNotifier, RestaurantTableState>(() {
  return RestaurantTableNotifier();
});

