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

    switch (ticket.status) {
      case KotStatus.newOrder:
        statusColor = const Color(0xFFEF4444);
        nextActionLabel = 'Start Prep';
        nextStatus = KotStatus.preparing;
        break;
      case KotStatus.preparing:
        statusColor = const Color(0xFFF59E0B);
        nextActionLabel = 'Mark Ready';
        nextStatus = KotStatus.ready;
        break;
      case KotStatus.ready:
        statusColor = const Color(0xFF10B981);
        nextActionLabel = 'Mark Served';
        nextStatus = KotStatus.served;
        break;
      case KotStatus.served:
        statusColor = const Color(0xFF6366F1);
        nextActionLabel = 'Order Served';
        nextStatus = null;
        break;
    }

    final elapsedMins = DateTime.now().difference(ticket.createdAt).inMinutes;
    final isUrgent = elapsedMins >= 15 && ticket.status != KotStatus.served;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFEF4444)
              : (ticket.status == KotStatus.served
                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                  : statusColor.withValues(alpha: 0.6)),
          width: isUrgent ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: KOT # + Timer + Print
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: ticket.status == KotStatus.served ? 0.06 : 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1)),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.status == KotStatus.newOrder
                                  ? 'NEW'
                                  : (ticket.status == KotStatus.preparing
                                      ? 'IN PREP'
                                      : (ticket.status == KotStatus.ready ? 'READY' : 'SERVED')),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            ticket.orderNumber,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '•',
                            style: TextStyle(fontSize: 10, color: borderColor),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.schedule_rounded,
                            size: 10,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('hh:mm a').format(ticket.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('dd MMM yyyy').format(ticket.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 8.5,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUrgent ? Colors.transparent : borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 11, color: isUrgent ? Colors.white : (ticket.status == KotStatus.served ? const Color(0xFF64748B) : statusColor)),
                          const SizedBox(width: 4),
                          Text(
                            elapsedMins < 60
                                ? '${elapsedMins}m'
                                : (elapsedMins < 1440
                                    ? '${elapsedMins ~/ 60}h ${elapsedMins % 60}m'
                                    : '${elapsedMins ~/ 1440}d ago'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.white : (ticket.status == KotStatus.served ? const Color(0xFF64748B) : statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onPrintKot,
                      tooltip: 'Print KOT Slip',
                      icon: const Icon(Icons.print_rounded, size: 16),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Meta Info: Table & Server / Source
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (ticket.orderType == OrderType.dineIn
                            ? const Color(0xFF10B981)
                            : (ticket.orderType == OrderType.takeaway ? const Color(0xFFF97316) : const Color(0xFF8B5CF6)))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    ticket.tableLabel != null && ticket.tableLabel!.isNotEmpty
                        ? 'Table ${ticket.tableLabel}'
                        : ticket.orderType.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: ticket.orderType == OrderType.dineIn
                          ? const Color(0xFF10B981)
                          : (ticket.orderType == OrderType.takeaway ? const Color(0xFFF97316) : const Color(0xFF8B5CF6)),
                    ),
                  ),
                ),
                if (ticket.floor != null && ticket.floor!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('• ${ticket.floor}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                ],
                const Spacer(),
                Text(
                  ticket.serverName ?? 'Staff',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Items List with interactive Strike-through Checkbox
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: ticket.items.length,
              separatorBuilder: (_, __) => Divider(height: 8, color: borderColor.withValues(alpha: 0.5)),
              itemBuilder: (context, idx) {
                final it = ticket.items[idx];
                return InkWell(
                  onTap: () => onToggleItem(it.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          it.isPrepared ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 19,
                          color: it.isPrepared ? const Color(0xFF10B981) : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: it.isPrepared ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                                  child: Text(
                                    '👉 ${it.notes!}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w700,
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
          if (ticket.specialInstruction != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.specialInstruction!,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bottom Action Button: Next Progression Status (or Completed Indicator for Served)
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: nextStatus != null
                  ? ElevatedButton(
                      onPressed: () => onUpdateStatus(nextStatus!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nextActionLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF6366F1)),
                          SizedBox(width: 6),
                          Text(
                            'Order Served',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
