import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';
import 'customer_stat_card.dart';

class CustomersSummaryCards extends StatelessWidget {
  final List<Map<String, dynamic>> allCustomers;

  const CustomersSummaryCards({
    super.key,
    required this.allCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 20) / 2,
              child: CustomerStatCard(
                title: 'Total Customers',
                value: '${allCustomers.length}',
                icon: Icons.people,
                bgColor: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
              ),
            ),
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 20) / 2,
              child: CustomerStatCard(
                title: 'Active Customers',
                value:
                    '${allCustomers.where((c) => c['status'] == 'Active').length}',
                icon: Icons.check_circle_outline,
                bgColor: AppColors.infoLight,
                iconColor: AppColors.info,
              ),
            ),
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 20) / 2,
              child: CustomerStatCard(
                title: 'New This Month',
                value:
                    '${allCustomers.where((c) {
                      if (c['raw_created_at'] == null) return false;
                      try {
                        final dt = DateTime.parse(c['raw_created_at']).toLocal();
                        final now = DateTime.now();
                        return dt.month == now.month && dt.year == now.year;
                      } catch (e) {
                        return false;
                      }
                    }).length}',
                icon: Icons.person_add_alt_1,
                bgColor: AppColors.warningLight,
                iconColor: AppColors.warning,
              ),
            ),
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 20) / 2,
              child: CustomerStatCard(
                title: 'Loyal Customers',
                value:
                    '${allCustomers.where((c) => (c['bills'] ?? 0) >= 10).length}',
                icon: Icons.star,
                bgColor: AppColors.secondaryLight,
                iconColor: AppColors.secondary,
                subtitle: '(10+ purchases)',
              ),
            ),
          ],
        );
      },
    );
  }
}
