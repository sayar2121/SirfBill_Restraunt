import 'package:flutter/material.dart';
import 'upload_form_fields.dart';

class AdditionalInfoCard extends StatelessWidget {
  final TextEditingController skuCtrl;

  const AdditionalInfoCard({
    super.key,
    required this.skuCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UploadFormFieldWidgets.buildSectionHeader(
            context,
            Icons.description,
            'Additional Information',
            'Optional details',
          ),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              flex: 1,
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Barcode / SKU',
                'Scan or enter barcode',
                suffixIcon: Icons.qr_code_scanner,
                controller: skuCtrl,
              ),
            ),
            const Spacer(),
          ]),
        ],
      ),
    );
  }
}
