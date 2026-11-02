import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/category_dropdown.dart';
import '../../../../widgets/distributor_dropdown.dart';
import 'item_image_picker.dart';
import 'upload_form_fields.dart';

class BasicInfoCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController manufacturerCtrl;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final String? selectedDistributorId;
  final ValueChanged<String?> onDistributorChanged;
  final PlatformFile? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const BasicInfoCard({
    super.key,
    required this.nameCtrl,
    required this.manufacturerCtrl,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedDistributorId,
    required this.onDistributorChanged,
    required this.selectedImage,
    required this.onPickImage,
    required this.onRemoveImage,
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
            Icons.medication_liquid,
            'Basic Information',
            'General details about the item',
          ),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  UploadFormFieldWidgets.buildResponsiveRow(context, [
                    Expanded(
                      child: UploadFormFieldWidgets.buildTextField(
                        context,
                        'Item Name',
                        'e.g. Paracetamol 500mg',
                        isRequired: true,
                        controller: nameCtrl,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: UploadFormFieldWidgets.buildTextField(
                        context,
                        'Manufacturer',
                        'e.g. Sun Pharma',
                        controller: manufacturerCtrl,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: ItemImagePicker(
                selectedImage: selectedImage,
                onPickImage: onPickImage,
                onRemoveImage: onRemoveImage,
              ),
            ),
          ]),
          const SizedBox(height: 24),
          UploadFormFieldWidgets.buildResponsiveRow(context, [
            Expanded(
              child: UploadFormFieldWidgets.buildDropdownWrapper(
                context,
                'Category',
                CategoryDropdown(
                  selectedCategoryId: selectedCategoryId,
                  onChanged: onCategoryChanged,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: UploadFormFieldWidgets.buildDropdownWrapper(
                context,
                'Distributor',
                DistributorDropdown(
                  selectedDistributorId: selectedDistributorId,
                  onChanged: onDistributorChanged,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
