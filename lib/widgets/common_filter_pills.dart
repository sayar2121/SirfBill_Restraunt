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
      onTap: () async {
        final now = DateTime.now();
        DateTime fromDate = customRange?.start ?? now.subtract(const Duration(days: 7));
        DateTime toDate = customRange?.end ?? now;

        await showDialog<DateTimeRange>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                final modalDark = Theme.of(ctx).brightness == Brightness.dark;
                final bg = modalDark ? const Color(0xFF1E293B) : Colors.white;
                final cardInner = modalDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
                final border = modalDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                final textPrimary = modalDark ? Colors.white : const Color(0xFF0F172A);
                final textMuted = modalDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

                String fmtShort(DateTime d) {
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return '${d.day} ${months[d.month - 1]} ${d.year}';
                }

                final daysDifference = toDate.difference(fromDate).inDays + 1;

                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Container(
                    width: 440,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: modalDark ? 0.45 : 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Gradient Accent Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: modalDark
                                  ? [const Color(0xFF065F46), const Color(0xFF047857)]
                                  : [const Color(0xFF059669), const Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Filter Orders by Date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Select period to analyze billing & sales',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                        // Body Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Presets Carousel
                              Text(
                                'QUICK PRESETS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickChip('Today', () {
                                    setModalState(() {
                                      fromDate = DateTime(now.year, now.month, now.day);
                                      toDate = now;
                                    });
                                  }, modalDark),
                                  _buildQuickChip('Yesterday', () {
                                    final y = now.subtract(const Duration(days: 1));
                                    setModalState(() {
                                      fromDate = DateTime(y.year, y.month, y.day);
                                      toDate = DateTime(y.year, y.month, y.day, 23, 59, 59);
                                    });
                                  }, modalDark),
                                  _buildQuickChip('Last 7 Days', () {
                                    setModalState(() {
                                      fromDate = now.subtract(const Duration(days: 7));
                                      toDate = now;
                                    });
                                  }, modalDark),
                                  _buildQuickChip('Last 30 Days', () {
                                    setModalState(() {
                                      fromDate = now.subtract(const Duration(days: 30));
                                      toDate = now;
                                    });
                                  }, modalDark),
                                  _buildQuickChip('This Month', () {
                                    setModalState(() {
                                      fromDate = DateTime(now.year, now.month, 1);
                                      toDate = now;
                                    });
                                  }, modalDark),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Interactive Date Cards with Arrow Connector
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardInner,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    // From Date Box
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: ctx,
                                            initialDate: fromDate,
                                            firstDate: DateTime(2020),
                                            lastDate: toDate,
                                            builder: (context, child) => Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                                  primary: const Color(0xFF10B981),
                                                ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setModalState(() => fromDate = picked);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: bg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF10B981)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'START DATE',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                      color: textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                fmtShort(fromDate),
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Arrow Connector & Duration Tag
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF10B981)),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$daysDifference d',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // To Date Box
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: ctx,
                                            initialDate: toDate,
                                            firstDate: fromDate,
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                            builder: (context, child) => Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                                  primary: const Color(0xFF10B981),
                                                ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setModalState(() => toDate = picked);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: bg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.event_available_rounded, size: 13, color: Color(0xFF3B82F6)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'END DATE',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                      color: textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                fmtShort(toDate),
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Bottom Footer Actions
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: TextButton.styleFrom(
                                      foregroundColor: textMuted,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final newRange = DateTimeRange(start: fromDate, end: toDate);
                                      onSelectCustomRange(newRange);
                                      onSelectPreset(DateRangePreset.custom);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                    icon: const Icon(Icons.filter_alt_rounded, size: 16),
                                    label: const Text(
                                      'Apply Date Range',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
