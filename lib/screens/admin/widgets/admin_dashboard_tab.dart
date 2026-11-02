import 'package:flutter/material.dart';
import '../../../config/api_constants.dart';
import '../../../services/shop_service.dart';
import 'admin_metric_card.dart';

class AdminDashboardTab extends StatelessWidget {
  final List<Shop> branches;
  final int staffCount;
  final VoidCallback onAddBranch;
  final VoidCallback onAddUser;
  final VoidCallback onViewAllBranches;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminDashboardTab({
    super.key,
    required this.branches,
    required this.staffCount,
    required this.onAddBranch,
    required this.onAddUser,
    required this.onViewAllBranches,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QUICK STATS CARDS ROW
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              final crossAxisCount = isWide ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 2.1 : 1.7,
                children: [
                  AdminMetricCard(
                    title: 'Active Outlets',
                    value: '${branches.length}',
                    trend: 'All locations online',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF6366F1),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  AdminMetricCard(
                    title: 'Total Staff',
                    value: '$staffCount',
                    trend: 'Across all branches',
                    icon: Icons.badge_rounded,
                    color: const Color(0xFF10B981),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  AdminMetricCard(
                    title: 'System Roles',
                    value: '5 Roles',
                    trend: 'Admin, Mgr, Cashier, Chef, Inventory',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFFF59E0B),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  AdminMetricCard(
                    title: 'Gateway',
                    value: 'REST API',
                    trend: 'Connected (Port 8000)',
                    icon: Icons.cloud_done_rounded,
                    color: const Color(0xFF06B6D4),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // QUICK ACTIONS & SHORTCUTS
          Text(
            'Admin Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              final shortcuts = [
                AdminActionShortcut(
                  icon: Icons.add_business_rounded,
                  title: 'Create Outlet / Branch',
                  subtitle: 'Register new restaurant address & contact details',
                  color: const Color(0xFF6366F1),
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: onAddBranch,
                ),
                AdminActionShortcut(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Provision Staff User',
                  subtitle: 'Set up login ID, password & assign security roles',
                  color: const Color(0xFF10B981),
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: onAddUser,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: shortcuts[0]),
                    const SizedBox(width: 14),
                    Expanded(child: shortcuts[1]),
                  ],
                );
              } else {
                return Column(
                  children: [
                    shortcuts[0],
                    const SizedBox(height: 10),
                    shortcuts[1],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // RECENT ACTIVITY / RECENT REGISTERED BRANCHES
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Primary Branch Network',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAllBranches,
                      child: const Text('View All Outlets →', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (branches.isEmpty)
                  const AdminEmptyState(text: 'No branches found. Register your first outlet now.')
                else
                  ...branches.take(3).map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (b.logoUrl != null && b.logoUrl!.trim().isNotEmpty)
                                    ? Image.network(
                                        b.logoUrl!.startsWith('http://') || b.logoUrl!.startsWith('https://')
                                            ? b.logoUrl!
                                            : '${ApiConstants.baseUrl}${b.logoUrl!.startsWith('/') ? '' : '/'}${b.logoUrl}',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, color: Color(0xFF6366F1), size: 16),
                                      )
                                    : const Icon(Icons.store_rounded, color: Color(0xFF6366F1), size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${b.location}, ${b.city}',
                                    style: TextStyle(fontSize: 11, color: subtitleColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: b.isPrimary
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFF94A3B8).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.isPrimary ? 'PRIMARY' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: b.isPrimary ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
