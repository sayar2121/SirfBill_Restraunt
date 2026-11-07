import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'kitchen_badges.dart';
import 'kitchen_ticket_item_row.dart';

class KitchenTicketCard extends StatelessWidget {
  final KitchenTicket ticket;
  final ValueChanged<KotStatus>? onUpdateStatus;
  final ValueChanged<String>? onToggleItem;
  final VoidCallback onPrintKot;
  final bool isReadOnly;

  const KitchenTicketCard({
    super.key,
    required this.ticket,
    this.onUpdateStatus,
    this.onToggleItem,
    required this.onPrintKot,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Color statusColor;
    String nextActionLabel;
    KotStatus? nextStatus;
    IconData actionIcon;

    switch (ticket.status) {
      case KotStatus.newOrder:
        statusColor = const Color(0xFFEF4444);
        nextActionLabel = 'Accept & Prep';
        nextStatus = KotStatus.preparing;
        actionIcon = Icons.soup_kitchen_rounded;
        break;
      case KotStatus.preparing:
        statusColor = const Color(0xFFF59E0B);
        nextActionLabel = 'Mark Ready';
        nextStatus = KotStatus.ready;
        actionIcon = Icons.done_all_rounded;
        break;
      case KotStatus.ready:
        statusColor = const Color(0xFF10B981);
        nextActionLabel = 'Mark Served';
        nextStatus = KotStatus.served;
        actionIcon = Icons.check_circle_outline_rounded;
        break;
      case KotStatus.served:
        statusColor = const Color(0xFF6366F1);
        nextActionLabel = 'Order Served';
        nextStatus = null;
        actionIcon = Icons.check_circle_rounded;
        break;
    }

    final elapsedMins = DateTime.now().difference(ticket.createdAt).inMinutes;
    final isUrgent = elapsedMins >= 15 && ticket.status != KotStatus.served;

    final totalItemsCount = ticket.items.length;
    final preparedItemsCount = ticket.items.where((i) => i.isPrepared).length;
    final allItemsPrepared = totalItemsCount > 0 && preparedItemsCount == totalItemsCount;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFEF4444)
              : (ticket.status == KotStatus.served
                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                  : statusColor.withValues(alpha: 0.6)),
          width: isUrgent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : const Color(0xFF64748B).withValues(alpha: 0.08)),
            blurRadius: isUrgent ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: KOT Number + Live Elapsed Timer + Print
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [statusColor.withValues(alpha: 0.18), statusColor.withValues(alpha: 0.06)]
                    : [statusColor.withValues(alpha: 0.14), statusColor.withValues(alpha: 0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.25))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ticket.kotNumber,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          KitchenStatusBadge(status: ticket.status, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ticket.orderNumber,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('•', style: TextStyle(fontSize: 10, color: borderColor)),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('hh:mm a').format(ticket.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KitchenTimerBadge(
                      createdAt: ticket.createdAt,
                      prepStartedAt: ticket.prepStartedAt,
                      status: ticket.status,
                      statusColor: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: onPrintKot,
                        tooltip: 'Print KOT Slip',
                        icon: const Icon(Icons.print_rounded, size: 18),
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(),
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Metadata Bar: Fulfillment Type Badge / Floor / Server
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: KitchenOrderTypeBadge(
                          orderType: ticket.orderType,
                          tableLabel: ticket.tableLabel,
                        ),
                      ),
                      if (ticket.floor != null && ticket.floor!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '• ${ticket.floor}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.serverName ?? 'Staff',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Line Items with Reusable KitchenTicketItemRow
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: ticket.items.length,
              separatorBuilder: (_, __) => Divider(height: 8, color: borderColor.withValues(alpha: 0.5)),
              itemBuilder: (context, idx) {
                final it = ticket.items[idx];
                return KitchenTicketItemRow(
                  item: it,
                  onToggle: isReadOnly ? null : () => onToggleItem?.call(it.id),
                  isReadOnly: isReadOnly,
                );
              },
            ),
          ),

          // Special Instruction notice if present
          if (ticket.specialInstruction != null && ticket.specialInstruction!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.specialInstruction!,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E), fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4. Status Indicator / Action Progression Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: isReadOnly
                  ? Container(
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(actionIcon, size: 16, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            ticket.status == KotStatus.newOrder
                                ? 'New Order • In Queue'
                                : (ticket.status == KotStatus.preparing
                                    ? 'Kitchen In Prep'
                                    : (ticket.status == KotStatus.ready
                                        ? 'Food Ready • Waiting for Pickup'
                                        : 'Order Fully Served')),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (nextStatus != null
                      ? ElevatedButton(
                          onPressed: () => onUpdateStatus?.call(nextStatus!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (nextStatus == KotStatus.ready && !allItemsPrepared)
                                ? statusColor.withValues(alpha: 0.85)
                                : statusColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                            shadowColor: statusColor.withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(actionIcon, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                nextStatus == KotStatus.ready && allItemsPrepared
                                    ? 'All Prepared • Ready'
                                    : nextActionLabel,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 17, color: Color(0xFF6366F1)),
                              SizedBox(width: 6),
                              Text(
                                'Order Fully Served',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        )),
            ),
          ),
        ],
      ),
    );
  }
}
