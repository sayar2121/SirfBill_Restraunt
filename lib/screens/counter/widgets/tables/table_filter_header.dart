import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

class TableFilterHeader extends StatelessWidget {
  final List<String>? floors;
  final int totalCount;
  final int availableCount;
  final int occupiedCount;
  final int reservedCount;
  final String selectedFloor;
  final TableStatus? statusFilter;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<TableStatus?> onSelectStatus;
  final ValueChanged<String> onSearch;
  final VoidCallback onAddTable;
  final VoidCallback? onRefresh;

  const TableFilterHeader({
    super.key,
    this.floors,
    required this.totalCount,
    required this.availableCount,
    required this.occupiedCount,
    required this.reservedCount,
    required this.selectedFloor,
    required this.statusFilter,
    required this.onSelectFloor,
    required this.onSelectStatus,
    required this.onSearch,
    required this.onAddTable,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Search, and "+ Add Table" Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;
              final searchWidget = SizedBox(
                width: isCompact ? 140 : 200,
                height: 36,
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                    hintText: 'Search...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              );

              final refreshButton = IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh Tables & Floors',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF10B981)),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );

              final addButton = ElevatedButton.icon(
                onPressed: onAddTable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isCompact ? 'Add' : 'Add Table',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );

              return Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : context.go('/counter/billing'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF10B981)),
                    label: Text(
                      isCompact ? 'POS' : 'Back to POS',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.table_restaurant_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Table & Floor Management',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  searchWidget,
                  if (onRefresh != null) ...[
                    const SizedBox(width: 8),
                    refreshButton,
                  ],
                  const SizedBox(width: 8),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Bottom Filter Row: Floor pills & Status Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Floor Segmented Container (Matches Orders & Kitchen headers)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ((floors != null && floors!.isNotEmpty)
                            ? floors!
                            : ['All Floors'])
                        .map((floor) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: CommonFilterTypePill(
                                label: floor,
                                icon: Icons.apartment_rounded,
                                isSelected: selectedFloor == floor,
                                onTap: () => onSelectFloor(floor),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 14),

                // Separator
                Container(height: 24, width: 1.2, color: borderColor),
                const SizedBox(width: 14),

                // Status Counts
                CommonStatusFilterPill(
                  label: 'All',
                  count: totalCount,
                  isSelected: statusFilter == null,
                  color: const Color(0xFF64748B),
                  onTap: () => onSelectStatus(null),
                ),
                const SizedBox(width: 8),
                CommonStatusFilterPill(
                  label: 'Available',
                  count: availableCount,
                  isSelected: statusFilter == TableStatus.available,
                  color: const Color(0xFF10B981),
                  onTap: () => onSelectStatus(TableStatus.available),
                ),
                const SizedBox(width: 8),
                CommonStatusFilterPill(
                  label: 'Occupied',
                  count: occupiedCount,
                  isSelected: statusFilter == TableStatus.occupied,
                  color: const Color(0xFFEF4444),
                  onTap: () => onSelectStatus(TableStatus.occupied),
                ),
                const SizedBox(width: 8),
                CommonStatusFilterPill(
                  label: 'Reserved',
                  count: reservedCount,
                  isSelected: statusFilter == TableStatus.reserved,
                  color: const Color(0xFFF59E0B),
                  onTap: () => onSelectStatus(TableStatus.reserved),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
