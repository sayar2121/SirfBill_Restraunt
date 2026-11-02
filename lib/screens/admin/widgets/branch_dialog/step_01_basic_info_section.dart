import 'package:flutter/material.dart';
import '../../../../config/api_constants.dart';
import 'admin_form_fields.dart';

class Step01BasicInfoSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final String outletType;
  final ValueChanged<String?> onOutletTypeChanged;
  final String status;
  final ValueChanged<String?> onStatusChanged;
  final String tenantId;
  final TextEditingController descriptionCtrl;
  final Color textColor;
  final String? logoUrl;
  final VoidCallback onPickLogo;
  final VoidCallback onClearLogo;
  final bool? isUploadingLogo;

  const Step01BasicInfoSection({
    super.key,
    required this.nameCtrl,
    required this.codeCtrl,
    required this.outletType,
    required this.onOutletTypeChanged,
    required this.status,
    required this.onStatusChanged,
    required this.tenantId,
    required this.descriptionCtrl,
    required this.textColor,
    this.logoUrl,
    required this.onPickLogo,
    required this.onClearLogo,
    this.isUploadingLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploading = isUploadingLogo == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFormFieldWidgets.buildSectionHeader(
            '01. Basic Information',
            'Identify the branch, business classification, and brand logo',
            Icons.storefront_rounded,
          ),
          const SizedBox(height: 18),

          // OUTLET LOGO UPLOAD & BRANDING CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Preview Box
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: uploading
                            ? const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              )
                            : (logoUrl != null && logoUrl!.isNotEmpty)
                                ? Image.network(
                                    logoUrl!.startsWith('http://') || logoUrl!.startsWith('https://')
                                        ? logoUrl!
                                        : '${ApiConstants.baseUrl}${logoUrl!.startsWith('/') ? '' : '/'}$logoUrl',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_rounded,
                                      size: 32,
                                      color: Colors.amber,
                                    ),
                                  )
                                : Icon(
                                    Icons.restaurant_rounded,
                                    size: 36,
                                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                  ),
                      ),
                    ),
                    if (logoUrl != null && logoUrl!.isNotEmpty && !uploading)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: InkWell(
                          onTap: onClearLogo,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                // Text & Upload Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Restaurant / Branch Logo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Prints on Invoices & KOT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports PNG, JPG, or WEBP (Recommended: 500x500px, under 2MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            onPressed: uploading ? null : onPickLogo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 15),
                            label: Text(
                              uploading
                                  ? 'Uploading...'
                                  : (logoUrl != null && logoUrl!.isNotEmpty)
                                      ? 'Change Logo'
                                      : 'Upload Logo',
                            ),
                          ),
                          if (logoUrl != null && logoUrl!.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: uploading ? null : onClearLogo,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent, width: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 14),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: nameCtrl,
                  label: 'Outlet Name *',
                  hint: 'e.g. Main Branch / Downtown Central',
                  icon: Icons.store_mall_directory_rounded,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: codeCtrl,
                  label: 'Outlet Code *',
                  hint: 'e.g. OUT001',
                  icon: Icons.qr_code_rounded,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: outletType,
                  label: 'Outlet Type *',
                  items: const [
                    'Dine-in, Takeaway & Delivery',
                    'Dine-in Only',
                    'Takeaway & Delivery Counter',
                    'Cloud / Ghost Kitchen',
                    'Kiosk / Cafe',
                  ],
                  onChanged: onOutletTypeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: status,
                  label: 'Outlet Status *',
                  items: const ['Active', 'Inactive', 'Under Setup'],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AdminFormFieldWidgets.buildTextField(
            controller: TextEditingController(text: tenantId),
            label: 'Parent Company / Tenant ID',
            hint: 'Linked automatically to your SirfBill HQ account',
            icon: Icons.link_rounded,
            readOnly: true,
            textColor: textColor,
          ),
          const SizedBox(height: 14),
          AdminFormFieldWidgets.buildTextField(
            controller: descriptionCtrl,
            label: 'Branch Description',
            hint: 'e.g. Main city outlet with 2-floor dining, outdoor seating & bar',
            icon: Icons.notes_rounded,
            maxLines: 2,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
