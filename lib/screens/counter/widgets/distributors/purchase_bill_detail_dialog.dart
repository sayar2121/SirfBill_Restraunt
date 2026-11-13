import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api_constants.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../services/account_service.dart';

/// Modal dialog displaying full itemized breakdown of a purchase bill with payment settlement.
class PurchaseBillDetailDialog extends ConsumerWidget {
  final Map<String, dynamic> bill;

  const PurchaseBillDetailDialog({super.key, required this.bill});

  static Future<void> show(BuildContext context, Map<String, dynamic> bill) {
    return showDialog(
      context: context,
      builder: (context) => PurchaseBillDetailDialog(bill: bill),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = (bill['items'] as List<dynamic>?) ?? [];
    final inventoryList = ref.watch(inventoryProvider).value ?? [];

    final isPaid = bill['payment_status'] == 'PAID';

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Invoice: ${bill['invoice_no'] ?? 'N/A'}'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bill['payment_status'] ?? 'UNPAID',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${bill['bill_date']?.toString().split('T')[0] ?? 'N/A'}',
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final invItem = inventoryList.where((i) => i.id == item['inventory_item_id']).firstOrNull;
                    final itemName = invItem != null ? invItem.name : 'Unknown Item (${item['inventory_item_id']})';

                    return ListTile(
                      title: Text(itemName),
                      subtitle: Text(
                          'Qty: ${item['quantity']} • Batch: ${item['batch_number'] ?? 'N/A'} • Exp: ${item['expiry_date'] ?? 'N/A'}'),
                      trailing: Text('₹${item['unit_price'] ?? 0.0}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final totalAmount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
                final subtotal = (bill['subtotal'] as num?)?.toDouble() ?? 0.0;
                final totalGst = (bill['total_gst'] as num?)?.toDouble() ?? 0.0;
                final totalDiscount = (bill['total_discount'] as num?)?.toDouble() ?? 0.0;
                final billTotal = totalAmount > 0 ? totalAmount : (subtotal + totalGst - totalDiscount);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Text('₹${billTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Generate PDF'),
          onPressed: () async {
            final billId = bill['id'];
            if (billId != null) {
              final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/purchases/$billId/pdf');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          },
        ),
        if (!isPaid)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
            onPressed: () => _handleMarkAsPaid(context, ref),
            child: const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }

  Future<void> _handleMarkAsPaid(BuildContext context, WidgetRef ref) async {
    final billTotal = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
    final amountPaid = (bill['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final dueAmount = (billTotal - amountPaid) > 0 ? (billTotal - amountPaid) : billTotal;

    List<AccountModel> accounts = [];
    try {
      accounts = await AccountService.getAccounts();
    } catch (_) {}

    final assetAccounts = accounts.where((a) => a.accountType.toUpperCase() == 'ASSET').toList();
    final totalFunds = assetAccounts.fold<double>(0.0, (sum, acc) => sum + acc.balance);

    if (assetAccounts.isEmpty || totalFunds < dueAmount) {
      if (context.mounted) {
        showDialog(
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
                  'There is not enough money in the accounts section to pay this purchase bill.',
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
                          const Text('Bill Due Amount:'),
                          Text('₹${dueAmount.toStringAsFixed(2)}',
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
                          Text('₹${(dueAmount - totalFunds).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please deposit money into Accounts first before marking this purchase bill as paid.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      final svc = ref.read(purchaseServiceProvider);
      await svc.markBillAsPaid(bill['id']);

      ref.invalidate(purchaseBillsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(historyProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bill marked as PAID! Deducted from Accounts.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: const Text('Payment Failed'),
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
    }
  }
}
