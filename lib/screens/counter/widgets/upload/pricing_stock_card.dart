import 'package:flutter/material.dart';
import '../../../../widgets/rack_dropdown.dart';
import 'upload_form_fields.dart';

class PricingStockCard extends StatelessWidget {
  final TextEditingController buyingPriceCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController packSizeCtrl;
  final TextEditingController looseStockCtrl;
  final TextEditingController gstCtrl;
  final TextEditingController discountCtrl;
  final String? selectedRackId;
  final ValueChanged<String?> onRackChanged;
  final TextEditingController expiryCtrl;
  final TextEditingController hsnCtrl;

  const PricingStockCard({
    super.key,
    required this.buyingPriceCtrl,
    required this.priceCtrl,
    required this.stockCtrl,
    required this.packSizeCtrl,
    required this.looseStockCtrl,
    required this.gstCtrl,
    required this.discountCtrl,
    required this.selectedRackId,
    required this.onRackChanged,
    required this.expiryCtrl,
    required this.hsnCtrl,
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
            Icons.currency_rupee,
            'Pricing & Stock Details',
            'Set pricing and stock information',
          ),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Buying Price (₹)',
                '0.00',
                isRequired: true,
                controller: buyingPriceCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Selling Price/MRP (₹)',
                '0.00',
                isRequired: true,
                controller: priceCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Initial Stock (Packs)',
                '0',
                controller: stockCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Pieces/Pack',
                '1',
                controller: packSizeCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Loose Stock (Pieces)',
                '0',
                controller: looseStockCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'GST (%)',
                '0',
                controller: gstCtrl,
              ),
            ),
          ]),
          const SizedBox(height: 24),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Discount (%)',
                '0',
                controller: discountCtrl,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildDropdownWrapper(
                context,
                'Rack / Location',
                RackDropdown(
                  selectedRackId: selectedRackId,
                  onChanged: onRackChanged,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'Expiry Date',
                'yyyy-mm-dd (Optional)',
                suffixIcon: Icons.calendar_today,
                controller: expiryCtrl,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    expiryCtrl.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildTextField(
                context,
                'HSN Code',
                'e.g. 3004',
                controller: hsnCtrl,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
