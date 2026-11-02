import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/distributor_provider.dart';

class DistributorKpiCards extends ConsumerWidget {
  final List<dynamic> distributors;

  const DistributorKpiCards({super.key, required this.distributors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = distributors.where((d) => d['is_active'] != false).length;
    final totalCount = distributors.length;
    
    final purchaseBillsAsync = ref.watch(purchaseBillsProvider);
    
    double totalPurchases = 0;
    double pendingPayments = 0;
    
    if (purchaseBillsAsync.hasValue) {
      final bills = purchaseBillsAsync.value!;
      for (var bill in bills) {
        final amount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
        totalPurchases += amount;
        if (bill['payment_status'] != 'PAID') {
          pendingPayments += amount;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 1100 && constraints.maxWidth >= 600;
          
          double cardWidth = constraints.maxWidth; // Mobile
          if (isTablet) {
            cardWidth = (constraints.maxWidth - 16) / 2;
          // ignore: curly_braces_in_flow_control_structures
          } else if (!isMobile) cardWidth = (constraints.maxWidth - 48) / 4;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildCard(context, 'Total Distributors', '$totalCount', Icons.business, Colors.blue, cardWidth),
              _buildCard(context, 'Active Distributors', '$activeCount', Icons.check_circle, Colors.green, cardWidth),
              _buildCard(context, 'Total Purchases', '₹${totalPurchases.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}', Icons.shopping_bag, Colors.purple, cardWidth),
              _buildCard(context, 'Pending Payments', '₹${pendingPayments.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}', Icons.account_balance_wallet, Colors.orange, cardWidth),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String value, IconData icon, MaterialColor color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
