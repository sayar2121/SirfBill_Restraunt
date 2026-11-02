import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

class KitchenFilterHeader extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int newCount;
  final int preparingCount;
  final int readyCount;
  final int servedCount;
  final KotStatus? statusFilter;
  final OrderType? typeFilter;
  final bool onlyActive;
  final ValueChanged<KotStatus?> onSelectStatus;
  final VoidCallback onSelectActive;
  final VoidCallback onSelectAll;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  const KitchenFilterHeader({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.newCount,
    required this.preparingCount,
    required this.readyCount,
    required this.servedCount,
    required this.statusFilter,
    required this.typeFilter,
    required this.onlyActive,
    required this.onSelectStatus,
    required this.onSelectActive,
    required this.onSelectAll,
    required this.onSelectType,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title Badge, Search Bar, and Refresh
          Row(
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kitchen Display System',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Kitchen Stream • Auto-updating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Search Input Box
              SizedBox(
                width: 260,
                height: 44,
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    hintText: 'Search KOT / table / item...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Refresh Button
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  onPressed: onRefresh,
                  tooltip: 'Sync Kitchen Tickets',
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    foregroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Filter Row: Order Type Toggle + High Contrast Status Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Order Types Segmented Container
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CommonFilterTypePill(label: 'All Types', isSelected: typeFilter == null, onTap: () => onSelectType(null)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Dine-In', isSelected: typeFilter == OrderType.dineIn, onTap: () => onSelectType(OrderType.dineIn)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Takeaway', isSelected: typeFilter == OrderType.takeaway, onTap: () => onSelectType(OrderType.takeaway)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Delivery', isSelected: typeFilter == OrderType.delivery, onTap: () => onSelectType(OrderType.delivery)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Separator
                Container(height: 24, width: 1.2, color: borderColor),
                const SizedBox(width: 14),

                // Standardized KOT Status Pills
                CommonStatusFilterPill(label: 'All', count: totalCount, isSelected: !onlyActive && statusFilter == null, color: const Color(0xFF64748B), onTap: onSelectAll),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: '🔥 Active', count: activeCount, isSelected: onlyActive, color: const Color(0xFFEA580C), onTap: onSelectActive),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: '🔴 New', count: newCount, isSelected: !onlyActive && statusFilter == KotStatus.newOrder, color: const Color(0xFFEF4444), onTap: () => onSelectStatus(KotStatus.newOrder)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: '🟡 In Prep', count: preparingCount, isSelected: !onlyActive && statusFilter == KotStatus.preparing, color: const Color(0xFFF59E0B), onTap: () => onSelectStatus(KotStatus.preparing)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: '🟢 Ready', count: readyCount, isSelected: !onlyActive && statusFilter == KotStatus.ready, color: const Color(0xFF10B981), onTap: () => onSelectStatus(KotStatus.ready)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: '✅ Served', count: servedCount, isSelected: !onlyActive && statusFilter == KotStatus.served, color: const Color(0xFF6366F1), onTap: () => onSelectStatus(KotStatus.served)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
