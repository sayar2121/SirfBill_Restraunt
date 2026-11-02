import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../services/windows_auto_updater.dart';
import '../about/about_us_dialog.dart';
import 'sidebar_nav_item.dart';

class CounterDashboardSidebar extends StatelessWidget {
  final bool isDesktop;
  final bool isExpanded;
  final int currentIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const CounterDashboardSidebar({
    super.key,
    required this.isDesktop,
    required this.isExpanded,
    required this.currentIndex,
    required this.onSelectIndex,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool expanded = isDesktop ? isExpanded : true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);

    const navItems = [
      (Icons.point_of_sale_rounded, 'POS Billing', 'F1'),
      (Icons.table_restaurant_rounded, 'Tables', 'F2'),
      (Icons.receipt_long_rounded, 'Orders', 'F3'),
      (Icons.soup_kitchen_rounded, 'Kitchen (KOT)', 'F4'),
      (Icons.restaurant_menu_rounded, 'Menu Management', 'F5'),
      (Icons.people_alt_rounded, 'Customers (CRM)', 'F6'),
      // (Icons.inventory_2_rounded, 'Inventory', 'F7'),
      (Icons.bar_chart_rounded, 'Reports', 'F7'),
      // (Icons.account_balance_wallet_rounded, 'Expenses', 'F8'),
      (Icons.settings_rounded, 'Settings', 'F8'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isDesktop ? (expanded ? 260 : 80) : null,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: ClipRect(
        child: SafeArea(
          top: !isDesktop,
          bottom: !isDesktop,
          child: Column(
            crossAxisAlignment: expanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(expanded ? 24.0 : 16.0),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  alignment: Alignment.centerLeft,
                  firstChild: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: 212,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sirfbill Restaurant',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'POS & Restaurant Operations',
                            style: TextStyle(
                              fontSize: 10,
                              color: subtitleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  secondChild: const Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < navItems.length; i++)
                        SidebarNavItem(
                          icon: navItems[i].$1,
                          label: navItems[i].$2,
                          shortcut: navItems[i].$3,
                          isSelected: currentIndex == i,
                          isExpanded: expanded,
                          isDesktop: isDesktop,
                          onTap: () => onSelectIndex(i),
                        ),

                      const SizedBox(height: 16),
                      Divider(
                        color: borderColor,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      const SizedBox(height: 8),

                      // Super Admin Quick Links: Admin Panel & Modules
                      FutureBuilder<bool>(
                        future: SharedPreferences.getInstance().then((p) {
                          final r = (p.getString('user_role') ?? '').trim().toUpperCase();
                          return r == 'ADMIN' || r == 'OWNER' || r == 'SUPER_ADMIN';
                        }),
                        builder: (ctx, snap) {
                          if (snap.data == true) {
                            return Column(
                              children: [
                                SidebarNavItem(
                                  icon: Icons.admin_panel_settings_rounded,
                                  label: 'Admin Panel',
                                  isExpanded: expanded,
                                  isDesktop: isDesktop,
                                  customTextColor: const Color(0xFF6366F1),
                                  customIconColor: const Color(0xFF6366F1),
                                  onTap: () => context.go('/admin'),
                                ),
                                SidebarNavItem(
                                  icon: Icons.dashboard_customize_rounded,
                                  label: 'All Modules',
                                  isExpanded: expanded,
                                  isDesktop: isDesktop,
                                  customTextColor: const Color(0xFF10B981),
                                  customIconColor: const Color(0xFF10B981),
                                  onTap: () => context.go('/dashboard'),
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  color: borderColor,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      SidebarNavItem(
                        icon: isDark ? Icons.light_mode : Icons.dark_mode,
                        label: isDark ? 'Light Mode' : 'Dark Mode',
                        isExpanded: expanded,
                        isDesktop: isDesktop,
                        customTextColor: subtitleColor,
                        customIconColor: subtitleColor,
                        onTap: onToggleTheme,
                      ),

                      SidebarNavItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        isExpanded: expanded,
                        isDesktop: isDesktop,
                        customTextColor: Colors.red,
                        customIconColor: Colors.red,
                        onTap: onLogout,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sidebar Card (About Us)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                alignment: Alignment.bottomCenter,
                firstChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => AboutUsDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: isDesktop ? 228 : double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF22C55E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About SirfBill',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Company & Support Info',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: subtitleColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: subtitleColor),
                        ],
                      ),
                    ),
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF22C55E), size: 24),
                      tooltip: 'About SirfBill',
                      onPressed: () => AboutUsDialog.show(context),
                    ),
                  ),
                ),
              ),

              // Check for Updates Button (Windows Desktop only)
              if (!kIsWeb && Platform.isWindows)
                AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                alignment: Alignment.center,
                firstChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final currentVersion = snapshot.hasData ? snapshot.data!.version : '1.0.3';
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checking for updates...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          final updateInfo = await WindowsAutoUpdater.checkForUpdate();
                          if (context.mounted) {
                            if (updateInfo != null) {
                              WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('SirfBill v$currentVersion is already up to date!'),
                                  backgroundColor: const Color(0xFF166534),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534).withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF166534).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.system_update_rounded,
                                size: 18,
                                color: Color(0xFF166534),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Check for Updates',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF166534),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'v$currentVersion',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.system_update_rounded, color: Color(0xFF166534), size: 22),
                      tooltip: 'Check for Updates',
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checking for updates...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        final updateInfo = await WindowsAutoUpdater.checkForUpdate();
                        if (context.mounted && updateInfo != null) {
                          WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
