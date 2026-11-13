import 'package:flutter/material.dart';
import '../../../../services/admin_staff_service.dart';
import 'admin_form_fields.dart';

class Step05StaffPermissionsSection extends StatelessWidget {
  final bool loadingStaff;
  final String? assignedManager;
  final ValueChanged<String?> onAssignedManagerChanged;
  final List<RestaurantStaffUser> availableStaff;
  final List<String> assignedStaff;
  final ValueChanged<String> onToggleStaff;
  final TextEditingController maxDiscountLimitCtrl;
  final TextEditingController maxRefundLimitCtrl;
  final bool allowMultiOutletAccess;
  final ValueChanged<bool> onAllowMultiOutletAccessChanged;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const Step05StaffPermissionsSection({
    super.key,
    required this.loadingStaff,
    required this.assignedManager,
    required this.onAssignedManagerChanged,
    required this.availableStaff,
    required this.assignedStaff,
    required this.onToggleStaff,
    required this.maxDiscountLimitCtrl,
    required this.maxRefundLimitCtrl,
    required this.allowMultiOutletAccess,
    required this.onAllowMultiOutletAccessChanged,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFormFieldWidgets.buildSectionHeader(
            '05. Staff & Permissions',
            'Assign outlet manager, cashier floor access & discount limits',
            Icons.badge_rounded,
          ),
          const SizedBox(height: 16),
          if (loadingStaff)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<String>(
              initialValue: assignedManager,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Assign Outlet Manager',
                prefixIcon: const Icon(Icons.manage_accounts_rounded, size: 20),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    'No Manager Assigned Yet',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                ...availableStaff.map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(
                        '${u.name} (${u.role.toUpperCase()})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    )),
              ],
              selectedItemBuilder: (context) {
                return [
                  const Text(
                    'No Manager Assigned Yet',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  ...availableStaff.map((u) => Text(
                        '${u.name} (${u.role.toUpperCase()})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      )),
                ];
              },
              onChanged: onAssignedManagerChanged,
            ),
            const SizedBox(height: 18),
            Text(
              'Assign Floor Staff Accounts (${availableStaff.length} available)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: availableStaff.isEmpty
                  ? Center(
                      child: Text(
                        'No staff members provisioned yet.',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableStaff.length,
                      itemBuilder: (context, i) {
                        final staff = availableStaff[i];
                        final isSelected = assignedStaff.contains(staff.id);
                        return Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            dense: true,
                            title: Text(
                              staff.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                            ),
                            subtitle: Text(
                              '${staff.username} • Role: ${staff.role.toUpperCase()}',
                              style: TextStyle(fontSize: 10.5, color: subtitleColor),
                            ),
                            value: isSelected,
                            activeColor: const Color(0xFF6366F1),
                            onChanged: (_) => onToggleStaff(staff.id),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AdminFormFieldWidgets.buildTextField(
                    controller: maxDiscountLimitCtrl,
                    label: 'Max Cashier Discount Limit (%)',
                    hint: '20',
                    icon: Icons.percent_rounded,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AdminFormFieldWidgets.buildTextField(
                    controller: maxRefundLimitCtrl,
                    label: 'Max Void / Refund Limit (₹)',
                    hint: '2000',
                    icon: Icons.currency_rupee_rounded,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow multi-outlet roaming access',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(
                  'When enabled, assigned staff can log in across other branches if permitted by HQ.',
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
                value: allowMultiOutletAccess,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: onAllowMultiOutletAccessChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
