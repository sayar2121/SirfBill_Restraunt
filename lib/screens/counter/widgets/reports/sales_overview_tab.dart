import 'package:flutter/material.dart';
import '../../../../models/restaurant_report_models.dart';
import 'channel_breakdown_card.dart';
import 'executive_hero_banner.dart';
import 'executive_kpi_grid.dart';

/// Clean, modular executive sales overview tab.
class SalesOverviewTab extends StatelessWidget {
  final SalesReportSummary summary;

  const SalesOverviewTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSales = summary.grossSales > 0 ? summary.grossSales : 1.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Hero Banner
          ExecutiveHeroBanner(summary: summary, isDark: isDark),
          const SizedBox(height: 20),

          // 2. 6-KPI Executive Grid
          ExecutiveKpiGrid(summary: summary, isDark: isDark),
          const SizedBox(height: 20),

          // 3. Channel Breakdowns (Payment Tender Split & Order Fulfillment Mix)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;

              final paymentCard = ChannelBreakdownCard(
                title: 'Payment Channel Split',
                subtitle: 'Collections categorized by settlement tender',
                badgeText: 'Tender Mix',
                icon: Icons.account_balance_rounded,
                accentColor: const Color(0xFF6366F1),
                isDark: isDark,
                items: [
                  ChannelItemData(
                    title: 'UPI / Dynamic QR',
                    subtitle: 'Instant phone & scan payments',
                    amount: summary.upiSales,
                    percentage: (summary.upiSales / totalSales) * 100,
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  ChannelItemData(
                    title: 'Cash Tendered',
                    subtitle: 'Physical register currency',
                    amount: summary.cashSales,
                    percentage: (summary.cashSales / totalSales) * 100,
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  ChannelItemData(
                    title: 'Debit & Credit Cards',
                    subtitle: 'EDC terminal POS swipe',
                    amount: summary.cardSales,
                    percentage: (summary.cardSales / totalSales) * 100,
                    icon: Icons.credit_card_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              );

              final orderTypeCard = ChannelBreakdownCard(
                title: 'Fulfillment & Order Channels',
                subtitle: 'Dine-in floor, takeaway counter & delivery mix',
                badgeText: 'Channel Flow',
                icon: Icons.pie_chart_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                items: [
                  ChannelItemData(
                    title: 'Dine-In Restaurant Tables',
                    subtitle: 'Floor service & table seating',
                    amount: summary.dineInSales,
                    percentage: (summary.dineInSales / totalSales) * 100,
                    icon: Icons.table_restaurant_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  ChannelItemData(
                    title: 'Takeaway Counter',
                    subtitle: 'Direct parcel & pickup orders',
                    amount: summary.takeawaySales,
                    percentage: (summary.takeawaySales / totalSales) * 100,
                    icon: Icons.takeout_dining_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  ChannelItemData(
                    title: 'Delivery Logistics',
                    subtitle: 'Rider dispatch & home delivery',
                    amount: summary.deliverySales,
                    percentage: (summary.deliverySales / totalSales) * 100,
                    icon: Icons.delivery_dining_rounded,
                    color: const Color(0xFFEC4899),
                  ),
                ],
              );

              return isNarrow
                  ? Column(children: [paymentCard, const SizedBox(height: 16), orderTypeCard])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: paymentCard),
                        const SizedBox(width: 16),
                        Expanded(child: orderTypeCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}
