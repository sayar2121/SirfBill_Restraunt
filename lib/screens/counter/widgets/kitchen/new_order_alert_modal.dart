import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'kitchen_badges.dart';

/// Interactive modal alert displayed on the dedicated KDS screen when a new order arrives.
/// Plays audio until acknowledged or accepted by the kitchen staff.
class NewOrderAlertModal extends StatelessWidget {
  final KitchenTicket ticket;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final String? restaurantName;

  const NewOrderAlertModal({
    super.key,
    required this.ticket,
    required this.onAccept,
    required this.onDismiss,
    this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final anyPrepared = ticket.items.any((i) => i.isPrepared);
    final isRunningOrder = anyPrepared || ticket.items.any((i) => i.isRunningItem);

    // Group items: New / To Prepare items first, followed by already Done / Served items
    final newItems = ticket.items.where((i) => !i.isPrepared).toList();
    final doneItems = ticket.items.where((i) => i.isPrepared).toList();

    final totalQty = ticket.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final newQty = newItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final doneQty = doneItems.fold<int>(0, (sum, i) => sum + i.quantity);

    final highlightColor = isRunningOrder ? const Color(0xFFF59E0B) : const Color(0xFFEA580C);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlightColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: highlightColor.withValues(alpha: 0.22),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sleek Gradient Header with Brand Logo & Pulse
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRunningOrder
                      ? (isDark
                          ? [const Color(0xFFB45309), const Color(0xFF78350F)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)])
                      : (isDark
                          ? [const Color(0xFFC2410C), const Color(0xFF9A3412)]
                          : [const Color(0xFFEA580C), const Color(0xFFC2410C)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      isRunningOrder ? Icons.update_rounded : Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isRunningOrder ? 'ORDER UPDATED • NEW ITEMS' : 'NEW ORDER INCOMING',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            LivePulseBadge(
                              label: isRunningOrder ? 'UPDATE' : 'LIVE',
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isRunningOrder
                              ? 'Running order updated with new items • $newQty to prepare'
                              : (restaurantName != null && restaurantName!.isNotEmpty
                                  ? 'Kitchen prep required • $restaurantName'
                                  : 'Requires immediate kitchen preparation'),
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      hoverColor: Colors.white12,
                      tooltip: 'Mute & Dismiss',
                    ),
                  ),
                ],
              ),
            ),

            // 2. Ticket Identification & Metadata Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.kotNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          KitchenStatusBadge(
                            status: ticket.status,
                            color: isRunningOrder ? const Color(0xFFD97706) : const Color(0xFFEF4444),
                          ),
                          if (isRunningOrder) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'UPDATED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket.orderNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  KitchenOrderTypeBadge(
                    orderType: ticket.orderType,
                    tableLabel: ticket.tableLabel,
                  ),
                ],
              ),
            ),

            // 3. Dish List inside rounded card (Categorized into New to Prepare & Already Done)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    // Section 1: NEW ITEMS TO PREPARE
                    if (newItems.isNotEmpty) ...[
                      if (anyPrepared)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.soup_kitchen_rounded, size: 13, color: Color(0xFFEA580C)),
                              const SizedBox(width: 6),
                              Text(
                                'NEW ITEMS TO PREPARE ($newQty items)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...newItems.map((item) => _buildDishRow(
                            item: item,
                            isDone: false,
                            isDark: isDark,
                            borderColor: borderColor,
                            isUpdatedOrder: isRunningOrder,
                          )),
                    ],

                    // Section 2: ALREADY DONE / PREPARED ITEMS
                    if (doneItems.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: EdgeInsets.only(top: newItems.isNotEmpty ? 12 : 0, bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              'ALREADY DONE / SERVED ($doneQty items)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...doneItems.map((item) => _buildDishRow(
                            item: item,
                            isDone: true,
                            isDark: isDark,
                            borderColor: borderColor,
                            isUpdatedOrder: isRunningOrder,
                          )),
                    ],
                  ],
                ),
              ),
            ),

            if (ticket.specialInstruction != null && ticket.specialInstruction!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: ${ticket.specialInstruction}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 4. Modal Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Review Later',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
                      label: Text(
                        anyPrepared
                            ? 'Accept & Prep New Items ($newQty items)'
                            : 'Accept & Start Prep ($totalQty items)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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

  Widget _buildDishRow({
    required KotItem item,
    required bool isDone,
    required bool isDark,
    required Color borderColor,
    required bool isUpdatedOrder,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFEA580C).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFFEA580C).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFEA580C),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF94A3B8),
                          decorationThickness: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 11, color: Color(0xFF10B981)),
                            SizedBox(width: 2),
                            Text(
                              'ALREADY DONE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isUpdatedOrder) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.35)),
                        ),
                        child: const Text(
                          'NEW / TO PREP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '👉 ${item.notes!}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

