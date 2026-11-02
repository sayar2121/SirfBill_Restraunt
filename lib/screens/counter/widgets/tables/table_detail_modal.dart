import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class TableDetailModal extends StatelessWidget {
  final DiningTable table;
  final ValueChanged<TableStatus> onUpdateStatus;
  final VoidCallback onOpenPos;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TableDetailModal({
    super.key,
    required this.table,
    required this.onUpdateStatus,
    required this.onOpenPos,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    Color statusColor;
    String statusText;
    Color statusBg;

    switch (table.status) {
      case TableStatus.available:
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusText = 'Available';
        break;
      case TableStatus.occupied:
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        statusText = 'Occupied';
        break;
      case TableStatus.reserved:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        statusText = 'Reserved';
        break;
    }

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          minWidth: 320,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title, Current Status Badge, and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_restaurant_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Table ${table.label}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${table.floor} • Seating for ${table.capacity} Guests',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null) ...[
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit!();
                      },
                      tooltip: 'Edit Table Details',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              // Realtime Metrics Strip (if Occupied or Active)
              if (table.status == TableStatus.occupied) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(
                        icon: Icons.timer_outlined,
                        label: 'Dine-in Duration',
                        value: table.occupiedDuration ?? '00:00',
                        color: const Color(0xFFEF4444),
                      ),
                      Container(height: 28, width: 1, color: borderColor),
                      _buildMetricItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Active Orders',
                        value: '${table.activeOrderCount} items',
                        color: const Color(0xFF3B82F6),
                      ),
                      Container(height: 28, width: 1, color: borderColor),
                      _buildMetricItem(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Current Bill',
                        value: '₹ ${table.currentBillAmount.toStringAsFixed(0)}',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Table Status Selection Section
              const Text(
                'Change Table Status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),

              // Reusable Status Selector Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Available',
                      icon: Icons.check_circle_outline_rounded,
                      isActive: table.status == TableStatus.available,
                      activeColor: const Color(0xFF10B981),
                      onTap: () {
                        onUpdateStatus(TableStatus.available);
                        Navigator.pop(context);
                      },
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Occupied',
                      icon: Icons.people_alt_rounded,
                      isActive: table.status == TableStatus.occupied,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () {
                        onUpdateStatus(TableStatus.occupied);
                        Navigator.pop(context);
                      },
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Reserved',
                      icon: Icons.bookmark_added_rounded,
                      isActive: table.status == TableStatus.reserved,
                      activeColor: const Color(0xFFF59E0B),
                      onTap: () {
                        onUpdateStatus(TableStatus.reserved);
                        Navigator.pop(context);
                      },
                      borderColor: borderColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bottom Action CTAs
              Row(
                children: [
                  if (onDelete != null) ...[
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                      tooltip: 'Delete Table',
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onOpenPos();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                        label: Text(
                          table.status == TableStatus.occupied ? 'Manage POS Order' : 'Take New Order (POS)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : activeColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
