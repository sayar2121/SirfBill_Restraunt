import 'package:flutter/material.dart';
import '../../../../services/transaction_service.dart';

void showAddTransactionDialog(
  BuildContext context, {
  String defaultType = 'Income',
  required VoidCallback onSuccess,
}) {
  final typeCtrl = TextEditingController(text: defaultType);
  final categoryCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final paymentModeCtrl = TextEditingController(text: 'Cash');

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFF0369A1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: typeCtrl.text,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Income', 'Expense']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) =>
                    setStateDialog(() => typeCtrl.text = val!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category (e.g. Sales, Rent)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: paymentModeCtrl.text,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                items: ['Cash', 'Bank Transfer', 'UPI', 'Card']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) =>
                    setStateDialog(() => paymentModeCtrl.text = val!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (amountCtrl.text.isEmpty ||
                          categoryCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter amount and category'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final payload = {
                        "date": now.toIso8601String(),
                        "amount": double.tryParse(amountCtrl.text) ?? 0.0,
                        "transaction_type": typeCtrl.text.toUpperCase(),
                        "description": descriptionCtrl.text,
                        "category_name": categoryCtrl.text,
                        "category": categoryCtrl.text,
                        "payment_mode": paymentModeCtrl.text,
                      };

                      try {
                        await TransactionService.saveTransaction(payload);
                        if (context.mounted) {
                          Navigator.pop(context);
                          onSuccess();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
