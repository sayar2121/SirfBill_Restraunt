import 'package:flutter/material.dart';

class PurchaseActionsBar extends StatelessWidget {
  final TextEditingController invoiceController;
  final bool isLoading;
  final VoidCallback onAddNewItem;
  final VoidCallback onConfirmPurchase;

  const PurchaseActionsBar({
    super.key,
    required this.invoiceController,
    required this.isLoading,
    required this.onAddNewItem,
    required this.onConfirmPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onAddNewItem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF166534),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            controller: invoiceController,
            decoration: const InputDecoration(
              hintText: 'Auto Gen',
              labelText: 'Invoice Number',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onConfirmPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF166534),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Confirm Purchase',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
