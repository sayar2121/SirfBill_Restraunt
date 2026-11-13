import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';
import '../../../../widgets/common_date_picker_modal.dart';

/// Ultra-premium, responsive Kitchen Status Command Bar.
/// Zero-scroll layout with an executive segmented stage switcher
/// and modular dropdown filter widgets for fulfillment modes and date ranges.
class KitchenStatusFilterBar extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int newCount;
  final int preparingCount;
  final int readyCount;
  final int delayedCount;
  final int servedCount;
  final KotStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final bool onlyActive;
  final bool onlyDelayed;
  final ValueChanged<KotStatus?> onSelectStatus;
  final VoidCallback onSelectActive;
  final VoidCallback onSelectDelayed;
  final VoidCallback onSelectAll;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<DateRangePreset> onSelectDatePreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final bool isDark;
  final bool isMobile;
  final bool isTablet;
  final Color borderColor;

  const KitchenStatusFilterBar({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.newCount,
    required this.preparingCount,
    required this.readyCount,
    required this.delayedCount,
    required this.servedCount,
    required this.statusFilter,
    required this.typeFilter,
    required this.datePreset,
    this.customRange,
    required this.onlyActive,
    required this.onlyDelayed,
    required this.onSelectStatus,
    required this.onSelectActive,
    required this.onSelectDelayed,
    required this.onSelectAll,
    required this.onSelectType,
    required this.onSelectDatePreset,
    required this.onSelectCustomRange,
    required this.isDark,
    required this.isMobile,
    required this.isTablet,
    required this.borderColor,
  });

  String _getOrderTypeLabel(OrderType? type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Dine-In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
      case null:
        return 'All Modes';
    }
  }

  IconData _getOrderTypeIcon(OrderType? type) {
    switch (type) {
      case OrderType.dineIn:
        return Icons.table_restaurant_rounded;
      case OrderType.takeaway:
        return Icons.shopping_bag_rounded;
      case OrderType.delivery:
        return Icons.delivery_dining_rounded;
      case null:
        return Icons.restaurant_menu_rounded;
    }
  }

  String _getDatePresetLabel(DateRangePreset preset, DateTimeRange? customRange) {
    switch (preset) {
      case DateRangePreset.all:
        return 'All Time';
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.thisYear:
        return 'This Year';
      case DateRangePreset.custom:
        if (customRange != null) {
          final s = customRange.start;
          final e = customRange.end;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final barBg = isDark ? const Color(0xFF0B1329) : const Color(0xFFF8FAFC);
    final isAllSelected = !onlyActive && !onlyDelayed && statusFilter == null;
    final isNewSelected = !onlyActive && !onlyDelayed && statusFilter == KotStatus.newOrder;
    final isPrepSelected = !onlyActive && !onlyDelayed && statusFilter == KotStatus.preparing;
    final isReadySelected = !onlyActive && !onlyDelayed && statusFilter == KotStatus.ready;
    final isServedSelected = !onlyActive && !onlyDelayed && statusFilter == KotStatus.served;

    final primarySegments = [
      KdsSegmentItem(
        label: isMobile ? 'All' : (isTablet ? 'All' : 'All Tickets'),
        count: totalCount,
        icon: Icons.receipt_long_rounded,
        isSelected: isAllSelected,
        activeColor: const Color(0xFF475569),
        onTap: onSelectAll,
      ),
      KdsSegmentItem(
        label: isMobile ? 'Active' : (isTablet ? 'Active' : 'Active Queue'),
        count: activeCount,
        icon: Icons.bolt_rounded,
        isSelected: onlyActive,
        activeColor: const Color(0xFFEA580C),
        onTap: onSelectActive,
      ),
      KdsSegmentItem(
        label: isMobile ? 'New' : (isTablet ? 'New' : 'New Orders'),
        count: newCount,
        icon: Icons.notifications_active_rounded,
        isSelected: isNewSelected,
        activeColor: const Color(0xFFEF4444),
        onTap: () => onSelectStatus(KotStatus.newOrder),
      ),
      KdsSegmentItem(
        label: isMobile ? 'Prep' : 'In Prep',
        count: preparingCount,
        icon: Icons.outdoor_grill_rounded,
        isSelected: isPrepSelected,
        activeColor: const Color(0xFFD97706),
        onTap: () => onSelectStatus(KotStatus.preparing),
      ),
      KdsSegmentItem(
        label: isMobile ? 'Ready' : (isTablet ? 'Ready' : 'Ready / Done'),
        count: readyCount,
        icon: Icons.check_circle_outline_rounded,
        isSelected: isReadySelected,
        activeColor: const Color(0xFF059669),
        onTap: () => onSelectStatus(KotStatus.ready),
      ),
      if (!isMobile)
        KdsSegmentItem(
          label: 'Served',
          count: servedCount,
          icon: Icons.done_all_rounded,
          isSelected: isServedSelected,
          activeColor: const Color(0xFF4F46E5),
          onTap: () => onSelectStatus(KotStatus.served),
        ),
    ];

    if (isMobile) {
      // Mobile: 2-Tier zero-scroll layout
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        color: barBg,
        child: Column(
          children: [
            KdsSegmentGroup(
              items: primarySegments,
              isMobile: true,
              isTablet: false,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                KdsBadgeChip(
                  label: 'Served',
                  count: servedCount,
                  isSelected: isServedSelected,
                  activeColor: const Color(0xFF4F46E5),
                  onTap: () => onSelectStatus(KotStatus.served),
                  isDark: isDark,
                  borderColor: borderColor,
                  isMobile: true,
                ),
                const SizedBox(width: 6),
                KdsBadgeChip(
                  label: 'Delayed',
                  count: delayedCount,
                  icon: delayedCount > 0 ? Icons.warning_amber_rounded : Icons.alarm_rounded,
                  isSelected: onlyDelayed,
                  activeColor: const Color(0xFFDC2626),
                  isAlert: true,
                  onTap: onSelectDelayed,
                  isDark: isDark,
                  borderColor: borderColor,
                  isMobile: true,
                ),
                const Spacer(),
                _buildOrderTypeDropdown(context, isMobile: true),
                const SizedBox(width: 6),
                _buildDateDropdown(context, isMobile: true),
              ],
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      // Tablet: 2-Tier spacious, zero-overflow layout
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: barBg,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: KdsSegmentGroup(
                    items: primarySegments,
                    isMobile: false,
                    isTablet: true,
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                KdsBadgeChip(
                  label: 'Delayed',
                  count: delayedCount,
                  icon: delayedCount > 0 ? Icons.warning_amber_rounded : Icons.alarm_rounded,
                  isSelected: onlyDelayed,
                  activeColor: const Color(0xFFDC2626),
                  isAlert: true,
                  onTap: onSelectDelayed,
                  isDark: isDark,
                  borderColor: borderColor,
                  isMobile: false,
                ),
                const Spacer(),
                _buildOrderTypeDropdown(context, isMobile: false),
                const SizedBox(width: 8),
                _buildDateDropdown(context, isMobile: false),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop: Single-ribbon unified layout
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: barBg,
      child: Row(
        children: [
          KdsSegmentGroup(
            items: primarySegments,
            isMobile: false,
            isTablet: false,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(width: 10),
          KdsBadgeChip(
            label: 'Delayed',
            count: delayedCount,
            icon: delayedCount > 0 ? Icons.warning_amber_rounded : Icons.alarm_rounded,
            isSelected: onlyDelayed,
            activeColor: const Color(0xFFDC2626),
            isAlert: true,
            onTap: onSelectDelayed,
            isDark: isDark,
            borderColor: borderColor,
            isMobile: false,
          ),
          const Spacer(),
          _buildOrderTypeDropdown(context, isMobile: false),
          const SizedBox(width: 8),
          _buildDateDropdown(context, isMobile: false),
        ],
      ),
    );
  }

  Widget _buildOrderTypeDropdown(BuildContext context, {required bool isMobile}) {
    final hasFilter = typeFilter != null;
    return KdsDropdownFilter<OrderType?>(
      label: _getOrderTypeLabel(typeFilter),
      icon: _getOrderTypeIcon(typeFilter),
      accentColor: const Color(0xFFF97316),
      isActive: hasFilter,
      isMobile: isMobile,
      isDark: isDark,
      borderColor: borderColor,
      onSelected: onSelectType,
      items: [
        _buildPopupMenuItem(value: null, label: 'All Modes', icon: Icons.restaurant_menu_rounded, isSelected: typeFilter == null),
        _buildPopupMenuItem(value: OrderType.dineIn, label: 'Dine-In', icon: Icons.table_restaurant_rounded, isSelected: typeFilter == OrderType.dineIn),
        _buildPopupMenuItem(value: OrderType.takeaway, label: 'Takeaway', icon: Icons.shopping_bag_rounded, isSelected: typeFilter == OrderType.takeaway),
        _buildPopupMenuItem(value: OrderType.delivery, label: 'Delivery', icon: Icons.delivery_dining_rounded, isSelected: typeFilter == OrderType.delivery),
      ],
    );
  }

  Widget _buildDateDropdown(BuildContext context, {required bool isMobile}) {
    final isCustom = datePreset == DateRangePreset.custom;
    final isToday = datePreset == DateRangePreset.today;
    return KdsDropdownFilter<DateRangePreset>(
      label: _getDatePresetLabel(datePreset, customRange),
      icon: Icons.calendar_today_rounded,
      accentColor: const Color(0xFF10B981),
      isActive: !isToday,
      isMobile: isMobile,
      isDark: isDark,
      borderColor: borderColor,
      onSelected: (preset) {
        if (preset == DateRangePreset.custom) {
          final now = DateTime.now();
          final initial = customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
          CommonDatePickerModal.show(
            context: context,
            initialRange: initial,
            onApply: onSelectCustomRange,
            onSelectPreset: onSelectDatePreset,
          );
        } else {
          onSelectDatePreset(preset);
        }
      },
      items: [
        _buildPopupMenuItem(value: DateRangePreset.today, label: 'Today', icon: Icons.today_rounded, isSelected: isToday),
        _buildPopupMenuItem(value: DateRangePreset.thisWeek, label: 'This Week', icon: Icons.view_week_rounded, isSelected: datePreset == DateRangePreset.thisWeek),
        _buildPopupMenuItem(value: DateRangePreset.thisMonth, label: 'This Month', icon: Icons.calendar_month_rounded, isSelected: datePreset == DateRangePreset.thisMonth),
        _buildPopupMenuItem(value: DateRangePreset.thisYear, label: 'This Year', icon: Icons.event_note_rounded, isSelected: datePreset == DateRangePreset.thisYear),
        _buildPopupMenuItem(value: DateRangePreset.all, label: 'All Time', icon: Icons.history_rounded, isSelected: datePreset == DateRangePreset.all),
        const PopupMenuDivider(),
        _buildPopupMenuItem(value: DateRangePreset.custom, label: 'Custom Range...', icon: Icons.date_range_rounded, isSelected: isCustom),
      ],
    );
  }

  PopupMenuItem<T> _buildPopupMenuItem<T>({
    required T value,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? const Color(0xFFF97316) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFFF97316) : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
              ),
            ),
          ),
          if (isSelected) const Icon(Icons.check_rounded, size: 15, color: Color(0xFFF97316)),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE SUB-WIDGETS & DATA MODELS
// ============================================================================

/// Model item for a segmented queue stage
class KdsSegmentItem {
  final String label;
  final int count;
  final IconData? icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const KdsSegmentItem({
    required this.label,
    required this.count,
    this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });
}

/// Reusable segmented tab capsule group
class KdsSegmentGroup extends StatelessWidget {
  final List<KdsSegmentItem> items;
  final bool isMobile;
  final bool isTablet;
  final bool isDark;
  final Color borderColor;

  const KdsSegmentGroup({
    super.key,
    required this.items,
    required this.isMobile,
    this.isTablet = false,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final tabs = items.map<Widget>((it) {
      final tab = _KdsSegmentTab(item: it, isDark: isDark, isMobile: isMobile, isTablet: isTablet);
      return (isMobile || isTablet) ? Expanded(child: tab) : tab;
    }).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 3 : 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isMobile ? 11 : 12),
        border: Border.all(color: borderColor),
      ),
      child: (isMobile || isTablet)
          ? Row(children: tabs)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  tabs[i],
                ],
              ],
            ),
    );
  }
}

