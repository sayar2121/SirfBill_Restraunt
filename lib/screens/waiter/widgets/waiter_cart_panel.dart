import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';

class WaiterCartPanel extends StatelessWidget {
  final bool isWide;
  final String? selectedTableId;
  final String selectedTableLabel;
  final List<PosCartItem> cart;
  final List<PosCartItem> initialCart;
  final String? activeOrderId;
  final TextEditingController notesController;
  final bool isSubmitting;
  final double cartTotal;
  final void Function(int index) onIncrement;
  final void Function(int index) onDecrement;
  final void Function(int index) onRemove;
  final VoidCallback? onClearCart;
  final VoidCallback onSubmit;

  const WaiterCartPanel({
    super.key,
    required this.isWide,
    required this.selectedTableId,
    required this.selectedTableLabel,
    required this.cart,
    required this.initialCart,
    required this.activeOrderId,
    required this.notesController,
    required this.isSubmitting,
    required this.cartTotal,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onClearCart,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final totalItemsCount = cart.fold<int>(0, (sum, i) => sum + i.quantity);

    // Count how many new items are not yet sent to kitchen
    int newItemsCount = 0;
    for (final item in cart) {
      final match = initialCart.where((i) => i.item.id == item.item.id).firstOrNull;
      if (match == null) {
        newItemsCount += item.quantity;
      } else if (item.quantity > match.quantity) {
        newItemsCount += (item.quantity - match.quantity);
      }
    }

    final isExistingOrder = activeOrderId != null && activeOrderId!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          left: BorderSide(color: borderColor, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactHeight = constraints.maxHeight < 440;

          // 1. Table Banner
          final tableBanner = Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: selectedTableId != null
                  ? LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF3B290C), const Color(0xFF1E293B)]
                          : [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selectedTableId == null
                  ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: selectedTableId != null
                      ? const Color(0xFFFDE68A)
                      : borderColor,
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selectedTableId != null
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: selectedTableId != null
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    size: 18,
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
                          Text(
                            selectedTableId != null
                                ? 'Table $selectedTableLabel'
                                : 'No Table Selected',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: selectedTableId != null
                                  ? (isDark ? Colors.white : const Color(0xFF92400E))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (isExistingOrder) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SEATED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedTableId != null
                            ? (isExistingOrder
                                ? 'Adding items to seated order'
                                : 'Punching new dining order')
                            : 'Tap any table above to assign this ticket',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: selectedTableId != null
                              ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (cart.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalItemsCount Qty',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (onClearCart != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmClearCart(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );

          // 2. Order Ticket Items List
          final itemsList = cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 26,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectedTableId == null
                              ? 'Select a Table to Begin'
                              : 'Order Ticket is Empty',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedTableId == null
                              ? 'Tap any table above to build order'
                              : 'Tap dishes from the menu for Table $selectedTableLabel.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: isCompactHeight,
                  physics: isCompactHeight ? const NeverScrollableScrollPhysics() : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = cart[idx];
                    final initMatch = initialCart
                        .where((i) => i.item.id == item.item.id)
                        .firstOrNull;
                    final isRunningDelta =
                        initMatch != null && item.quantity > initMatch.quantity;
                    final isAlreadySent =
                        initMatch != null && item.quantity <= initMatch.quantity;

                    final lineTotal = item.item.price * item.quantity;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRunningDelta
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                              : borderColor,
                          width: isRunningDelta ? 1.4 : 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Veg / Non-Veg Indicator
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: item.item.isVeg
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.item.isVeg
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Dish Title & Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.item.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      '₹${item.item.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (isAlreadySent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '✓ Sent (${initMatch.quantity})',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isRunningDelta) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '+${item.quantity - initMatch.quantity} New',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFFD97706),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Large Touch-Friendly Stepper Controls
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => onDecrement(idx),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                    child: Container(
                                      width: 36,
                                      height: 38,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        item.quantity == 1
                                            ? Icons.delete_outline_rounded
                                            : Icons.remove_rounded,
                                        size: item.quantity == 1 ? 17 : 18,
                                        color: item.quantity == 1
                                            ? const Color(0xFFEF4444)
                                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 30),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => onIncrement(idx),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                    child: Container(
                                      width: 36,
                                      height: 38,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 19,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Line Total
                          SizedBox(
                            width: 54,
                            child: Text(
                              '₹${lineTotal.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );

          // 3. Bottom Summary
          final bottomSummary = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor, width: 1.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Kitchen Notes Input
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: notesController,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.note_alt_outlined, size: 17, color: Color(0xFFF59E0B)),
                      hintText: 'Kitchen note (e.g. less spicy)...',
                      hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Total Row with Clear All Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$totalItemsCount Items in ticket',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (cart.isNotEmpty && onClearCart != null) ...[
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _confirmClearCart(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '₹${cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Dispatch Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTableId == null || cart.isEmpty
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                        : const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: selectedTableId != null && cart.isNotEmpty ? 3 : 0,
                    shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting || selectedTableId == null || cart.isEmpty
                      ? null
                      : onSubmit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isExistingOrder
                                  ? Icons.soup_kitchen_rounded
                                  : Icons.send_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isExistingOrder
                                  ? (newItemsCount > 0
                                      ? 'Update & Send KOT (+$newItemsCount New)'
                                      : 'Update & Send KOT')
                                  : 'Place Order & Send KOT',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );

          if (isCompactHeight) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tableBanner,
                  itemsList,
                  bottomSummary,
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tableBanner,
              Expanded(child: itemsList),
              bottomSummary,
            ],
          );
        },
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    if (onClearCart == null) return;
    final isExistingOrder = activeOrderId != null && activeOrderId!.isNotEmpty;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Clear Order Ticket?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isExistingOrder
              ? 'This will clear newly added unsent items and reset to the active order.'
              : 'Are you sure you want to remove all items from this order ticket?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onClearCart?.call();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
