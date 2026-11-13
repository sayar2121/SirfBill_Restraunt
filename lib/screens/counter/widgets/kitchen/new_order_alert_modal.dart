import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'new_order_alert_components.dart';

/// Interactive modal alert displayed on the dedicated KDS screen when a new order arrives.
/// Refactored into modular presentation components:
/// - [NewOrderAlertHeader]: Gradient top bar with live pulse badge, title, and dismiss.
/// - [NewOrderAlertTicketMeta]: KOT number, status badge, order ID, and order type / table.
/// - [NewOrderDishList]: Grouped dish list (new to prepare vs already done items).
/// - [NewOrderAlertSpecialNote]: Cooking instructions banner.
/// - [NewOrderAlertActions]: Review later and Accept preparation CTA buttons.
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

    final anyPrepared = ticket.items.any((i) => i.isPrepared);
    final isRunningOrder = anyPrepared || ticket.items.any((i) => i.isRunningItem);

    // Group items: New / To Prepare items first, followed by already Done / Served items
    final newItems = ticket.items.where((i) => !i.isPrepared).toList();
    final doneItems = ticket.items.where((i) => i.isPrepared).toList();

    final totalQty = ticket.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final newQty = newItems.fold<int>(0, (sum, i) => sum + i.quantity);

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
            NewOrderAlertHeader(
              isRunningOrder: isRunningOrder,
              newQty: newQty,
              restaurantName: restaurantName,
              onDismiss: onDismiss,
            ),

            // 2. Ticket Identification & Metadata Banner
            NewOrderAlertTicketMeta(
              ticket: ticket,
              isRunningOrder: isRunningOrder,
            ),

            // 3. Dish List inside rounded card (Categorized into New to Prepare & Already Done)
            NewOrderDishList(
              newItems: newItems,
              doneItems: doneItems,
              anyPrepared: anyPrepared,
              isRunningOrder: isRunningOrder,
            ),

            // Optional Special Instruction note
            if (ticket.specialInstruction != null && ticket.specialInstruction!.isNotEmpty)
              NewOrderAlertSpecialNote(note: ticket.specialInstruction!),

            // 4. Modal Action Buttons
            NewOrderAlertActions(
              onDismiss: onDismiss,
              onAccept: onAccept,
              anyPrepared: anyPrepared,
              newQty: newQty,
              totalQty: totalQty,
            ),
          ],
        ),
      ),
    );
  }
}
