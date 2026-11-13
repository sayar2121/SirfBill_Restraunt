import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../services/accounting_extended_service.dart';
import 'pay_purchase_bill_dialog.dart';
import 'payable_row_tile.dart';

class PayablesView extends ConsumerStatefulWidget {
  const PayablesView({super.key});

  @override
  ConsumerState<PayablesView> createState() => _PayablesViewState();
}

class _PayablesViewState extends ConsumerState<PayablesView> {
  bool _isLoading = true;
  List<dynamic> _payables = [];
  double _totalPayables = 0.0;

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
    final success = await PayPurchaseBillDialog.handlePay(
      context: context,
      item: item,
    );

    if (success && mounted) {
      ref.invalidate(accountsProvider);
      ref.invalidate(purchaseBillsProvider);
      ref.invalidate(historyProvider);
      await _loadData();
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
                  return PayableRowTile(
                    item: item,
                    onPay: () => _handlePay(item),
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
