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
  final bool isMobile;
  final bool isTablet;
  final VoidCallback? onOpenDrawer;

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
    this.isMobile = false,
    this.isTablet = false,
    this.onOpenDrawer,
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
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              // Drawer Hamburger Menu on Mobile
              if (onOpenDrawer != null) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 24),
                  onPressed: onOpenDrawer,
                  color: textColor,
                  tooltip: 'Open Menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 8),
              ],

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 2),
                  Text(
                    descText,
                    style: TextStyle(fontSize: 11, color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Refresh Button
          if (isMobile)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              color: textColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            )
          else
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
          const SizedBox(width: 4),

          // All Modules (Desktop & Tablet)
          if (!isMobile) ...[
            OutlinedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard_customize_rounded, size: 15),
              label: Text(isTablet ? 'Modules' : 'All Modules', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor),
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 9 : 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Launch POS
          if (isMobile)
            IconButton(
              onPressed: onLaunchPos,
              icon: const Icon(Icons.point_of_sale_rounded, size: 20),
              tooltip: 'Launch POS',
              color: const Color(0xFF10B981),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            )
          else
            ElevatedButton.icon(
              onPressed: onLaunchPos,
              icon: const Icon(Icons.point_of_sale_rounded, size: 15),
              label: Text(isTablet ? 'POS' : 'Launch POS', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),

          if (!isMobile) ...[
            const SizedBox(width: 10),
            Container(
              height: 24,
              width: 1,
              color: borderColor,
            ),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 4),

          // User Profile Pill / Avatar with Dropdown
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            color: cardBg,
            elevation: 8,
            tooltip: 'Account & Actions',
            onSelected: (value) {
              if (value == 'modules') {
                context.go('/dashboard');
              } else if (value == 'about') {
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
              if (isMobile) ...[
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'modules',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All Modules',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
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
            child: isMobile
                ? Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Container(
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
                          constraints: BoxConstraints(maxWidth: isTablet ? 90 : 130),
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
    ),
  ),
);
  }
}
