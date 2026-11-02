import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant_pos_models.dart';
import '../../providers/restaurant_pos_provider.dart';
import '../../providers/restaurant_table_provider.dart';
import 'widgets/tables/table_card.dart';
import 'widgets/tables/table_filter_header.dart';
import 'widgets/tables/add_table_dialog.dart';
import 'widgets/tables/table_detail_modal.dart';

class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(restaurantTableProvider.notifier).loadTables();
    });
    // Live periodic sync with backend & POS every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.read(restaurantTableProvider.notifier).loadTables(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableState = ref.watch(restaurantTableProvider);
    final tableNotifier = ref.read(restaurantTableProvider.notifier);
    final posNotifier = ref.read(restaurantPosProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final tables = tableState.filteredTables;

    return Scaffold(
      backgroundColor: screenBg,
      body: RefreshIndicator(
        onRefresh: () => ref.read(restaurantTableProvider.notifier).loadTables(),
        child: Column(
          children: [
            // 1. Header with Floor Pills, Status Toggles, Search and Add Table
            TableFilterHeader(
              floors: tableState.availableFloors,
              totalCount: tableState.totalCount,
              availableCount: tableState.availableCount,
              occupiedCount: tableState.occupiedCount,
              reservedCount: tableState.reservedCount,
              selectedFloor: tableState.selectedFloor,
              statusFilter: tableState.statusFilter,
              onSelectFloor: tableNotifier.setFloor,
              onSelectStatus: tableNotifier.setStatusFilter,
              onSearch: tableNotifier.setSearchQuery,
              onAddTable: () => _showAddTableDialog(context, tableNotifier, tableState.availableFloors),
              onRefresh: () => tableNotifier.loadTables(),
            ),

          // 2. Responsive Table Matrix Grid
          Expanded(
            child: Builder(
              builder: (context) {
                if (tableState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_restaurant_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'No tables found in this outlet database',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create dining tables and assign them to floors or dining areas.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTableDialog(context, tableNotifier, tableState.availableFloors),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add First Table'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount;
                    double childAspectRatio;

                    if (width < 500) {
                      crossAxisCount = 1;
                      childAspectRatio = 1.8;
                    } else if (width < 850) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.35;
                    } else if (width < 1200) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.38;
                    } else if (width < 1600) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.40;
                    } else {
                      crossAxisCount = 5;
                      childAspectRatio = 1.45;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: tables.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return TableCard(
                          table: table,
                          onTap: () => _showTableDetailDialog(
                            context,
                            table,
                            tableNotifier,
                            posNotifier,
                            tableState.availableFloors,
                          ),
                          onEdit: () => _showEditTableDialog(
                            context,
                            table,
                            tableNotifier,
                            tableState.availableFloors,
                          ),
                          onOpenPos: () {
                            posNotifier.selectFloor(table.floor);
                            posNotifier.selectTable(table.id);
                            posNotifier.setOrderType(OrderType.dineIn);
                            context.go('/counter/billing');
                          },
                          onStatusToggle: () {
                            final nextStatus = table.status == TableStatus.available
                                ? TableStatus.occupied
                                : TableStatus.available;
                            tableNotifier.updateTableStatus(table.id, nextStatus);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showAddTableDialog(
    BuildContext context,
    RestaurantTableNotifier notifier,
    List<String> floors,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AddTableDialog(
        existingFloors: floors,
        onSave: (data) async {
          await notifier.addTable(
            label: data.label,
            capacity: data.capacity,
            floor: data.floor,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Table ${data.label} created successfully on ${data.floor}!')),
            );
          }
        },
      ),
    );
  }

  void _showEditTableDialog(
    BuildContext context,
    DiningTable table,
    RestaurantTableNotifier notifier,
    List<String> floors,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AddTableDialog(
        existingFloors: floors,
        initialTable: table,
        onSave: (data) async {
          await notifier.updateTable(
            tableId: table.id,
            label: data.label,
            capacity: data.capacity,
            floor: data.floor,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Table ${data.label} updated successfully!')),
            );
          }
        },
      ),
    );
  }

  void _showTableDetailDialog(
    BuildContext context,
    DiningTable table,
    RestaurantTableNotifier tableNotifier,
    RestaurantPosNotifier posNotifier,
    List<String> floors,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TableDetailModal(
        table: table,
        onUpdateStatus: (status) => tableNotifier.updateTableStatus(table.id, status),
        onOpenPos: () {
          posNotifier.selectFloor(table.floor);
          posNotifier.selectTable(table.id);
          posNotifier.setOrderType(OrderType.dineIn);
          context.go('/counter/billing');
        },
        onEdit: () => _showEditTableDialog(context, table, tableNotifier, floors),
        onDelete: () {
          tableNotifier.deleteTable(table.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Table ${table.label} removed.')),
          );
        },
      ),
    );
  }

}
