import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'accounts_common_widgets.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';

class AccountsSummaryCards extends StatefulWidget {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double outstandingReceivables;

  const AccountsSummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.outstandingReceivables,
  });

  @override
  State<AccountsSummaryCards> createState() => _AccountsSummaryCardsState();
}

class _AccountsSummaryCardsState extends State<AccountsSummaryCards> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _fmt(double val) =>
      NumberFormat.currency(symbol: '₹ ', decimalDigits: 2).format(val);

  @override
  Widget build(BuildContext context) {
    return HorizontalMouseTouchpadScroll(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          children: [
            SizedBox(
              width: 250,
              child: AccountsWidgets.buildStatCard(
                context,
                'Total Income',
                _fmt(widget.totalIncome),
                Icons.currency_rupee,
                const Color(0xFFDCFCE7),
                const Color(0xFF166534),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: AccountsWidgets.buildStatCard(
                context,
                'Total Expenses',
                _fmt(widget.totalExpenses),
                Icons.credit_card,
                const Color(0xFFFEE2E2),
                const Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: AccountsWidgets.buildStatCard(
                context,
                'Net Profit',
                _fmt(widget.netProfit),
                Icons.bar_chart,
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: AccountsWidgets.buildStatCard(
                context,
                'Outstanding Receivables',
                _fmt(widget.outstandingReceivables),
                Icons.people_alt,
                const Color(0xFFF3E8FF),
                const Color(0xFF7E22CE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
