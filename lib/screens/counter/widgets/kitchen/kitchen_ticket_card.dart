import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_pos_models.dart';

class KitchenTicketCard extends StatelessWidget {
  final KitchenTicket ticket;
  final ValueChanged<KotStatus> onUpdateStatus;
  final ValueChanged<String> onToggleItem;
  final VoidCallback onPrintKot;

  const KitchenTicketCard({
    super.key,
    required this.ticket,
    required this.onUpdateStatus,
    required this.onToggleItem,
    required this.onPrintKot,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    Color statusColor;
    String nextActionLabel;
    KotStatus? nextStatus;
    IconData actionIcon;

    switch (ticket.status) {
      case KotStatus.newOrder:
        statusColor = const Color(0xFFEF4444);
        nextActionLabel = 'Start Prep';
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

    // Elapsed SLA Calculation
    final elapsedMins = DateTime.now().difference(ticket.createdAt).inMinutes;
    final isUrgent = elapsedMins >= 15 && ticket.status != KotStatus.served;
    final isWarning = elapsedMins >= 10 && elapsedMins < 15 && ticket.status != KotStatus.served;

    // Check preparation progress of individual items
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
          width: isUrgent ? 2.2 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                : (isDark ? Colors.black45 : const Color(0xFF0F172A).withValues(alpha: 0.05)),
            blurRadius: isUrgent ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: KOT Number + Live Elapsed SLA Badge + Print Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: ticket.status == KotStatus.served ? 0.06 : 0.12),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              ticket.status == KotStatus.newOrder
                                  ? 'NEW'
                                  : (ticket.status == KotStatus.preparing
                                      ? 'IN PREP'
                                      : (ticket.status == KotStatus.ready ? 'READY' : 'SERVED')),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            ticket.orderNumber,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('•', style: TextStyle(fontSize: 10, color: borderColor)),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('hh:mm a').format(ticket.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SLA Timer & Print Icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFEF4444)
                            : (isWarning
                                ? const Color(0xFFF59E0B)
                                : (isDark ? const Color(0xFF0F172A) : Colors.white)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isUrgent || isWarning) ? Colors.transparent : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUrgent ? Icons.warning_rounded : Icons.timer_outlined,
                            size: 12,
                            color: (isUrgent || isWarning)
                                ? Colors.white
                                : (ticket.status == KotStatus.served
                                    ? const Color(0xFF64748B)
                                    : statusColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            elapsedMins < 60
                                ? '${elapsedMins}m'
                                : '${elapsedMins ~/ 60}h ${elapsedMins % 60}m',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: (isUrgent || isWarning)
                                  ? Colors.white
                                  : (ticket.status == KotStatus.served
                                      ? const Color(0xFF64748B)
                                      : statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onPrintKot,
                      tooltip: 'Print KOT Slip',
                      icon: const Icon(Icons.print_rounded, size: 18),
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(),
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Metadata Bar: Table Tag / Order Type / Server
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Row(
              children: [
                // Order Type Pill (Dine-in / Takeaway / Delivery)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (ticket.orderType == OrderType.dineIn
                            ? const Color(0xFF10B981)
                            : (ticket.orderType == OrderType.takeaway
                                ? const Color(0xFFF97316)
                                : const Color(0xFF8B5CF6)))
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (ticket.orderType == OrderType.dineIn
                              ? const Color(0xFF10B981)
                              : (ticket.orderType == OrderType.takeaway
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF8B5CF6)))
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ticket.orderType == OrderType.dineIn
                            ? Icons.table_restaurant_rounded
                            : (ticket.orderType == OrderType.takeaway
                                ? Icons.shopping_bag_rounded
                                : Icons.delivery_dining_rounded),
                        size: 12,
                        color: ticket.orderType == OrderType.dineIn
                            ? const Color(0xFF10B981)
                            : (ticket.orderType == OrderType.takeaway
                                ? const Color(0xFFF97316)
                                : const Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.tableLabel != null && ticket.tableLabel!.isNotEmpty
                            ? 'Table ${ticket.tableLabel}'
                            : ticket.orderType.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: ticket.orderType == OrderType.dineIn
                              ? const Color(0xFF10B981)
                              : (ticket.orderType == OrderType.takeaway
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF8B5CF6)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ticket.floor != null && ticket.floor!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('• ${ticket.floor}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
                const Spacer(),
                Text(
                  ticket.serverName ?? 'Staff',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // 3. Line Items with Touch Strike-through & Progress Indicator
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: ticket.items.length,
              separatorBuilder: (_, __) => Divider(height: 8, color: borderColor.withValues(alpha: 0.5)),
              itemBuilder: (context, idx) {
                final it = ticket.items[idx];
                return InkWell(
                  onTap: () => onToggleItem(it.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          it.isPrepared ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: it.isPrepared
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: it.isPrepared
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${it.quantity}x',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: it.isPrepared
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
                              Text(
                                it.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: it.isPrepared
                                      ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                      : textColor,
                                  decoration: it.isPrepared ? TextDecoration.lineThrough : null,
                                  decorationColor: const Color(0xFF94A3B8),
                                  decorationThickness: 1.5,
                                ),
                              ),
                              if (it.notes != null && it.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '👉 ${it.notes!}',
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

          // 4. Action Progression Button: Start Prep / Mark Ready / Mark Served
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: nextStatus != null
                  ? ElevatedButton(
                      onPressed: () => onUpdateStatus(nextStatus!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (nextStatus == KotStatus.ready && !allItemsPrepared)
                            ? statusColor.withValues(alpha: 0.85)
                            : statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
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
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
