import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_summary_widget.dart';
import 'billing_customer_section.dart';
import 'billing_cart_table.dart';
import '../../../../providers/billing_provider.dart';


class BillingRightPanel extends ConsumerWidget {
  final bool hasEnoughHeight;
  final TextEditingController discountController;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerLocationController;

  final VoidCallback onClearCart;
  final Function(int) onDecreaseQty;
  final Function(int) onIncreaseQty;
  final Function(int) onRemoveItem;
  final VoidCallback onSaveCustomerToDb;
  final VoidCallback onSaveDraft;
  final VoidCallback onShowDraftsDialog;
  final VoidCallback onShowBillPreview;
  final VoidCallback onGenerateBill;
  final Widget customerSearchField;
  final bool isGeneratingBill;
  const BillingRightPanel({
    super.key,
    required this.hasEnoughHeight,
    required this.discountController,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.customerLocationController,
    required this.onClearCart,
    required this.onDecreaseQty,
    required this.onIncreaseQty,
    required this.onRemoveItem,
    required this.onSaveCustomerToDb,
    required this.onSaveDraft,
    required this.onShowDraftsDialog,
    required this.onShowBillPreview,
    required this.onGenerateBill,
    required this.customerSearchField,
    required this.isGeneratingBill,
    required this.onUpdateItemDiscount,
  });

  final Function(int, double) onUpdateItemDiscount;




  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);
    final notifier = ref.read(billingProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView(
        shrinkWrap: !hasEnoughHeight,
        physics: hasEnoughHeight
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Bill',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                InkWell(
                  onTap: onClearCart,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          BillingCartTable(
            billingState: billingState,
            notifier: notifier,
            onIncreaseQty: onIncreaseQty,
            onDecreaseQty: onDecreaseQty,
            onRemoveItem: onRemoveItem,
            onUpdateItemDiscount: onUpdateItemDiscount,
          ),
          BillingCustomerSection(
            billingState: billingState,
            notifier: notifier,
            onSaveCustomerToDb: onSaveCustomerToDb,
            customerSearchField: customerSearchField,
            customerNameController: customerNameController,
            customerPhoneController: customerPhoneController,
            customerLocationController: customerLocationController,
          ),
          BillingSummaryWidget(
            billingState: billingState,
            notifier: notifier,
            discountController: discountController,
            onSaveCustomerToDb: onSaveCustomerToDb,
            onSaveDraft: onSaveDraft,
            onShowDraftsDialog: onShowDraftsDialog,
            onShowBillPreview: onShowBillPreview,
            onGenerateBill: onGenerateBill,
            isGeneratingBill: isGeneratingBill,
          ),
        ],
      ),
    );
  }
}
