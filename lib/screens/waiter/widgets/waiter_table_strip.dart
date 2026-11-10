import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';

/// Touch-optimized, luxury Dining Table Strip designed specifically
/// for Waitstaff / Captains to quickly view and switch dining tables.
class WaiterTableStrip extends StatefulWidget {
  final List<DiningTable> tables;
  final String selectedFloor;
  final String? selectedTableId;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<DiningTable> onSelectTable;
  final VoidCallback onRefresh;

  const WaiterTableStrip({
    super.key,
    required this.tables,
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
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 620;

              // Filter Segmented Pills: All, Free, Seated
              final filterPills = Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip(
                      label: 'All (${baseTables.length})',
                      filterKey: 'all',
                      dotColor: const Color(0xFF3B82F6),
                      isSelected: _statusFilter == 'all',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 2),
                    _buildFilterChip(
                      label: 'Free ($availableCount)',
                      filterKey: 'free',
                      dotColor: const Color(0xFF10B981),
                      isSelected: _statusFilter == 'free',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 2),
                    _buildFilterChip(
                      label: 'Seated ($occupiedCount)',
                      filterKey: 'seated',
                      dotColor: const Color(0xFFEF4444),
                      isSelected: _statusFilter == 'seated',
                      isDark: isDark,
                    ),
                  ],
                ),
              );

              // Floor Selector & Refresh
              final floorAndRefresh = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: Border.all(color: borderColor, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveFloor,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        items: floorList
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) widget.onSelectFloor(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Refresh Tables',
                    child: InkWell(
                      onTap: widget.onRefresh,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.sync_rounded, size: 15, color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              );

              // Table Title
              final tableTitle = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.table_restaurant_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tables',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tableTitle,
                        floorAndRefresh,
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: filterPills,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  tableTitle,
                  const SizedBox(width: 14),
                  filterPills,
                  const Spacer(),
                  floorAndRefresh,
                ],
              );
            },
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
                      final isOccupied = table.status == TableStatus.occupied;

                      // Visual theme per state
                      Color borderC;
                      Color bgC;
                      Color accentC;
                      String statusText;
                      String subtitle;

                      if (isSelected) {
                        borderC = isOccupied ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
                        bgC = isOccupied
                            ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2))
                            : (isDark ? const Color(0xFF38250C) : const Color(0xFFFEF3C7));
                        accentC = isOccupied ? const Color(0xFFDC2626) : const Color(0xFFD97706);
                        statusText = isOccupied ? 'ACTIVE' : 'SELECTED';
                        subtitle = isOccupied
                            ? (table.currentBillAmount > 0 ? '₹${table.currentBillAmount.toStringAsFixed(0)}' : 'Seated')
                            : 'Selected';
                      } else if (isOccupied) {
                        // High-contrast RED theme for Seated / Occupied tables
                        borderC = const Color(0xFFEF4444);
                        bgC = isDark ? const Color(0xFF2E1313) : const Color(0xFFFFF1F2);
                        accentC = const Color(0xFFDC2626);
                        statusText = 'SEATED';
                        subtitle = table.currentBillAmount > 0
                            ? '₹${table.currentBillAmount.toStringAsFixed(0)}'
                            : (table.occupiedDuration ?? 'Seated');
                      } else {
                        // Clean EMERALD theme for Free tables
                        borderC = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                        bgC = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
                        accentC = const Color(0xFF10B981);
                        statusText = 'FREE';
                        subtitle = 'Available';
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => widget.onSelectTable(table),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 118,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: bgC,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderC,
                                width: isSelected ? 2.2 : (isOccupied ? 1.6 : 1.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? accentC.withValues(alpha: 0.3)
                                      : (isOccupied
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                          : (isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03))),
                                  blurRadius: isSelected ? 10 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top row: Table Name & Seater Capacity
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      table.label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                        color: isOccupied
                                            ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
                                            : (isSelected
                                                ? const Color(0xFFD97706)
                                                : (isDark ? Colors.white : const Color(0xFF0F172A))),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.people_alt_rounded,
                                            size: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${table.capacity}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Bottom row: Status Chip + Subtitle (Amount or Timer)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: accentC.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5.5,
                                            height: 5.5,
                                            decoration: BoxDecoration(
                                              color: accentC,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                              color: accentC,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isOccupied ? FontWeight.w800 : FontWeight.w600,
                                          color: isOccupied
                                              ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required Color dotColor,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _statusFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
