import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';
import 'kitchen_badges.dart';
import 'kitchen_header_actions.dart';
import 'kitchen_status_filter_bar.dart';

/// Top control and filter header for the Kitchen Display System (KDS).
/// Responsive across mobile, tablet, and desktop viewports.
class KitchenFilterHeader extends StatelessWidget {
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
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final bool isSoundEnabled;
  final VoidCallback? onToggleSound;
  final bool isStandalone;
  final VoidCallback? onExitStandalone;

  const KitchenFilterHeader({
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
    required this.onSearch,
    required this.onRefresh,
    this.onExport,
    this.isSoundEnabled = true,
    required this.onToggleSound,
    this.isStandalone = false,
    this.onExitStandalone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 600;
            final isTablet = width >= 600 && width < 1050;
            final isCompact = width < 1050;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Row 1: Header Brand, Search & Actions
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : (isTablet ? 16 : 24),
                  vertical: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1)),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KdsBrandHeader(
                                  isStandalone: isStandalone,
                                  isMobile: isMobile,
                                  isTablet: isTablet,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              KdsHeaderActions(
                                isCompact: true,
                                isMobile: isMobile,
                                isDark: isDark,
                                borderColor: borderColor,
                                isSoundEnabled: isSoundEnabled,
                                onToggleSound: onToggleSound,
                                onRefresh: onRefresh,
                                onExport: onExport,
                                isStandalone: isStandalone,
                                onExitStandalone: onExitStandalone,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          KdsSearchInput(
                            onSearch: onSearch,
                            isDark: isDark,
                            borderColor: borderColor,
                            height: isMobile ? 36 : 38,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _KdsBrandHeader(
                              isStandalone: isStandalone,
                              isMobile: false,
                              isTablet: false,
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: KdsSearchInput(
                                onSearch: onSearch,
                                isDark: isDark,
                                borderColor: borderColor,
                                height: 38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          KdsHeaderActions(
                            isCompact: width < 1250,
                            isMobile: false,
                            isDark: isDark,
                            borderColor: borderColor,
                            isSoundEnabled: isSoundEnabled,
                            onToggleSound: onToggleSound,
                            onRefresh: onRefresh,
                            onExport: onExport,
                            isStandalone: isStandalone,
                            onExitStandalone: onExitStandalone,
                          ),
                        ],
                      ),
              ),

              // Row 2: Status Badges Bar & Dine-In/Takeaway Mode Selector
              KitchenStatusFilterBar(
                totalCount: totalCount,
                activeCount: activeCount,
                newCount: newCount,
                preparingCount: preparingCount,
                readyCount: readyCount,
                delayedCount: delayedCount,
                servedCount: servedCount,
                statusFilter: statusFilter,
                typeFilter: typeFilter,
                datePreset: datePreset,
                customRange: customRange,
                onlyActive: onlyActive,
                onlyDelayed: onlyDelayed,
                onSelectStatus: onSelectStatus,
                onSelectActive: onSelectActive,
                onSelectDelayed: onSelectDelayed,
                onSelectAll: onSelectAll,
                onSelectType: onSelectType,
                onSelectDatePreset: onSelectDatePreset,
                onSelectCustomRange: onSelectCustomRange,
                isDark: isDark,
                isMobile: isMobile,
                isTablet: isTablet,
                borderColor: borderColor,
              ),
            ],
          );
        },
      ),
    ),
  );
}
}

/// Brand logo, title, and live pulse badge header
class _KdsBrandHeader extends StatelessWidget {
  final bool isStandalone;
  final bool isMobile;
  final bool isTablet;
  final bool isDark;
  final Color borderColor;

  const _KdsBrandHeader({
    required this.isStandalone,
    required this.isMobile,
    required this.isTablet,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStandalone) ...[
          Image.asset(
            isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
            height: isMobile ? 26 : (isTablet ? 32 : 38),
            fit: BoxFit.contain,
          ),
          SizedBox(width: isMobile ? 8 : (isTablet ? 10 : 14)),
          if (!isMobile && !isTablet) ...[
            Container(height: 28, width: 1.5, color: borderColor),
            const SizedBox(width: 14),
          ],
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      isMobile ? 'Kitchen Display' : 'Kitchen Display System',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : (isTablet ? 15.5 : 16),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const LivePulseBadge(label: 'LIVE KDS'),
                ],
              ),
              if (!isMobile) ...[
                const SizedBox(height: 2),
                Text(
                  'Real-time automated order queue • POS live-synced',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