/// Reusable individual segment button
class _KdsSegmentTab extends StatelessWidget {
  final KdsSegmentItem item;
  final bool isDark;
  final bool isMobile;
  final bool isTablet;

  const _KdsSegmentTab({
    required this.item,
    required this.isDark,
    required this.isMobile,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = item.isSelected;
    final activeColor = item.activeColor;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 3 : (isTablet ? 6 : 11),
          vertical: isMobile ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null && !isMobile && !isTablet) ...[
              Icon(
                item.icon,
                size: 13,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isMobile ? 3 : 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                item.count.toString(),
                style: TextStyle(
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable status alert/quick chip (for Served, Delayed, etc.)
class KdsBadgeChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData? icon;
  final bool isSelected;
  final Color activeColor;
  final bool isAlert;
  final VoidCallback onTap;
  final bool isDark;
  final Color borderColor;
  final bool isMobile;

  const KdsBadgeChip({
    super.key,
    required this.label,
    required this.count,
    this.icon,
    required this.isSelected,
    required this.activeColor,
    this.isAlert = false,
    required this.onTap,
    required this.isDark,
    required this.borderColor,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final alertTriggered = isAlert && count > 0;
    final color = alertTriggered ? activeColor : (isSelected ? activeColor : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)));
    final bg = isSelected
        ? activeColor
        : (alertTriggered
            ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: isMobile ? 32 : 36,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (alertTriggered ? activeColor.withValues(alpha: isDark ? 0.6 : 0.4) : borderColor),
            width: alertTriggered ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
              : (alertTriggered ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 4)] : null),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isMobile ? 12 : 14, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: isSelected || alertTriggered ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (alertTriggered ? activeColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic reusable pill dropdown button (used for Fulfillment Types and Date Presets)
class KdsDropdownFilter<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? accentColor;
  final bool isActive;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final bool isDark;
  final Color borderColor;
  final bool isMobile;

  const KdsDropdownFilter({
    super.key,
    required this.label,
    required this.icon,
    this.accentColor,
    this.isActive = false,
    required this.items,
    required this.onSelected,
    required this.isDark,
    required this.borderColor,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final bg = isActive && accentColor != null
        ? accentColor!.withValues(alpha: isDark ? 0.2 : 0.1)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));

    return PopupMenuButton<T>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 38),
      itemBuilder: (_) => items,
      child: Container(
        height: isMobile ? 32 : 36,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isActive && accentColor != null ? accentColor!.withValues(alpha: 0.5) : borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isMobile ? 12 : 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive && accentColor != null ? accentColor : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black45),
          ],
        ),
      ),
    );
  }
}
