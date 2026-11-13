import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';
import 'waiter_table_components.dart';

/// Touch-optimized dining table strip for Waitstaff / Captains.
/// Refactored into clean presentation components:
/// - [WaiterTableStripHeader]: Title, filter pills, floor selector dropdown, and refresh button.
/// - [WaiterTableFilterChip]: Segmented status filter pill.
/// - [WaiterTableCardItem]: Horizontal carousel dining table card.
class WaiterTableStrip extends StatefulWidget {
  final List<DiningTable> tables;
  final Set<String>? readyTableLabels;
  final String selectedFloor;
  final String? selectedTableId;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<DiningTable> onSelectTable;
  final VoidCallback onRefresh;

  const WaiterTableStrip({
    super.key,
    required this.tables,
    this.readyTableLabels,
    required this.selectedFloor,
    required this.selectedTableId,
    required this.onSelectFloor,
    required this.onSelectTable,
    required this.onRefresh,
  });

  @override
  State<WaiterTableStrip> createState() => _WaiterTableStripState();
}

class _WaiterTableStripState extends State<WaiterTableStrip> {
  // Filter by status: 'all', 'free', 'seated'
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Collect distinct floors
    final floorList = <String>{};
    for (final t in widget.tables) {
      if (t.floor.trim().isNotEmpty) floorList.add(t.floor.trim());
    }
    if (floorList.isEmpty) floorList.add('1st Floor');

    final effectiveFloor = floorList.contains(widget.selectedFloor)
        ? widget.selectedFloor
        : floorList.first;

    final floorTables = widget.tables.where((t) => t.floor.trim().isEmpty || t.floor.trim() == effectiveFloor).toList();
    final baseTables = floorTables.isNotEmpty ? floorTables : widget.tables;

    final occupiedCount = baseTables.where((t) => t.status == TableStatus.occupied).length;
    final availableCount = baseTables.length - occupiedCount;

    // Apply status filter
    final displayTables = baseTables.where((t) {
      if (_statusFilter == 'free') return t.status != TableStatus.occupied;
      if (_statusFilter == 'seated') return t.status == TableStatus.occupied;
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header: Section Title + Filter Tabs + Floor & Refresh (Adaptive)
          WaiterTableStripHeader(
            effectiveFloor: effectiveFloor,
            floorList: floorList.toList(),
            onSelectFloor: widget.onSelectFloor,
            onRefresh: widget.onRefresh,
            statusFilter: _statusFilter,
            onStatusFilterChanged: (val) => setState(() => _statusFilter = val),
            totalCount: baseTables.length,
            freeCount: availableCount,
            seatedCount: occupiedCount,
          ),
          const SizedBox(height: 12),

          // 2. Horizontal Carousel of Table Cards
          SizedBox(
            height: 78,
            child: displayTables.isEmpty
                ? Center(
                    child: Text(
                      _statusFilter == 'seated'
                          ? 'No tables are currently occupied'
                          : 'No tables found for this filter',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayTables.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final table = displayTables[idx];
                      final isSelected = table.id == widget.selectedTableId;
                      final hasReadyOrder = widget.readyTableLabels?.contains(table.label.trim()) ?? false;

                      return WaiterTableCardItem(
                        table: table,
                        isSelected: isSelected,
                        hasReadyOrder: hasReadyOrder,
                        onSelect: widget.onSelectTable,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
