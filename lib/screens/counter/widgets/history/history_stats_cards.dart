import 'package:flutter/material.dart';

class HistoryStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final String percentage;

  const HistoryStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    this.percentage = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (percentage.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      percentage.startsWith('+')
                          ? Icons.arrow_upward
                          : (percentage == '0%'
                              ? Icons.horizontal_rule
                              : Icons.arrow_downward),
                      color: percentage.startsWith('+')
                          ? const Color(0xFF22C55E)
                          : (percentage == '0%'
                              ? const Color(0xFF94A3B8)
                              : Colors.red),
                      size: 12,
                    ),
                    Text(
                      percentage,
                      style: TextStyle(
                        color: percentage.startsWith('+')
                            ? const Color(0xFF22C55E)
                            : (percentage == '0%'
                                ? const Color(0xFF94A3B8)
                                : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'vs last month',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class HistoryStatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> filtered;

  const HistoryStatsRow({super.key, required this.filtered});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalRevenue = 0;
    int totalInvoices = 0;
    double totalReturns = 0;
    double cashInHand = 0;

    for (var tx in filtered) {
      double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (tx['type'] == 'Return') {
        totalReturns += amount;
      } else {
        totalRevenue += amount;
        totalInvoices += 1;
        if (tx['paymentMode'] == 'Cash') {
          cashInHand += amount;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250,
                child: HistoryStatCard(
                  value: '₹${totalRevenue.toStringAsFixed(2)}',
                  label: 'Total Revenue',
                  bgColor: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                  iconColor: isDark ? Colors.green[400]! : const Color(0xFF166534),
                  icon: Icons.currency_rupee,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250,
                child: HistoryStatCard(
                  value: '$totalInvoices',
                  label: 'Total Invoices',
                  bgColor: isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
                  iconColor: isDark ? Colors.blue[400]! : const Color(0xFF0369A1),
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250,
                child: HistoryStatCard(
                  value: '₹${totalReturns.toStringAsFixed(2)}',
                  label: 'Total Returns',
                  bgColor: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                  iconColor: isDark ? Colors.red[400]! : Colors.red,
                  icon: Icons.keyboard_return,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250,
                child: HistoryStatCard(
                  value: '₹${cashInHand.toStringAsFixed(2)}',
                  label: 'Cash in Hand',
                  bgColor: isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF),
                  iconColor: isDark ? Colors.purple[400]! : const Color(0xFF7E22CE),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
