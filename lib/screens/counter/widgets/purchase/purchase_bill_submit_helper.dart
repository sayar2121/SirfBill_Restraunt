import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api_constants.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../services/account_service.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/purchase_service.dart';

/// Helper class handling funds validation, account deduction, and bill submission.
class PurchaseBillSubmitHelper {
  static final PurchaseService _purchaseService = PurchaseService();

  /// Validates available account balance and submits the purchase bill.
  static Future<bool> submitPurchaseBill({
    required BuildContext context,
    required WidgetRef ref,
    required String distributorId,
    required String invoiceNo,
    required String paymentStatus,
    required double amountPaid,
    required double grandTotal,
    required double subtotal,
    required double totalDiscount,
    required double totalGst,
    required List<Map<String, dynamic>> items,
    required VoidCallback onPaymentStatusChangedToUnpaid,
  }) async {
    if (items.isEmpty) return false;

    try {
      final effectivePaid = paymentStatus == 'UNPAID'
          ? 0.0
          : (paymentStatus == 'PAID' ? grandTotal : amountPaid);

      // 1. Account Funds Check for non-credit bills
      if (paymentStatus == 'PAID' || (paymentStatus == 'PARTIAL' && effectivePaid > 0)) {
        List<AccountModel> accounts = [];
        try {
          accounts = await AccountService.getAccounts();
        } catch (_) {}

        final assetAccounts = accounts
            .where((a) => a.accountType.toUpperCase() == 'ASSET')
            .toList();
        final totalFunds = assetAccounts.fold<double>(
          0.0,
          (sum, acc) => sum + acc.balance,
        );

        if (assetAccounts.isEmpty || totalFunds < effectivePaid) {
          if (context.mounted) {
            final shouldChangeToUnpaid = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 52),
                title: const Text('No Money in Accounts Section', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'There is not enough money in the accounts section to pay for this purchase bill.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount to Pay:'),
                              Text('₹${effectivePaid.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Available in Accounts:'),
                              Text('₹${totalFunds.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Shortage:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '₹${(effectivePaid - totalFunds).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Would you like to save this bill as UNPAID (Credit) instead, or cancel and add money in Accounts?',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save as UNPAID (Credit)'),
                  ),
                ],
              ),
            );

            if (shouldChangeToUnpaid == true) {
              onPaymentStatusChangedToUnpaid();
              return await submitPurchaseBill(
                // ignore: use_build_context_synchronously
                context: context,
                ref: ref,
                distributorId: distributorId,
                invoiceNo: invoiceNo,
                paymentStatus: 'UNPAID',
                amountPaid: 0.0,
                grandTotal: grandTotal,
                subtotal: subtotal,
                totalDiscount: totalDiscount,
                totalGst: totalGst,
                items: items,
                onPaymentStatusChangedToUnpaid: onPaymentStatusChangedToUnpaid,
              );
            }
          }
          return false;
        }
      }

      // 2. Build and Dispatch Bill Payload
      final shopId = await InventoryService.getShopId();
      final billData = {
        'shop_id': shopId,
        'distributor_id': distributorId,
        'invoice_no': invoiceNo.isNotEmpty ? invoiceNo : null,
        'payment_status': paymentStatus,
        'bill_date': DateTime.now().toIso8601String().split('T')[0],
        'total_amount': grandTotal,
        'subtotal': subtotal,
        'total_discount': totalDiscount,
        'total_gst': totalGst,
        'amount_paid': effectivePaid,
        'items': items
            .map((i) => {
                  'inventory_item_id': i['inventory_item_id'],
                  'quantity': i['quantity'],
                  'unit_price': i['buying_price'],
                  'selling_price': i['selling_price'],
                  'batch_number': i['batch_number'],
                  'expiry_date': i['expiry_date'] != '' ? i['expiry_date'] : null,
                  'hsn_code': i['hsn_code'] != '' ? i['hsn_code'] : null,
                  'gst': i['gst'],
                  'rack_id': i['rack_id'],
                  'category_id': i['category_id'],
                })
            .toList(),
      };

      final response = await _purchaseService.createPurchaseBill(billData);
      final billId = response['id'];

      ref.invalidate(inventoryProvider);
      ref.invalidate(purchaseInventoryProvider);
      ref.invalidate(purchaseBillsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(historyProvider);

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Purchase Success'),
            content: const Text('Purchase bill created and stock updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Generate Bill (PDF)'),
                onPressed: () async {
                  final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/purchases/$billId/pdf');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: const Text('Purchase Creation Failed'),
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return false;
    }
  }
}
