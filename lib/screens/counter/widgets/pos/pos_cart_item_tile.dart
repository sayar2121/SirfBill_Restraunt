import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class PosCartItemTile extends StatelessWidget {
  final int index;
  final PosCartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const PosCartItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index Badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Dish Name & Notes
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                ),
                if (item.notes != null)
                  Text(
                    item.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),

          // Unit Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '₹ ${item.item.price.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),

          // Quantity Stepper (- Qty +)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onDecrement,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    child: const Text('–', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onIncrement,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    child: const Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Line Total
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Text(
              '₹ ${item.totalPrice.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
          const SizedBox(width: 8),

          // Enlarged Touch-Friendly Delete button
          Tooltip(
            message: 'Remove item',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
