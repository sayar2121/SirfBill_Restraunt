import 'common_date_picker_modal.dart';
import 'package:flutter/material.dart';

/// Reusable Segmented Pill for Primary Filters (e.g. Order Types, Floors, Categories)
class CommonFilterTypePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const CommonFilterTypePill({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Standard Status Filter Pill (e.g. All, In Stock, Out of Stock, Available, Active, Completed)
class CommonStatusFilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const CommonStatusFilterPill({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
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

/// Date Range Presets: Today, This Week, This Month, This Year, Custom Range
enum DateRangePreset {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

/// Reusable Date Range Filter Segment with DatePicker modal for custom range
class CommonDateFilterBar extends StatelessWidget {
  final DateRangePreset selectedPreset;
  final DateTimeRange? customRange;
  final ValueChanged<DateRangePreset> onSelectPreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;

  const CommonDateFilterBar({
    super.key,
    required this.selectedPreset,
    this.customRange,
    required this.onSelectPreset,
    required this.onSelectCustomRange,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final containerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    String customLabel = 'Custom Range';
    if (customRange != null) {
      customLabel = '${_formatDate(customRange!.start)} - ${_formatDate(customRange!.end)}';
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPresetPill(
            context: context,
            preset: DateRangePreset.all,
            label: 'All Time',
            icon: Icons.history_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildPresetPill(
            context: context,
            preset: DateRangePreset.today,
            label: 'Today',
            icon: Icons.today_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildPresetPill(
            context: context,
            preset: DateRangePreset.thisWeek,
            label: 'This Week',
            icon: Icons.view_week_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildPresetPill(
            context: context,
            preset: DateRangePreset.thisMonth,
            label: 'This Month',
            icon: Icons.calendar_month_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildPresetPill(
            context: context,
            preset: DateRangePreset.thisYear,
            label: 'This Year',
            icon: Icons.event_note_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildCustomRangePill(
            context: context,
            label: customLabel,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill({
    required BuildContext context,
    required DateRangePreset preset,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = selectedPreset == preset;
    const activeColor = Color(0xFF10B981);

    return InkWell(
      onTap: () => onSelectPreset(preset),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRangePill({
    required BuildContext context,
    required String label,
    required bool isDark,
  }) {
    final isSelected = selectedPreset == DateRangePreset.custom;
    const activeColor = Color(0xFF10B981);

    return InkWell(
      onTap: () {
        final now = DateTime.now();
        final initial = customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
        CommonDatePickerModal.show(
          context: context,
          initialRange: initial,
          onApply: onSelectCustomRange,
          onSelectPreset: onSelectPreset,
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

}
