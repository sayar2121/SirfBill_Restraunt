import 'package:flutter/material.dart';

import 'bank_details_card.dart';
import 'media_upload_card.dart';
import 'shop_details_card.dart';
import 'terms_conditions_card.dart';

/// Form tab views (Restaurant details, bank/UPI accounts, terms & conditions, media upload)
class BillCustomizationForms extends StatelessWidget {
  final bool isDark;
  final bool isDesktop;
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
  final TextEditingController bankNameCtrl;
  final TextEditingController branchNameCtrl;
  final TextEditingController acHolderCtrl;
  final TextEditingController acNumberCtrl;
  final TextEditingController ifscCtrl;
  final TextEditingController upiIdCtrl;
  final TextEditingController terms1Ctrl;
  final TextEditingController terms2Ctrl;
  final TextEditingController terms3Ctrl;
  final String? logoUrl;
  final String? qrUrl;
  final VoidCallback onPickLogo;
  final VoidCallback onPickQr;
  final VoidCallback onClearLogo;
  final VoidCallback onClearQr;
  final Widget? rightPane;

  const BillCustomizationForms({
    super.key,
    required this.isDark,
    required this.isDesktop,
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
    required this.bankNameCtrl,
    required this.branchNameCtrl,
    required this.acHolderCtrl,
    required this.acNumberCtrl,
    required this.ifscCtrl,
    required this.upiIdCtrl,
    required this.terms1Ctrl,
    required this.terms2Ctrl,
    required this.terms3Ctrl,
    required this.logoUrl,
    required this.qrUrl,
    required this.onPickLogo,
    required this.onPickQr,
    required this.onClearLogo,
    required this.onClearQr,
    this.rightPane,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: isDesktop ? 2 : 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              isScrollable: !isDesktop,
              tabAlignment: !isDesktop ? TabAlignment.start : TabAlignment.fill,
              labelColor: isDark ? Colors.green[400] : const Color(0xFF166534),
              unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              indicatorColor: const Color(0xFF22C55E),
              tabs: [
                const Tab(text: 'Restaurant Details'),
                const Tab(text: 'Bill Customization'),
                if (!isDesktop) const Tab(text: 'Live Preview'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ShopDetailsCard(
                        shopNameCtrl: shopNameCtrl,
                        taglineCtrl: taglineCtrl,
                        addressCtrl: addressCtrl,
                        phoneCtrl: phoneCtrl,
                        landlineCtrl: landlineCtrl,
                        emailCtrl: emailCtrl,
                        gstCtrl: gstCtrl,
                        fssaiCtrl: fssaiCtrl,
                        outletType: outletType,
                        onOutletTypeChanged: onOutletTypeChanged,
                        openingTimeCtrl: openingTimeCtrl,
                        closingTimeCtrl: closingTimeCtrl,
                      ),
                      const SizedBox(height: 16),
                      BankDetailsCard(
                        bankNameCtrl: bankNameCtrl,
                        branchNameCtrl: branchNameCtrl,
                        acHolderCtrl: acHolderCtrl,
                        acNumberCtrl: acNumberCtrl,
                        ifscCtrl: ifscCtrl,
                        upiIdCtrl: upiIdCtrl,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      TermsConditionsCard(
                        terms1Ctrl: terms1Ctrl,
                        terms2Ctrl: terms2Ctrl,
                        terms3Ctrl: terms3Ctrl,
                      ),
                      const SizedBox(height: 16),
                      MediaUploadCard(
                        logoUrl: logoUrl,
                        qrUrl: qrUrl,
                        onPickLogo: onPickLogo,
                        onPickQr: onPickQr,
                        onClearLogo: onClearLogo,
                        onClearQr: onClearQr,
                      ),
                    ],
                  ),
                ),
                if (!isDesktop && rightPane != null) rightPane!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
