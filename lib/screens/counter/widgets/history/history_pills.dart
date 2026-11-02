import 'package:flutter/material.dart';

class HistoryPills {
  static Widget buildTypePill(BuildContext context, String type) {
    Color bgColor, textColor;
    IconData icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case 'Sale':
        bgColor = isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        icon = Icons.shopping_cart_outlined;
        break;
      case 'Return':
        bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        textColor = Colors.red;
        icon = Icons.keyboard_return;
        break;
      case 'Adjustment':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFF97316);
        icon = Icons.inventory_2_outlined;
        break;
      case 'Purchase':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.local_shipping_outlined;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPaymentModePill(BuildContext context, String mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (mode == '-') {
      return Text(
        '-',
        style: TextStyle(
          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
        ),
      );
    }

    Color bgColor, textColor;
    switch (mode) {
      case 'Cash':
        bgColor = isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        break;
      case 'UPI':
        bgColor = isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF);
        textColor = const Color(0xFFA855F7);
        break;
      case 'Card':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'Bank Transfer':
        bgColor = isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF);
        textColor = const Color(0xFFA855F7);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
