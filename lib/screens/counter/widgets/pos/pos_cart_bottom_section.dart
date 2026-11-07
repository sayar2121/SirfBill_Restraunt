import 'package:flutter/material.dart';

import '../../../../providers/restaurant_pos_provider.dart';
import 'pos_bill_summary.dart';
import 'pos_bottom_action_bar.dart';

/// Reusable checkout bottom section for notes, calculations, and actions
class PosCartBottomSection extends StatelessWidget {
  final RestaurantPosState posState;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onAddDiscount;
  final VoidCallback onSaveHold;
  final VoidCallback onPrintKot;
  final VoidCallback onProceedToPayment;

  const PosCartBottomSection({
    super.key,
    required this.posState,
    required this.onNotesChanged,
    required this.onAddDiscount,
    required this.onSaveHold,
    required this.onPrintKot,
    required this.onProceedToPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Notes Field
          TextField(
            onChanged: onNotesChanged,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF94A3B8)),
              hintText: 'Add order notes (e.g. less spicy, no onion...)',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bill Financials Summary
          PosBillSummary(
            subtotal: posState.subtotal,
            discount: posState.discountAmount,
            gstPercent: posState.gstPercent,
            gstAmount: posState.gstAmount,
            grandTotal: posState.grandTotal,
            onAddDiscount: onAddDiscount,
          ),
          const SizedBox(height: 8),

          // Action Bar (Save/Hold, Print KOT, Payment)
          PosBottomActionBar(
            activeOrderLabel: posState.activeOrderNumber,
            onSaveHold: onSaveHold,
            onPrintKot: onPrintKot,
            onProceedToPayment: onProceedToPayment,
          ),
        ],
      ),
    );
  }
}
