import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/transaction_service.dart';
import 'accounts_common_widgets.dart';

class AccountsRightPanel extends StatelessWidget {
  final double cashInHand;
  final double bankBalance;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final List<TransactionModel> recentTransactions;

  const AccountsRightPanel({
    super.key,
    required this.cashInHand,
    required this.bankBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.recentTransactions,
  });

  String _fmt(double val) =>
      NumberFormat.currency(symbol: '₹ ', decimalDigits: 2).format(val);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AccountsWidgets.buildRightCard(
          context,
          title: 'Account Summary',
          child: Column(
            children: [
              AccountsWidgets.buildSummaryRow(
                context,
                Icons.money,
                'Cash in Hand',
                _fmt(cashInHand),
                const Color(0xFF22C55E),
              ),
              AccountsWidgets.buildSummaryRow(
                context,
                Icons.account_balance,
                'Bank Balance',
                _fmt(bankBalance),
                const Color(0xFF3B82F6),
              ),
              AccountsWidgets.buildSummaryRow(
                context,
                Icons.credit_card,
                'Total Income',
                _fmt(totalIncome),
                const Color(0xFF1E293B),
              ),
              AccountsWidgets.buildSummaryRow(
                context,
                Icons.credit_score,
                'Total Expenses',
                _fmt(totalExpenses),
                const Color(0xFFEF4444),
              ),
              AccountsWidgets.buildSummaryRow(
                context,
                Icons.bar_chart,
                'Net Profit',
                _fmt(netProfit),
                const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AccountsWidgets.buildRightCard(
          context,
          title: 'Recent Activities',
          expandChild: false,
          child: recentTransactions.isEmpty
              ? const Center(
                  child: Text(
                    'No recent activities',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: recentTransactions
                      .take(5)
                      .map(
                        (txn) => AccountsWidgets.buildActivityItem(
                          context,
                          '${txn.type == 'Income' ? 'Payment received' : 'Payment sent'}: ${txn.category}',
                          _fmt(txn.amount),
                          '${txn.date} ${txn.time}',
                          txn.type == 'Income' ? Colors.green : Colors.red,
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
