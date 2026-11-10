import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class TableCard extends StatelessWidget {
  final DiningTable table;
  final VoidCallback onTap;
  final VoidCallback onOpenPos;
  final VoidCallback onStatusToggle;
  final VoidCallback? onEdit;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onOpenPos,
    required this.onStatusToggle,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOccupied = table.status == TableStatus.occupied;
    final isReserved = table.status == TableStatus.reserved;

    Color statusColor;
    String statusText;
    Color statusBg;
    IconData statusIcon;

    switch (table.status) {
      case TableStatus.available:
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusText = 'Available';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case TableStatus.occupied:
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        statusText = 'Occupied';
        statusIcon = Icons.restaurant_rounded;
        break;
      case TableStatus.reserved:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        statusText = 'Reserved';
        statusIcon = Icons.bookmark_border_rounded;
        break;
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isOccupied
        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
        : (isReserved
            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: isOccupied ? 1.8 : 1.2),
            boxShadow: [
              BoxShadow(
                color: isOccupied
                    ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                    : (isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.06)),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Bar: Table Icon + Name + Status Pill + Edit
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOccupied
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : (isReserved
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : [const Color(0xFF10B981), const Color(0xFF059669)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        table.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${table.label}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.layers_rounded, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Text(
                              table.floor.isNotEmpty ? table.floor : 'Main Floor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      tooltip: 'Table Settings',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // 2. Middle Section: Visual Seating Capacity & Order Live Metrics
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Capacity pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CAPACITY',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '${table.capacity} Seats',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Occupancy / Status Metric
                    if (isOccupied) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFEF4444)),
                              const SizedBox(width: 3),
                              Builder(
                                builder: (_) {
                                  String duration = table.occupiedDuration ?? '00:00:00';
                                  if (table.occupiedSince != null) {
                                    final diff = DateTime.now().difference(table.occupiedSince!);
                                    final h = diff.inHours.toString().padLeft(2, '0');
                                    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
                                    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
                                    duration = '$h:$m:$s';
                                  } else if (duration.split(':').length == 2) {
                                    duration = '$duration:00';
                                  }
                                  return Text(
                                    duration,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '₹${table.currentBillAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        isReserved ? 'Reserved Guest' : 'Ready to Seat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isReserved ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Action Buttons: "Free/Occupied" toggle & "Take Order / Open POS"
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onStatusToggle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        icon: Icon(
                          isOccupied ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          size: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        label: Text(
                          isOccupied ? 'Release' : 'Occupy',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: onOpenPos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                        label: const Text(
                          'POS Bill',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
