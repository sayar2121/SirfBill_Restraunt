import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/restaurant_pos_models.dart';

class PosTableSelector extends StatelessWidget {
  final String selectedFloor;
  final String? selectedTableId;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<String> onSelectTable;
  final List<DiningTable>? tables;
  final VoidCallback? onRefresh;

  const PosTableSelector({
    super.key,
    required this.selectedFloor,
    required this.selectedTableId,
    required this.onSelectFloor,
    required this.onSelectTable,
    this.tables,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final tableList = tables ?? const [];
    final floorList = <String>{};
    for (final t in tableList) {
      if (t.floor.trim().isNotEmpty) floorList.add(t.floor.trim());
    }
    final hasRealFloors = floorList.isNotEmpty;
    final effectiveFloor = hasRealFloors
        ? (floorList.contains(selectedFloor) ? selectedFloor : floorList.first)
        : '';
    final floorTables = tableList.where((t) => t.floor == effectiveFloor).toList();
    final displayList = floorTables.isNotEmpty ? floorTables : tableList;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Table Selection", Floor dropdown, "View Floor Plan"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_restaurant_rounded, size: 20, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Table Selection',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ],
              ),
              Row(
                children: [
                  if (hasRealFloors) ...[
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: Border.all(color: borderColor, width: 1.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: effectiveFloor,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          items: floorList.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) {
                            if (val != null) onSelectFloor(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onRefresh != null) ...[
                    Tooltip(
                      message: 'Refresh Tables',
                      child: InkWell(
                        onTap: onRefresh,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: const Center(
                            child: Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () => context.go('/counter/tables'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: const Size(0, 36),
                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF3B82F6)),
                    label: const Text('Floor Plan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Scrollable Table Chips (T1, T2, T3, T4...)
          SizedBox(
            height: 72,
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      'No tables set up yet.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final table = displayList[index];
                      final isSelected = table.id == selectedTableId;
                      final isOccupied = table.status == TableStatus.occupied;
                      final isReserved = table.status == TableStatus.reserved;

                      // Color coding:
                      // Occupied = Amber/Orange/Red (Warm)
                      // Reserved = Amber (Warm)
                      // Available/Empty = Emerald/Green
                      final statusPrimaryColor = isOccupied
                          ? const Color(0xFFEF4444)
                          : (isReserved ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelectTable(table.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 96,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? statusPrimaryColor
                                : (isOccupied
                                    ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2))
                                    : (isReserved
                                        ? (isDark ? const Color(0xFF452B0E) : const Color(0xFFFFFBEB))
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)))),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? statusPrimaryColor
                                  : (isOccupied
                                      ? const Color(0xFFFCA5A5)
                                      : (isReserved ? const Color(0xFFFCD34D) : borderColor)),
                              width: isSelected ? 2.5 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: statusPrimaryColor.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                table.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? Colors.white
                                      : (isOccupied
                                          ? const Color(0xFFDC2626)
                                          : (isReserved
                                              ? const Color(0xFFD97706)
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)))),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${table.capacity} Seater',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isOccupied
                                          ? const Color(0xFFDC2626)
                                          : (isReserved ? const Color(0xFFB45309) : const Color(0xFF64748B))),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              if (isOccupied)
                                TableLiveDurationBadge(
                                  table: table,
                                  isSelected: isSelected,
                                )
                              else
                                Text(
                                  isOccupied
                                      ? 'Occupied'
                                      : (isReserved ? 'Reserved' : 'Empty'),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : (isOccupied
                                            ? const Color(0xFFEF4444)
                                            : (isReserved ? const Color(0xFFF59E0B) : const Color(0xFF10B981))),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


/// Dedicated widget that ticks every second to display live moving HH:MM:SS
class TableLiveDurationBadge extends StatefulWidget {
  final DiningTable table;
  final bool isSelected;

  const TableLiveDurationBadge({
    super.key,
    required this.table,
    required this.isSelected,
  });

  @override
  State<TableLiveDurationBadge> createState() => _TableLiveDurationBadgeState();
}

class _TableLiveDurationBadgeState extends State<TableLiveDurationBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration() {
    if (widget.table.occupiedSince != null) {
      final diff = DateTime.now().difference(widget.table.occupiedSince!);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    final raw = widget.table.occupiedDuration ?? '00:00:00';
    if (raw.split(':').length == 2) {
      return '$raw:00';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: widget.isSelected ? Colors.white24 : const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatDuration(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: widget.isSelected ? Colors.white : const Color(0xFFEF4444),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
