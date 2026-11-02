import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../services/account_service.dart';
import '../../../../services/accounting_extended_service.dart';
import '../../../../services/purchase_service.dart';

class PayablesView extends ConsumerStatefulWidget {
  const PayablesView({super.key});

  @override
  ConsumerState<PayablesView> createState() => _PayablesViewState();
}

class _PayablesViewState extends ConsumerState<PayablesView> {
  bool _isLoading = true;
  List<dynamic> _payables = [];
  double _totalPayables = 0.0;
  final PurchaseService _purchaseService = PurchaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AccountingExtendedService.getPayables();
    if (mounted) {
      setState(() {
        _payables = data['payables'] ?? [];
        _totalPayables = (data['total_payables'] as num?)?.toDouble() ?? 0.0;
        _isLoading = false;
      });
    }
  }

  String _fmt(double amt) => '₹${amt.toStringAsFixed(2)}';

  Future<void> _handlePay(Map<String, dynamic> item) async {
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
      if (!mounted) return;
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
                        const Text(
                          'Shortage:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
      return;
    }

    // If billId is null (general transaction payable rather than direct purchase bill)
    if (billId == null || billId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot pay directly: No purchase bill linked to this payable.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Accounts with enough balance
    AccountModel selectedAccount = assetAccounts.firstWhere(
      (a) => a.balance >= amountOwed,
      orElse: () => assetAccounts.first,
    );

    if (!mounted) return;
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
        setState(() => _isLoading = true);
        await _purchaseService.markBillAsPaid(
          billId,
          accountId: selectedAccount.id,
        );

        // Refresh UI
        ref.invalidate(accountsProvider);
        ref.invalidate(purchaseBillsProvider);
        ref.invalidate(historyProvider);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchase bill marked as PAID! Deducted ${_fmt(amountOwed)} from ${selectedAccount.name}.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.transparent,
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Supplier / Bill',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount Owed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        _payables.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No outstanding payables!',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _payables.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                itemBuilder: (context, index) {
                  final item = _payables[index] as Map<String, dynamic>;
                  final supplierName = item['entity_name']?.toString() ?? 'Unknown';
                  final invoiceNo = item['invoice_no']?.toString();
                  final amountOwed = (item['amount_owed'] as num?)?.toDouble() ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF3B0764)
                                    : const Color(0xFFF3E8FF),
                                child: Text(
                                  supplierName.isNotEmpty
                                      ? supplierName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFFC084FC)
                                        : const Color(0xFF7E22CE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      supplierName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (invoiceNo != null && invoiceNo != 'N/A' && invoiceNo != '-')
                                      Text(
                                        'Invoice: $invoiceNo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt(amountOwed),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFB91C1C),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _handlePay(item),
                              icon: const Icon(Icons.payment, size: 14),
                              label: const Text(
                                'Pay',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF166534),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Payables: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : const Color(0xFF64748B),
                ),
              ),
              Text(
                _fmt(_totalPayables),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
