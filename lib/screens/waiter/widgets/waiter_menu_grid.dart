import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';
import 'waiter_menu_card.dart';

class WaiterMenuGrid extends StatelessWidget {
  final List<PosMenuItem> items;
  final List<PosCartItem> cart;
  final bool isWide;
  final ValueChanged<PosMenuItem> onAddItem;
  final ValueChanged<PosMenuItem>? onIncrementItem;
  final ValueChanged<PosMenuItem>? onDecrementItem;

  const WaiterMenuGrid({
    super.key,
    required this.items,
    required this.cart,
    required this.isWide,
    required this.onAddItem,
    this.onIncrementItem,
    this.onDecrementItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No menu items match your search',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try selecting another category or clearing search',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1150) {
          crossAxisCount = 5;
        } else if (width >= 880) {
          crossAxisCount = 4;
        } else if (width >= 580) {
          crossAxisCount = 3;
        } else if (width >= 340) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 10 - 28) / crossAxisCount;
        final cardHeight = (cardWidth * 10 / 16) + 78;
        final childAspectRatio = (cardWidth / cardHeight).clamp(0.82, 1.15);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            final cartMatch = cart.where((c) => c.item.id == item.id).firstOrNull;
            final cartQty = cartMatch?.quantity ?? 0;

            return WaiterMenuCard(
              item: item,
              cartQuantity: cartQty,
              onAdd: () => onAddItem(item),
              onIncrement: onIncrementItem != null ? () => onIncrementItem!(item) : () => onAddItem(item),
              onDecrement: onDecrementItem != null ? () => onDecrementItem!(item) : null,
            );
          },
        );
      },
    );
  }
}
