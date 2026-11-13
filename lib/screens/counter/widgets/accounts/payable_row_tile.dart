import 'package:flutter/material.dart';

/// Row widget rendering an individual payable line with supplier avatar, invoice no, amount, and Pay button.
class PayableRowTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onPay;

  const PayableRowTile({
    super.key,
    required this.item,
    required this.onPay,
  });

  static String _fmt(double amt) => '₹${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final supplierName = item['entity_name']?.toString() ?? 'Unknown';
    final invoiceNo = item['invoice_no']?.toString();
    final amountOwed = (item['amount_owed'] as num?)?.toDouble() ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF),
                  child: Text(
                    supplierName.isNotEmpty ? supplierName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (invoiceNo != null && invoiceNo != 'N/A' && invoiceNo != '-')
                        Text(
                          'Invoice: $invoiceNo',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmt(amountOwed),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payment, size: 14),
                label: const Text(
                  'Pay',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

