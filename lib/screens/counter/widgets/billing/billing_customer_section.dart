import 'package:flutter/material.dart';
import '../../../../notifiers/billing_notifier.dart';

class BillingCustomerSection extends StatelessWidget {
  final BillingState billingState;
  final BillingNotifier notifier;
  final Widget customerSearchField;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerLocationController;
  final VoidCallback onSaveCustomerToDb;

  const BillingCustomerSection({
    super.key,
    required this.billingState,
    required this.notifier,
    required this.customerSearchField,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.customerLocationController,
    required this.onSaveCustomerToDb,
  });

Widget _buildCompactField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool isNumber = false,
  String? hint,
  Function(String)? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 32,
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return       // Customer Details
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Color(0xFF166534),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Customer Details (Optional)',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Color(0xFF166534),
                    size: 16,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  customerSearchField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactField(
                          context,
                          'Name',
                          customerNameController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactField(
                          context,
                          'Phone',
                          customerPhoneController,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCompactField(
                    context,
                    'Location / Address',
                    customerLocationController,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onSaveCustomerToDb,
                      icon: const Icon(
                        Icons.person_add,
                        size: 14,
                        color: Color(0xFF22C55E),
                      ),
                      label: const Text(
                        'Save to DB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        backgroundColor: const Color(0xFFDCFCE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
