import 'package:flutter/material.dart';
import '../../../../providers/restaurant_pos_provider.dart';

class DiscountDialog extends StatefulWidget {
  final RestaurantPosNotifier notifier;

  const DiscountDialog({
    super.key,
    required this.notifier,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  double _discountPercent = 10.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Discount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Row(
        children: [
          const Text('Discount: '),
          DropdownButton<double>(
            value: _discountPercent,
            items: const [
              DropdownMenuItem(value: 5.0, child: Text('5%')),
              DropdownMenuItem(value: 10.0, child: Text('10%')),
              DropdownMenuItem(value: 15.0, child: Text('15%')),
              DropdownMenuItem(value: 20.0, child: Text('20%')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _discountPercent = v);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.notifier.setDiscount(_discountPercent);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
