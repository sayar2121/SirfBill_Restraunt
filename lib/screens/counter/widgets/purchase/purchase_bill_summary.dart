import 'package:flutter/material.dart';

class PurchaseBillSummary extends StatelessWidget {
  final double subtotal;
  final double totalGst;
  final double globalDiscount;
  final double grandTotal;
  final String paymentStatus;
  final double amountPaid;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<double> onAmountPaidChanged;

  const PurchaseBillSummary({
    super.key,
    required this.subtotal,
    required this.totalGst,
    required this.globalDiscount,
    required this.grandTotal,
    required this.paymentStatus,
    required this.amountPaid,
    required this.onDiscountChanged,
    required this.onPaymentStatusChanged,
    required this.onAmountPaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Subtotal: ', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Total GST: ', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '+ ₹${totalGst.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Discount: ', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          onDiscountChanged(double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Grand Total: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '₹${grandTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: paymentStatus,
                  items: const [
                    DropdownMenuItem(value: 'UNPAID', child: Text('UNPAID')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('PARTIAL')),
                    DropdownMenuItem(
                      value: 'PAID',
                      child: Text('PAID (Deduct from Accounts)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      onPaymentStatusChanged(v);
                    }
                  },
                ),
              ],
            ),
            if (paymentStatus == 'PARTIAL')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Amount Paid: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          onAmountPaidChanged(double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
