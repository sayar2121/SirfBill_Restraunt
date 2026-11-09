import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

class OrderFilterHeader extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int completedCount;
  final int holdCount;
  final OrderStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<OrderStatus?> onSelectStatus;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<DateRangePreset> onSelectDatePreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final ValueChanged<String> onSearch;
  final VoidCallback onNewOrder;
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;
  final bool isLoading;

  const OrderFilterHeader({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.holdCount,
    required this.statusFilter,
    required this.typeFilter,
    required this.datePreset,
    this.customRange,
    required this.onSelectStatus,
    required this.onSelectType,
    required this.onSelectDatePreset,
    required this.onSelectCustomRange,
    required this.onSearch,
    required this.onNewOrder,
    this.onRefresh,
    this.onExport,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title Badge, Search, Refresh, and "+ New Order" Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live Orders & History',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Track real-time kitchen status, print bills & manage guest orders',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: isCompact ? 170 : 250,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: onSearch,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search order #, table...',
                                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Refresh Orders',
                      child: InkWell(
                        onTap: isLoading ? null : onRefresh,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF10B981)),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (onExport != null) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Export Orders (Excel / PDF)',
                      child: InkWell(
                        onTap: onExport,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_outlined, size: 20, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text(
                                'Export Data',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onNewOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        isCompact ? 'POS' : 'New Order',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Bottom Filter Row: Order Type Pills + Status Filter Pills
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
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommonFilterTypePill(label: 'All Types', icon: Icons.tune_rounded, isSelected: typeFilter == null, onTap: () => onSelectType(null)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Dine-In', icon: Icons.table_restaurant_rounded, isSelected: typeFilter == OrderType.dineIn, onTap: () => onSelectType(OrderType.dineIn)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Takeaway', icon: Icons.shopping_bag_rounded, isSelected: typeFilter == OrderType.takeaway, onTap: () => onSelectType(OrderType.takeaway)),
                      const SizedBox(width: 4),
                      CommonFilterTypePill(label: 'Delivery', icon: Icons.moped_rounded, isSelected: typeFilter == OrderType.delivery, onTap: () => onSelectType(OrderType.delivery)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Separator
                Container(height: 24, width: 1.2, color: borderColor),
                const SizedBox(width: 14),

                // Order Status Filters (Matching All Screens)
                CommonStatusFilterPill(label: 'All', count: totalCount, isSelected: statusFilter == null, color: const Color(0xFF64748B), onTap: () => onSelectStatus(null)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: 'Active / In Prep', count: activeCount, isSelected: statusFilter == OrderStatus.active, color: const Color(0xFF3B82F6), onTap: () => onSelectStatus(OrderStatus.active)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: 'Held', count: holdCount, isSelected: statusFilter == OrderStatus.hold, color: const Color(0xFFF59E0B), onTap: () => onSelectStatus(OrderStatus.hold)),
                const SizedBox(width: 8),
                CommonStatusFilterPill(label: 'Completed', count: completedCount, isSelected: statusFilter == OrderStatus.completed, color: const Color(0xFF10B981), onTap: () => onSelectStatus(OrderStatus.completed)),

                const SizedBox(width: 14),
                // Separator before Date Range
                Container(height: 24, width: 1.2, color: borderColor),
                const SizedBox(width: 14),

                // Date Range Filter (Today, This Week, This Month, This Year, Custom Range)
                CommonDateFilterBar(
                  selectedPreset: datePreset,
                  customRange: customRange,
                  onSelectPreset: onSelectDatePreset,
                  onSelectCustomRange: onSelectCustomRange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
