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

/// Animated live pulsing badge with glowing halo and breathing green dot
class LivePulseBadge extends StatefulWidget {
  final String label;
  final Color color;

  const LivePulseBadge({
    super.key,
    this.label = 'LIVE KDS',
    this.color = const Color(0xFF10B981),
  });

  @override
  State<LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.45),
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing pulse ring
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: (1.0 - _opacityAnimation.value) * 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Inner solid pulsing beacon
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.8),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable timer & SLA indicator badge (Elapsed minutes with Warning / Urgent colors)
class KitchenTimerBadge extends StatelessWidget {
  final DateTime createdAt;
  final DateTime? prepStartedAt;
  final KotStatus status;
  final Color statusColor;

  const KitchenTimerBadge({
    super.key,
    required this.createdAt,
    this.prepStartedAt,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // If order is still 'newOrder' (not accepted yet), show queued time or 'Waiting'
    final isQueued = status == KotStatus.newOrder;
    final timerBase = (prepStartedAt != null) ? prepStartedAt! : createdAt;
    final diff = DateTime.now().difference(timerBase);
    final elapsedMins = diff.inMinutes;

    final isUrgent = elapsedMins >= 15 && status != KotStatus.served;
    final isWarning = elapsedMins >= 10 && elapsedMins < 15 && status != KotStatus.served;

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final hhmmss = '$h:$m:$s';

    final Color badgeBg = isUrgent
        ? const Color(0xFFEF4444)
        : (isWarning
            ? const Color(0xFFF59E0B)
            : (isDark ? const Color(0xFF0F172A) : Colors.white));

    final Color textColor = (isUrgent || isWarning)
        ? Colors.white
        : (status == KotStatus.served ? const Color(0xFF64748B) : statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
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
            isUrgent ? Icons.warning_rounded : (isQueued ? Icons.schedule_rounded : Icons.timer_outlined),
            size: 11,
            color: textColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            hhmmss,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: typeColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

