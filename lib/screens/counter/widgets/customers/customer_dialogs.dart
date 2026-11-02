import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';

import '../../../../services/customer_service.dart';

Widget buildModernTextField(BuildContext context, TextEditingController controller,
  String hint,
  IconData icon, {
  bool isNumber = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: TextStyle(fontSize: 14, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : AppColors.textHint), fontSize: 14),
      prefixIcon: Icon(icon, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : AppColors.textHint), size: 20),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}

void showAddCustomerDialog(BuildContext context, VoidCallback onCustomerAdded) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Add New Customer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            buildModernTextField(
              context,
              nameCtrl,
              'Customer Name',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            buildModernTextField(
              context,
              phoneCtrl,
              'Phone Number',
              Icons.phone_outlined,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            buildModernTextField(
              context,
              emailCtrl,
              'Email Address',
              Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            buildModernTextField(
              context,
              locationCtrl,
              'Location/City',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : AppColors.textSecondary),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
                    final newCust = Customer(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      email: emailCtrl.text,
                      location: locationCtrl.text,
                      isActive: true,
                    );
                    await CustomerService.saveCustomer(newCust);
                    if (context.mounted) {
                      Navigator.pop(context);
                      onCustomerAdded();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customer Added Successfully!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Customer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void showEditCustomerDialog(
  BuildContext context,
  Map<String, dynamic> customerMap,
  VoidCallback onCustomerUpdated,
) {
  final nameCtrl = TextEditingController(text: customerMap['name']);
  final phoneCtrl = TextEditingController(text: customerMap['phone']);
  final emailCtrl = TextEditingController(
    text: customerMap['email'] == 'N/A' ? '' : customerMap['email'],
  );
  final locationCtrl = TextEditingController(
    text: customerMap['city'] == 'Local' ? '' : customerMap['city'],
  );
  bool isActive = customerMap['status'] == 'Active';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Edit Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              buildModernTextField(
              context,
                nameCtrl,
                'Customer Name',
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              buildModernTextField(
              context,
                phoneCtrl,
                'Phone Number',
                Icons.phone_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              buildModernTextField(
              context,
                emailCtrl,
                'Email Address',
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              buildModernTextField(
              context,
                locationCtrl,
                'Location/City',
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (val) {
                      setDialogState(() {
                        isActive = val;
                      });
                    },
                    activeThumbColor: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : AppColors.textSecondary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }
                      final updatedCust = Customer(
                        id:
                            customerMap['full_id'] ??
                            customerMap['id'], // We need the full UUID to update
                        name: nameCtrl.text,
                        phone: phoneCtrl.text,
                        email: emailCtrl.text,
                        location: locationCtrl.text,
                        isActive: isActive,
                      );
                      try {
                        await CustomerService.updateCustomer(updatedCust);
                        if (context.mounted) {
                          Navigator.pop(context);
                          onCustomerUpdated();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer Updated Successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
