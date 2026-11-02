import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_pos_models.dart';

class OrderCard extends StatelessWidget {
  final RestaurantOrder order;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onPrintKot;
  final VoidCallback onPrintBill;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onComplete,
    required this.onPrintKot,
    required this.onPrintBill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    Color statusColor;
    String statusText;
    switch (order.status) {
      case OrderStatus.active:
        statusColor = const Color(0xFF3B82F6);
        statusText = 'In Prep';
        break;
      case OrderStatus.completed:
        statusColor = const Color(0xFF10B981);
        statusText = 'Completed';
        break;
      case OrderStatus.hold:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'On Hold';
        break;
      case OrderStatus.cancelled:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Cancelled';
        break;
    }

    String typeLabel;
    IconData typeIcon;
    switch (order.orderType) {
      case OrderType.dineIn:
        typeLabel = order.tableLabel != null ? 'Table ${order.tableLabel}' : 'Dine-In';
        typeIcon = Icons.table_restaurant_rounded;
        break;
      case OrderType.takeaway:
        typeLabel = 'Takeaway';
        typeIcon = Icons.shopping_bag_outlined;
        break;
      case OrderType.delivery:
        typeLabel = 'Delivery';
        typeIcon = Icons.delivery_dining_rounded;
        break;
    }

    // Exact Local Date & Time Format
    final localTime = order.createdAt.toLocal();
    final timeStr = DateFormat('hh:mm a').format(localTime);
    final dateStr = DateFormat('dd MMM yyyy').format(localTime);

    // Natural relative time calculation (mins or hrs)
    final diff = DateTime.now().difference(localTime);
    final String relativeTime;
    if (diff.inSeconds < 60) {
      relativeTime = 'Just now';
    } else if (diff.inMinutes < 60) {
      relativeTime = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      relativeTime = '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    } else {
      relativeTime = '${diff.inDays}d ago';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.status == OrderStatus.active
                ? statusColor.withValues(alpha: 0.5)
                : borderColor,
            width: order.status == OrderStatus.active ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Strip: Order #, Status Pill, Exact Time & Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.7))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• $relativeTime',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Middle Body: Table/Type pill + Customer Name + Items preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge & Guest
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 13, color: const Color(0xFF059669)),
                              const SizedBox(width: 5),
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerName.isNotEmpty ? order.customerName : 'Walk-in Guest',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items snippet
                    Expanded(
                      child: Text(
                        order.items.map((it) => '${it.quantity}x ${it.item.name}').join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.85),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Bottom Footer Strip: Grand Total & Quick Touch Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.7))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        '₹${order.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // KOT Print button
                      Tooltip(
                        message: 'Print Kitchen KOT',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onPrintKot,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
                            ),
                            child: const Center(
                              child: Icon(Icons.receipt_long_rounded, size: 17, color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Bill Print button
                      Tooltip(
                        message: 'Print Customer Bill',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onPrintBill,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                            ),
                            child: const Center(
                              child: Icon(Icons.print_rounded, size: 17, color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                      ),

                      // Mark Complete button (for in-prep active orders)
                      if (order.status == OrderStatus.active) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Complete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
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
