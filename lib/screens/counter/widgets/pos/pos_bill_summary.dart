import 'package:flutter/material.dart';

class PosBillSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final VoidCallback onAddDiscount;

  const PosBillSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.onAddDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        _buildRow('Subtotal', '₹ ${subtotal.toStringAsFixed(0)}', mutedColor, textColor),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Discount', style: TextStyle(fontSize: 12, color: mutedColor)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onAddDiscount,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF10B981)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 10, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('Add Discount', style: TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Text('₹ ${discount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
        const SizedBox(height: 6),
        _buildRow('GST (${gstPercent.toStringAsFixed(0)}%)', '₹ ${gstAmount.toStringAsFixed(0)}', mutedColor, textColor),
        const Divider(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Grand Total',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor),
            ),
            Text(
              '₹ ${grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
