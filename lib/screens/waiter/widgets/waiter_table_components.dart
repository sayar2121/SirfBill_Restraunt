import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';

/// 1. Reusable animated filter pill with colored dot indicator.
class WaiterTableFilterChip extends StatelessWidget {
  final String label;
  final String filterKey;
  final Color dotColor;
  final bool isSelected;
  final ValueChanged<String> onSelect;

  const WaiterTableFilterChip({
    super.key,
    required this.label,
    required this.filterKey,
    required this.dotColor,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelect(filterKey),
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

/// 2. Header component for Waiter Table Strip (Title, Filter Pills, Floor Selector, Refresh).
class WaiterTableStripHeader extends StatelessWidget {
  final String effectiveFloor;
  final List<String> floorList;
  final ValueChanged<String> onSelectFloor;
  final VoidCallback onRefresh;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final int totalCount;
  final int freeCount;
  final int seatedCount;

  const WaiterTableStripHeader({
    super.key,
    required this.effectiveFloor,
    required this.floorList,
    required this.onSelectFloor,
    required this.onRefresh,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.totalCount,
    required this.freeCount,
    required this.seatedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return LayoutBuilder(
      builder: (context, headerConstraints) {
        final isNarrow = headerConstraints.maxWidth < 680;

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
              WaiterTableFilterChip(
                label: 'All ($totalCount)',
                filterKey: 'all',
                dotColor: const Color(0xFF3B82F6),
                isSelected: statusFilter == 'all',
                onSelect: onStatusFilterChanged,
              ),
              const SizedBox(width: 2),
              WaiterTableFilterChip(
                label: 'Free ($freeCount)',
                filterKey: 'free',
                dotColor: const Color(0xFF10B981),
                isSelected: statusFilter == 'free',
                onSelect: onStatusFilterChanged,
              ),
              const SizedBox(width: 2),
              WaiterTableFilterChip(
                label: 'Seated ($seatedCount)',
                filterKey: 'seated',
                dotColor: const Color(0xFFEF4444),
                isSelected: statusFilter == 'seated',
                onSelect: onStatusFilterChanged,
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
                    if (val != null) onSelectFloor(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Refresh Tables',
              child: InkWell(
                onTap: onRefresh,
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
            const SizedBox(width: 10),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filterPills,
              ),
            ),
            const SizedBox(width: 8),
            floorAndRefresh,
          ],
        );
      },
    );
  }
}

/// 3. Individual Table Card in the horizontal strip.
class WaiterTableCardItem extends StatelessWidget {
  final DiningTable table;
  final bool isSelected;
  final bool hasReadyOrder;
  final ValueChanged<DiningTable> onSelect;

  const WaiterTableCardItem({
    super.key,
    required this.table,
    required this.isSelected,
    required this.hasReadyOrder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOccupied = table.status == TableStatus.occupied;

    // Visual theme per state
    Color borderC;
    Color bgC;
    Color accentC;
    String statusText;
    String subtitle;

    if (isSelected) {
      borderC = hasReadyOrder
          ? const Color(0xFF10B981)
          : (isOccupied ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
      bgC = hasReadyOrder
          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
          : (isOccupied
              ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E8))
              : (isDark ? const Color(0xFF38250C) : const Color(0xFFFEF3C7)));
      accentC = hasReadyOrder
          ? const Color(0xFF059669)
          : (isOccupied ? const Color(0xFFDC2626) : const Color(0xFFD97706));
      statusText = hasReadyOrder ? 'READY' : (isOccupied ? 'ACTIVE' : 'SELECTED');
      subtitle = hasReadyOrder
          ? 'Serve Now'
          : (isOccupied
              ? (table.currentBillAmount > 0 ? '₹${table.currentBillAmount.toStringAsFixed(0)}' : 'Seated')
              : 'Selected');
    } else if (hasReadyOrder) {
      borderC = const Color(0xFF10B981);
      bgC = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5);
      accentC = const Color(0xFF059669);
      statusText = 'READY';
      subtitle = 'Serve Now';
    } else if (isOccupied) {
      borderC = const Color(0xFFEF4444);
      bgC = isDark ? const Color(0xFF2E1313) : const Color(0xFFFFF1F2);
      accentC = const Color(0xFFDC2626);
      statusText = 'SEATED';
      subtitle = table.currentBillAmount > 0
          ? '₹${table.currentBillAmount.toStringAsFixed(0)}'
          : (table.occupiedDuration ?? 'Seated');
    } else {
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
        onTap: () => onSelect(table),
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
  }
}

