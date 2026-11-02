import 'package:flutter/material.dart';
import 'customization_text_field.dart';

class ShopDetailsCard extends StatelessWidget {
  final TextEditingController shopNameCtrl;
  final TextEditingController taglineCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController landlineCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController gstCtrl;
  final TextEditingController fssaiCtrl;
  final String outletType;
  final ValueChanged<String?>? onOutletTypeChanged;
  final TextEditingController? openingTimeCtrl;
  final TextEditingController? closingTimeCtrl;

  const ShopDetailsCard({
    super.key,
    required this.shopNameCtrl,
    required this.taglineCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.landlineCtrl,
    required this.emailCtrl,
    required this.gstCtrl,
    required this.fssaiCtrl,
    this.outletType = 'Dine-in, Takeaway & Delivery',
    this.onOutletTypeChanged,
    this.openingTimeCtrl,
    this.closingTimeCtrl,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Restaurant & Outlet Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Admin Synced',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomizationTextField(
              label: 'Restaurant / Outlet Name *',
              controller: shopNameCtrl,
            ),
            const SizedBox(height: 12),
            CustomizationTextField(
              label: 'Tagline / Slogan (e.g. Authentic Flavors & Fast Dining)',
              controller: taglineCtrl,
            ),
            const SizedBox(height: 12),
            if (onOutletTypeChanged != null) ...[
              DropdownButtonFormField<String>(
                initialValue: outletType,
                decoration: InputDecoration(
                  labelText: 'Outlet Operation Format',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Dine-in, Takeaway & Delivery', child: Text('Dine-in, Takeaway & Delivery')),
                  DropdownMenuItem(value: 'Quick Service / Fast Food (QSR)', child: Text('Quick Service / Fast Food (QSR)')),
                  DropdownMenuItem(value: 'Fine Dining Restaurant', child: Text('Fine Dining Restaurant')),
                  DropdownMenuItem(value: 'Cafe & Bakery', child: Text('Cafe & Bakery')),
                  DropdownMenuItem(value: 'Cloud Kitchen (Delivery Only)', child: Text('Cloud Kitchen (Delivery Only)')),
                ],
                onChanged: onOutletTypeChanged,
              ),
              const SizedBox(height: 12),
            ],
            CustomizationTextField(
              label: 'Restaurant Address / Location',
              controller: addressCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomizationTextField(
                    label: 'Primary Phone *',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomizationTextField(
                    label: 'Landline / Alternate Phone',
                    controller: landlineCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomizationTextField(
                    label: 'Email Address',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomizationTextField(
                    label: 'GSTIN Number (15 Digits)',
                    controller: gstCtrl,
                    maxLength: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomizationTextField(
                    label: 'FSSAI License Number (Food Safety 14 Digits)',
                    controller: fssaiCtrl,
                    maxLength: 14,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (openingTimeCtrl != null && closingTimeCtrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomizationTextField(
                      label: 'Opening Hours (e.g. 10:00 AM)',
                      controller: openingTimeCtrl!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomizationTextField(
                      label: 'Closing Hours (e.g. 11:00 PM)',
                      controller: closingTimeCtrl!,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
