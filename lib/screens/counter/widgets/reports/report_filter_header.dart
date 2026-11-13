import 'package:flutter/material.dart';
import '../../../../widgets/common_filter_pills.dart';

class ReportFilterHeader extends StatelessWidget {
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final int activeTab;
  final ValueChanged<DateRangePreset> onSelectDatePreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onExportPdf;
  final VoidCallback onRefresh;
  final bool isLoading;

  const ReportFilterHeader({
    super.key,
    required this.datePreset,
    this.customRange,
    required this.activeTab,
    required this.onSelectDatePreset,
    required this.onSelectCustomRange,
    required this.onSelectTab,
    required this.onExportPdf,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Title, Universal Unified Date Range Filter & Export Action
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopWide = constraints.maxWidth >= 1150;

              if (isDesktopWide) {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports & Executive Analytics',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Real-time revenue, order channels, menu performance and audit trail',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Refresh Button
                    IconButton(
                      onPressed: isLoading ? null : onRefresh,
                      tooltip: 'Refresh analytics',
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),

                    // Universal Date Filter Widget
                    CommonDateFilterBar(
                      selectedPreset: datePreset,
                      customRange: customRange,
                      onSelectPreset: onSelectDatePreset,
                      onSelectCustomRange: onSelectCustomRange,
                    ),
                    const SizedBox(width: 10),

                    // Export CTA Button (Excel / PDF)
                    ElevatedButton.icon(
                      onPressed: onExportPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text(
                        'Export Data',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }

              // On Tablet / Mobile: Responsive multi-row layout to prevent 441px overflow
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports & Executive Analytics',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Real-time revenue, order channels, menu performance and audit trail',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Refresh Button
                      IconButton(
                        onPressed: isLoading ? null : onRefresh,
                        tooltip: 'Refresh analytics',
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),

                      // Export CTA Button
                      ElevatedButton.icon(
                        onPressed: onExportPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.file_download_outlined, size: 15),
                        label: const Text(
                          'Export',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontally scrollable date range selector on tablet/compact
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CommonDateFilterBar(
                      selectedPreset: datePreset,
                      customRange: customRange,
                      onSelectPreset: onSelectDatePreset,
                      onSelectCustomRange: onSelectCustomRange,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Clean Segmented Tabs (Overview, Item-wise Sales, Audit Trail)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentTab(0, 'Overview & Financials', Icons.dashboard_rounded, activeTab == 0, isDark),
                  const SizedBox(width: 4),
                  _buildSegmentTab(1, 'Item-wise Sales', Icons.leaderboard_rounded, activeTab == 1, isDark),
                  const SizedBox(width: 4),
                  _buildSegmentTab(2, 'Audit Trail', Icons.security_rounded, activeTab == 2, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label, IconData icon, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => onSelectTab(index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
