import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_form_fields.dart';

class Step04BillingTaxSection extends StatelessWidget {
  final String gstStatus;
  final ValueChanged<String?> onGstStatusChanged;
  final TextEditingController gstinCtrl;
  final TextEditingController invoicePrefixCtrl;
  final TextEditingController billNumberFormatCtrl;
  final TextEditingController taxRateCtrl;
  final String rounding;
  final ValueChanged<String?> onRoundingChanged;
  final TextEditingController fssaiCtrl;
  final TextEditingController receiptFooterCtrl;
  final TextEditingController? upiIdCtrl;
  final TextEditingController? bankAccountNameCtrl;
  final TextEditingController? bankNameCtrl;
  final TextEditingController? bankAccountCtrl;
  final TextEditingController? bankIfscCtrl;
  final TextEditingController? bankBranchCtrl;
  final Color textColor;

  const Step04BillingTaxSection({
    super.key,
    required this.gstStatus,
    required this.onGstStatusChanged,
    required this.gstinCtrl,
    required this.invoicePrefixCtrl,
    required this.billNumberFormatCtrl,
    required this.taxRateCtrl,
    required this.rounding,
    required this.onRoundingChanged,
    required this.fssaiCtrl,
    required this.receiptFooterCtrl,
    this.upiIdCtrl,
    this.bankAccountNameCtrl,
    this.bankNameCtrl,
    this.bankAccountCtrl,
    this.bankIfscCtrl,
    this.bankBranchCtrl,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController effectiveUpi = upiIdCtrl ?? TextEditingController();
    final TextEditingController effectiveBankAccountName = bankAccountNameCtrl ?? TextEditingController();
    final TextEditingController effectiveBankName = bankNameCtrl ?? TextEditingController();
    final TextEditingController effectiveBankAccount = bankAccountCtrl ?? TextEditingController();
    final TextEditingController effectiveBankIfsc = bankIfscCtrl ?? TextEditingController();
    final TextEditingController effectiveBankBranch = bankBranchCtrl ?? TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFormFieldWidgets.buildSectionHeader(
            '04. Billing & Tax',
            'Invoice sequencing, GST registration & compliance headers',
            Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: gstStatus,
                  label: 'GST Registration Status',
                  items: const ['Registered (Regular)', 'Composition Scheme', 'Unregistered'],
                  onChanged: onGstStatusChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: gstinCtrl,
                  label: 'GSTIN (GST Number) * 15 Digits',
                  hint: '15-character GSTIN (e.g. 19AAAAA0000A1Z5)',
                  icon: Icons.credit_card_rounded,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: invoicePrefixCtrl,
                  label: 'Receipt / Invoice Prefix',
                  hint: 'e.g. MB / OUT1',
                  icon: Icons.title_rounded,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: billNumberFormatCtrl,
                  label: 'Bill Numbering Format',
                  hint: '{PREFIX}-{YYYY}-{0001}',
                  icon: Icons.format_list_numbered_rounded,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: taxRateCtrl,
                  label: 'Default Restaurant GST (%)',
                  hint: '5.0',
                  icon: Icons.percent_rounded,
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
                  value: rounding,
                  label: 'Default Rounding Rule',
                  items: const [
                    'Round to Nearest Rupee',
                    'Round Up to Next Rupee',
                    'No Rounding (Exact Paise)',
                  ],
                  onChanged: onRoundingChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: fssaiCtrl,
                  label: 'FSSAI Licence Number (14 Digits)',
                  hint: '14-digit licence (e.g. 12822019000123)',
                  icon: Icons.verified_user_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AdminFormFieldWidgets.buildTextField(
            controller: receiptFooterCtrl,
            label: 'Receipt Footer Note',
            hint: 'Message printed at the bottom of the customer bill',
            icon: Icons.short_text_rounded,
            maxLines: 2,
            textColor: textColor,
          ),
          const SizedBox(height: 20),

          // PAYMENT & BANK DETAILS SECTION
          AdminFormFieldWidgets.buildSectionHeader(
            'Settlement & Payment Details',
            'UPI ID for dynamic customer QR code & Bank account for settlements',
            Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveBankAccountName,
                  label: 'Account Holder Name',
                  hint: 'e.g. Gourmet Bistro Hospitality LLP',
                  icon: Icons.person_outline_rounded,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveUpi,
                  label: 'Outlet UPI ID / VPA *',
                  hint: 'e.g. restaurant@upi / 9876543210@paytm',
                  icon: Icons.qr_code_2_rounded,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveBankName,
                  label: 'Bank Name',
                  hint: 'e.g. HDFC Bank / State Bank of India',
                  icon: Icons.account_balance_outlined,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveBankAccount,
                  label: 'Bank Account Number',
                  hint: 'e.g. 50100234567890',
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveBankIfsc,
                  label: 'Bank IFSC Code',
                  hint: 'e.g. HDFC0001234',
                  icon: Icons.code_rounded,
                  textCapitalization: TextCapitalization.characters,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: effectiveBankBranch,
                  label: 'Bank Branch',
                  hint: 'e.g. Park Street Branch',
                  icon: Icons.location_on_outlined,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
