import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../counter/widgets/about/about_us_dialog.dart';

class AdminTopHeader extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onRefresh;
  final VoidCallback onLaunchPos;
  final VoidCallback onLogout;
  final String? userName;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const AdminTopHeader({
    super.key,
    required this.selectedIndex,
    required this.onRefresh,
    required this.onLaunchPos,
    required this.onLogout,
    this.userName,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    String titleText = 'Dashboard Overview';
    String descText = 'Business overview, performance metrics & live restaurant activity';

    if (selectedIndex == 1) {
      titleText = 'Outlets & Branches';
      descText = 'Configure multi-location restaurants, POS terminals & tax setup';
    } else if (selectedIndex == 2) {
      titleText = 'Users & Staff Access';
      descText = 'Manage cashier credentials, floor staff accounts and role permissions';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = (userName != null && userName!.trim().isNotEmpty) ? userName!.trim() : 'Restaurant Admin';
    final userInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descText,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Refresh', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.dashboard_customize_rounded, size: 15),
            label: const Text('All Modules', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onLaunchPos,
            icon: const Icon(Icons.point_of_sale_rounded, size: 15),
            label: const Text('Launch POS', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 14),

          // Divider
          Container(
            height: 28,
            width: 1,
            color: borderColor,
          ),
          const SizedBox(width: 14),

          // User Profile Pill with Dropdown (About SirfBill & Logout)
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            color: cardBg,
            elevation: 8,
            tooltip: 'Account & Actions',
            onSelected: (value) {
              if (value == 'about') {
                AboutUsDialog.show(context);
              } else if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Super Administrator',
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'About SirfBill',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Logout',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: subtitleColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
