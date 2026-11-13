import 'package:flutter/material.dart';
import '../../../../services/account_service.dart';
import '../../../../services/purchase_service.dart';

/// Helper and dialog to handle paying purchase bills directly from Accounts section.
class PayPurchaseBillDialog {
  static final PurchaseService _purchaseService = PurchaseService();

  static String _fmt(double amt) => '₹${amt.toStringAsFixed(2)}';

  /// Performs account funds validation, prompts account selection, and settles the bill.
  static Future<bool> handlePay({
    required BuildContext context,
    required Map<String, dynamic> item,
  }) async {
    final amountOwed = (item['amount_owed'] as num?)?.toDouble() ?? 0.0;
    final billId = item['bill_id']?.toString() ?? item['id']?.toString();
    final supplierName = item['entity_name']?.toString() ?? 'Supplier';
    final invoiceNo = item['invoice_no']?.toString() ?? 'N/A';

    // Fetch accounts to check current funds
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

    // If there is NO money or insufficient money in the accounts section
    if (assetAccounts.isEmpty || totalFunds < amountOwed) {
      if (!context.mounted) return false;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 52,
          ),
          title: const Text(
            'No Money in Accounts Section',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Supplier:'),
                        Flexible(
                          child: Text(
                            supplierName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Invoice:'),
                        Text(
                          invoiceNo,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Required:'),
                        Text(
                          _fmt(amountOwed),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Available in Accounts:'),
                        Text(
                          _fmt(totalFunds),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shortage:'),
                        Text(
                          _fmt((amountOwed - totalFunds).clamp(0.0, double.infinity)),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Please deposit money into your Cash or Bank account in the Accounts section before marking this purchase bill as paid.',
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
      return false;
    }

    // If billId is null (general transaction payable rather than direct purchase bill)
    if (billId == null || billId.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot pay directly: No purchase bill linked to this payable.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Accounts with enough balance
    AccountModel selectedAccount = assetAccounts.firstWhere(
      (a) => a.balance >= amountOwed,
      orElse: () => assetAccounts.first,
    );

    if (!context.mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Pay Purchase Bill',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay ${_fmt(amountOwed)} to $supplierName?'),
              const SizedBox(height: 8),
              Text(
                'Invoice: $invoiceNo',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deduct From Account:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<AccountModel>(
                initialValue: selectedAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: assetAccounts.map((acc) {
                  final hasEnough = acc.balance >= amountOwed;
                  return DropdownMenuItem<AccountModel>(
                    value: acc,
                    child: Text(
                      '${acc.name} (${_fmt(acc.balance)})${!hasEnough ? ' - Low Balance' : ''}',
                      style: TextStyle(
                        color: hasEnough ? null : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedAccount = val);
                  }
                },
              ),
              if (selectedAccount.balance < amountOwed) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ ${selectedAccount.name} only has ${_fmt(selectedAccount.balance)}. Please select an account with at least ${_fmt(amountOwed)}.',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedAccount.balance >= amountOwed
                    ? const Color(0xFF166534)
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedAccount.balance >= amountOwed
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Confirm & Pay'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _purchaseService.markBillAsPaid(
          billId,
          accountId: selectedAccount.id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchase bill marked as PAID! Deducted ${_fmt(amountOwed)} from ${selectedAccount.name}.',
              ),
              backgroundColor: Colors.green,
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
    return false;
  }
}
