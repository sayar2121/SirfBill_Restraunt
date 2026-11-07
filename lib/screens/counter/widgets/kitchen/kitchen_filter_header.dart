import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

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
  final VoidCallback onToggleSound;
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Brand title, Status Indicator, Search & Controls
          Row(
            children: [
              // Icon Badge with live pulse
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
                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Kitchen Display System',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'LIVE KDS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time order prep queue • Auto-synced with POS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Search Bar with 300ms debounce
              SizedBox(
                width: 240,
                height: 42,
                child: TextField(
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 19, color: Color(0xFF94A3B8)),
                    hintText: 'Search KOT / table / dish...',
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
                      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Audio Alert Toggle
              Tooltip(
                message: widget.isSoundEnabled ? 'Sound Alerts: ON' : 'Sound Alerts: OFF',
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    onPressed: widget.onToggleSound,
                    icon: Icon(
                      widget.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      size: 20,
                      color: widget.isSoundEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Manual Sync / Refresh Button
              Tooltip(
                message: 'Sync latest tickets now',
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFF97316)),
                  ),
                ),
              ),
              if (widget.isStandalone && widget.onExitStandalone != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Exit Kitchen Mode / Logout',
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: TextButton.icon(
                      onPressed: widget.onExitStandalone,
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text('Exit KDS', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Status Cards Carousel (Matches POS Category Selector: 72px Height)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKdsCategoryCard(
                  label: 'All Tickets',
                  count: widget.totalCount,
                  icon: '📋',
                  isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == null,
                  color: const Color(0xFF64748B),
                  onTap: widget.onSelectAll,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'Active Queue',
                  count: widget.activeCount,
                  icon: '⚡',
                  isSelected: widget.onlyActive,
                  color: const Color(0xFFF97316),
                  onTap: widget.onSelectActive,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'New Orders',
                  count: widget.newCount,
                  icon: '🔔',
                  isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.newOrder,
                  color: const Color(0xFFEF4444),
                  onTap: () => widget.onSelectStatus(KotStatus.newOrder),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'In Prep',
                  count: widget.preparingCount,
                  icon: '🍳',
                  isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.preparing,
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onSelectStatus(KotStatus.preparing),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'Ready / Done',
                  count: widget.readyCount,
                  icon: '🍽️',
                  isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.ready,
                  color: const Color(0xFF10B981),
                  onTap: () => widget.onSelectStatus(KotStatus.ready),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'Delayed (>15m)',
                  count: widget.delayedCount,
                  icon: '⏰',
                  isSelected: widget.onlyDelayed,
                  color: const Color(0xFFDC2626),
                  onTap: widget.onSelectDelayed,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildKdsCategoryCard(
                  label: 'Served / Out',
                  count: widget.servedCount,
                  icon: '✅',
                  isSelected: !widget.onlyActive && !widget.onlyDelayed && widget.statusFilter == KotStatus.served,
                  color: const Color(0xFF6366F1),
                  onTap: () => widget.onSelectStatus(KotStatus.served),
                  isDark: isDark,
                  borderColor: borderColor,
                ),

                const SizedBox(width: 14),
                Container(height: 38, width: 1.2, color: borderColor),
                const SizedBox(width: 14),

                // Order Type Selector Pills (Segmented)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildTypePill('All Modes', null, widget.typeFilter == null, isDark),
                      const SizedBox(width: 4),
                      _buildTypePill('Dine-In', OrderType.dineIn, widget.typeFilter == OrderType.dineIn, isDark),
                      const SizedBox(width: 4),
                      _buildTypePill('Takeaway', OrderType.takeaway, widget.typeFilter == OrderType.takeaway, isDark),
                      const SizedBox(width: 4),
                      _buildTypePill('Delivery', OrderType.delivery, widget.typeFilter == OrderType.delivery, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKdsCategoryCard({
    required String label,
    required int count,
    required String icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 110,
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePill(String label, OrderType? type, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => widget.onSelectType(type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF97316)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
