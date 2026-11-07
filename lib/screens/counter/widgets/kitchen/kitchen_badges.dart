import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

/// Reusable status pill widget for KDS tickets (New, In Prep, Ready, Served)
class KitchenStatusBadge extends StatelessWidget {
  final KotStatus status;
  final Color color;

  const KitchenStatusBadge({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    switch (status) {
      case KotStatus.newOrder:
        label = 'NEW';
        break;
      case KotStatus.preparing:
        label = 'IN PREP';
        break;
      case KotStatus.ready:
        label = 'READY';
        break;
      case KotStatus.served:
        label = 'SERVED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

/// Reusable timer & SLA indicator badge (Elapsed minutes with Warning / Urgent colors)
class KitchenTimerBadge extends StatelessWidget {
  final DateTime createdAt;
  final KotStatus status;
  final Color statusColor;

  const KitchenTimerBadge({
    super.key,
    required this.createdAt,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final elapsedMins = DateTime.now().difference(createdAt).inMinutes;
    final isUrgent = elapsedMins >= 15 && status != KotStatus.served;
    final isWarning = elapsedMins >= 10 && elapsedMins < 15 && status != KotStatus.served;

    final Color badgeBg = isUrgent
        ? const Color(0xFFEF4444)
        : (isWarning
            ? const Color(0xFFF59E0B)
            : (isDark ? const Color(0xFF0F172A) : Colors.white));

    final Color textColor = (isUrgent || isWarning)
        ? Colors.white
        : (status == KotStatus.served ? const Color(0xFF64748B) : statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
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
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            elapsedMins < 60
                ? '${elapsedMins}m'
                : '${elapsedMins ~/ 60}h ${elapsedMins % 60}m',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Fulfillment type badge (Dine-in with Table, Takeaway, Delivery)
class KitchenOrderTypeBadge extends StatelessWidget {
  final OrderType orderType;
  final String? tableLabel;

  const KitchenOrderTypeBadge({
    super.key,
    required this.orderType,
    this.tableLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    String label;

    switch (orderType) {
      case OrderType.dineIn:
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.table_restaurant_rounded;
        label = (tableLabel != null && tableLabel!.isNotEmpty) ? 'Table $tableLabel' : 'DINE-IN';
        break;
      case OrderType.takeaway:
        typeColor = const Color(0xFFF97316);
        typeIcon = Icons.shopping_bag_rounded;
        label = 'TAKEAWAY';
        break;
      case OrderType.delivery:
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.delivery_dining_rounded;
        label = 'DELIVERY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: typeColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon, size: 12, color: typeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }
}
