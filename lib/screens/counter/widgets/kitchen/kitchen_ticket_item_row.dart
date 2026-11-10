import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

/// Reusable individual food item row for Kitchen Ticket Card
class KitchenTicketItemRow extends StatelessWidget {
  final KotItem item;
  final VoidCallback? onToggle;
  final bool isReadOnly;

  const KitchenTicketItemRow({
    super.key,
    required this.item,
    this.onToggle,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      onTap: isReadOnly ? null : onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.isPrepared ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: item.isPrepared
                  ? const Color(0xFF10B981)
                  : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: item.isPrepared
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isPrepared
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Text(
                '${item.quantity}x',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: item.isPrepared
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: item.isPrepared
                                ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                : textColor,
                            decoration: item.isPrepared ? TextDecoration.lineThrough : null,
                            decorationColor: const Color(0xFF94A3B8),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                      if (item.isPrepared) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'SERVED / DONE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ] else if (item.isRunningItem) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'NEW ADDED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '👉 ${item.notes!}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

