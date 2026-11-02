import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? text;

  const StatusBadge({super.key, required this.status, this.text});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'In Stock':
      case 'OK':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'Medium Stock':
        bgColor = const Color(0xFFDBEAFE); // Blueish
        textColor = const Color(0xFF1E40AF);
        break;
      case 'Low Stock':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        break;
      case 'Out of Stock':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text ?? status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
