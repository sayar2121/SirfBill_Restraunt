import 'package:flutter/material.dart';
import 'customization_text_field.dart';

class BankDetailsCard extends StatelessWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController branchNameCtrl;
  final TextEditingController acHolderCtrl;
  final TextEditingController acNumberCtrl;
  final TextEditingController ifscCtrl;
  final TextEditingController upiIdCtrl;

  const BankDetailsCard({
    super.key,
    required this.bankNameCtrl,
    required this.branchNameCtrl,
    required this.acHolderCtrl,
    required this.acNumberCtrl,
    required this.ifscCtrl,
    required this.upiIdCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            CustomizationTextField(
              label: 'Bank Name',
              controller: bankNameCtrl,
            ),
            CustomizationTextField(
              label: 'Branch Name',
              controller: branchNameCtrl,
            ),
            CustomizationTextField(
              label: 'A/C Holder Name',
              controller: acHolderCtrl,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomizationTextField(
                    label: 'Account Number',
                    controller: acNumberCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomizationTextField(
                    label: 'IFSC Code',
                    controller: ifscCtrl,
                  ),
                ),
              ],
            ),
            CustomizationTextField(
              label: 'UPI ID (For Dynamic Payment QR)',
              controller: upiIdCtrl,
              hintText: 'e.g. 9876543210@paytm or shop@okhdfcbank',
            ),
          ],
        ),
      ),
    );
  }
}
