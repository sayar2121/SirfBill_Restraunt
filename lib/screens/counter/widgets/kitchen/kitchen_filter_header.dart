import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'kitchen_badges.dart';

class KitchenFilterHeader extends StatefulWidget {
  final int totalCount;
  final int activeCount;
  final int newCount;
  final int preparingCount;
  final int readyCount;
  final int delayedCount;
  final int servedCount;
  final KotStatus? statusFilter;
  final OrderType? typeFilter;
  final bool onlyActive;
  final bool onlyDelayed;
  final ValueChanged<KotStatus?> onSelectStatus;
  final VoidCallback onSelectActive;
  final VoidCallback onSelectDelayed;
  final VoidCallback onSelectAll;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
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
    required this.onlyActive,
    required this.onlyDelayed,
    required this.onSelectStatus,
    required this.onSelectActive,
    required this.onSelectDelayed,
    required this.onSelectAll,
    required this.onSelectType,
    required this.onSearch,
    required this.onRefresh,
    this.isSoundEnabled = true,
    required this.onToggleSound,
    this.isStandalone = false,
    this.onExitStandalone,
  });

  @override
  State<KitchenFilterHeader> createState() => _KitchenFilterHeaderState();
}

class _KitchenFilterHeaderState extends State<KitchenFilterHeader> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(val);
    });
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Brand Logo + System info on left, Search Bar & Control Actions on right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1)),
            ),
            child: Row(
              children: [
                if (widget.isStandalone) ...[
                  Image.asset(
                    isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Container(
                    height: 28,
                    width: 1.5,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 14),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kitchen Display System',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const LivePulseBadge(label: 'LIVE KDS'),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time automated order queue • POS live-synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Search Field & Actions
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240, minWidth: 140),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Color(0xFF94A3B8)),
                        hintText: 'Search KOT / table...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.onToggleSound != null) ...[
                  Tooltip(
                    message: widget.isSoundEnabled ? 'Sound Alerts: ON' : 'Sound Alerts: OFF',
                    child: Material(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: widget.onToggleSound,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            widget.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 18,
                            color: widget.isSoundEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Tooltip(
                  message: 'Sync live tickets now',
                  child: Material(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: widget.onRefresh,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFF97316)),
                      ),
                    ),
                  ),
                ),
                if (widget.isStandalone && widget.onExitStandalone != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Exit Kitchen Mode / Logout',
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onExitStandalone,
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Exit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Row 2: Status Badges Bar & Dine-In/Takeaway Mode Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: isDark ? const Color(0xFF0B1329) : const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKdsCategoryCard(
                    label: 'All Tickets',
                    count: widget.totalCount,
                    icon: Icons.receipt_long_rounded,
                    isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == null,
                    color: const Color(0xFF475569),
                    onTap: widget.onSelectAll,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'Active Queue',
                    count: widget.activeCount,
                    icon: Icons.bolt_rounded,
                    isSelected: widget.onlyActive,
                    color: const Color(0xFFEA580C),
                    onTap: widget.onSelectActive,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'New Orders',
                    count: widget.newCount,
                    icon: Icons.notifications_active_rounded,
                    isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.newOrder,
                    color: const Color(0xFFEF4444),
                    onTap: () => widget.onSelectStatus(KotStatus.newOrder),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'In Prep',
                    count: widget.preparingCount,
                    icon: Icons.outdoor_grill_rounded,
                    isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.preparing,
                    color: const Color(0xFFD97706),
                    onTap: () => widget.onSelectStatus(KotStatus.preparing),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'Ready / Done',
                    count: widget.readyCount,
                    icon: Icons.check_circle_outline_rounded,
                    isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.ready,
                    color: const Color(0xFF059669),
                    onTap: () => widget.onSelectStatus(KotStatus.ready),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'Delayed (>15m)',
                    count: widget.delayedCount,
                    icon: Icons.alarm_rounded,
                    isSelected: widget.onlyDelayed,
                    color: const Color(0xFFDC2626),
                    onTap: widget.onSelectDelayed,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildKdsCategoryCard(
                    label: 'Served / Out',
                    count: widget.servedCount,
                    icon: Icons.done_all_rounded,
                    isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.served,
                    color: const Color(0xFF4F46E5),
                    onTap: () => widget.onSelectStatus(KotStatus.served),
                    isDark: isDark,
                  ),

                  const SizedBox(width: 14),
                  Container(height: 26, width: 1.2, color: borderColor),
                  const SizedBox(width: 14),

                  // Order Type Selector Segmented Pill Bar
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildTypePill('All Modes', null, widget.typeFilter == null, isDark),
                        const SizedBox(width: 3),
                        _buildTypePill('Dine-In', OrderType.dineIn, widget.typeFilter == OrderType.dineIn, isDark),
                        const SizedBox(width: 3),
                        _buildTypePill('Takeaway', OrderType.takeaway, widget.typeFilter == OrderType.takeaway, isDark),
                        const SizedBox(width: 3),
                        _buildTypePill('Delivery', OrderType.delivery, widget.typeFilter == OrderType.delivery, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKdsCategoryCard({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : (isDark
                    ? color.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.07)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: isDark ? 0.35 : 0.25),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
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
                size: 15,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.28)
                      : color.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
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
      ),
    );
  }

  Widget _buildTypePill(String label, OrderType? type, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => widget.onSelectType(type),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
