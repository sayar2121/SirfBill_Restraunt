import 'package:flutter/material.dart';
import '../../../../models/restaurant_report_models.dart';

class KpiSpec {
  final String title;
  final String value;
  final String subtext;
  final String badge;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const KpiSpec({
    required this.title,
    required this.value,
    required this.subtext,
    required this.badge,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

/// Dynamic 6-KPI metrics grid (Net Revenue, Total Orders, AOV, Dishes, Guests, Discounts).
class ExecutiveKpiGrid extends StatelessWidget {
  final SalesReportSummary summary;
  final bool isDark;

  const ExecutiveKpiGrid({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w < 650 ? 2 : (w < 1100 ? 3 : 6);
        final aspect = w < 650 ? 1.6 : (w < 1100 ? 1.85 : 1.65);

        final metrics = [
          KpiSpec(
            title: 'Net Revenue',
            value: '₹${summary.netSales.toStringAsFixed(0)}',
            subtext: 'Excl. GST & discounts',
            badge: 'Base Revenue',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF6366F1),
            gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
          ),
          KpiSpec(
            title: 'Total Orders',
            value: '${summary.totalOrders}',
            subtext: 'Completed tickets',
            badge: summary.totalOrders > 0 ? 'Active Vol' : 'Zero Orders',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF0EA5E9),
            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          ),
          KpiSpec(
            title: 'Avg Order Value',
            value: '₹${summary.averageOrderValue.toStringAsFixed(1)}',
            subtext: 'Per guest check',
            badge: 'AOV Metric',
            icon: Icons.insights_rounded,
            color: const Color(0xFFF59E0B),
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          ),
          KpiSpec(
            title: 'Dishes Prepared',
            value: '${summary.totalItemsSold}',
            subtext: 'Kitchen item count',
            badge: 'Items Cooked',
            icon: Icons.restaurant_menu_rounded,
            color: const Color(0xFF8B5CF6),
            gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          ),
          KpiSpec(
            title: 'Guests Served',
            value: '${summary.uniqueCustomers}',
            subtext: 'Distinct patrons',
            badge: 'Unique CRM',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFFEC4899),
            gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
          ),
          KpiSpec(
            title: 'Discounts Given',
            value: '₹${summary.totalDiscount.toStringAsFixed(0)}',
            subtext: 'Promos & coupons',
            badge: 'Price Deductions',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFFEF4444),
            gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: aspect,
          ),
          itemBuilder: (context, i) => _buildMetricCard(metrics[i], isDark),
        );
      },
    );
  }

  Widget _buildMetricCard(KpiSpec kpi, bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textHeading = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  kpi.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kpi.gradient[0].withValues(alpha: 0.18),
                      kpi.gradient[1].withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 15),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kpi.value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: textHeading,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: kpi.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      kpi.badge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: kpi.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      kpi.subtext,
                      style: TextStyle(fontSize: 10, color: textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
