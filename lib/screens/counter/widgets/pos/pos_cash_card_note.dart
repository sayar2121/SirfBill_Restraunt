import 'package:flutter/material.dart';

/// Informative callout card for Cash / Card payment modes.
class PosCashCardNote extends StatelessWidget {
  final String selectedMode;
  final double grandTotal;
  final bool isDark;

  const PosCashCardNote({
    super.key,
    required this.selectedMode,
    required this.grandTotal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            selectedMode == 'Cash' ? Icons.payments_rounded : Icons.credit_card_rounded,
            size: 24,
            color: selectedMode == 'Cash' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedMode == 'Cash'
                  ? 'Collect ₹${grandTotal.toStringAsFixed(0)} cash at counter register.'
                  : 'Swipe or tap customer card on EDC POS machine.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
