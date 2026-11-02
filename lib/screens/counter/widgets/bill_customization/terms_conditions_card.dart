import 'package:flutter/material.dart';
import 'customization_text_field.dart';

class TermsConditionsCard extends StatelessWidget {
  final TextEditingController terms1Ctrl;
  final TextEditingController terms2Ctrl;
  final TextEditingController terms3Ctrl;

  const TermsConditionsCard({
    super.key,
    required this.terms1Ctrl,
    required this.terms2Ctrl,
    required this.terms3Ctrl,
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
              'Terms & Conditions (Footer)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            CustomizationTextField(
              label: 'Term 1',
              controller: terms1Ctrl,
            ),
            CustomizationTextField(
              label: 'Term 2',
              controller: terms2Ctrl,
            ),
            CustomizationTextField(
              label: 'Term 3',
              controller: terms3Ctrl,
            ),
          ],
        ),
      ),
    );
  }
}
