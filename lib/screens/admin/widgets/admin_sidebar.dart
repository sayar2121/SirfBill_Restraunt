import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final bool isDark;
  final bool isCollapsed;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;
  final Color sidebarBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const AdminSidebar({
    super.key,
    required this.isDark,
    required this.isCollapsed,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.onToggleCollapse,
    required this.onLogout,
    required this.sidebarBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // LOGO HEADER (Clean full official logo)
            Container(
              height: 72,
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Center(
                child: Image.asset(
                  isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                  height: isCollapsed ? 36 : 46,
                  fit: BoxFit.contain,
                  alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
                  errorBuilder: (_, __, ___) => Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

            // NAV ITEMS
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildNavButton(
                    index: 0,
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Dashboard',
                    subtitle: 'Overview & live activity',
                  ),
                  const SizedBox(height: 6),
                  _buildNavButton(
                    index: 1,
                    icon: Icons.storefront_rounded,
                    title: 'Outlets & Branches',
                    subtitle: 'Locations & store setups',
                  ),
                  const SizedBox(height: 6),
                  _buildNavButton(
                    index: 2,
                    icon: Icons.manage_accounts_rounded,
                    title: 'Users & Roles',
                    subtitle: 'Staff accounts & access',
                  ),
                ],
              ),
            ),

            // COLLAPSE TOGGLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCollapsed)
                        Expanded(
                          child: Text(
                            'Collapse Menu',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Icon(
                        isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        size: 20,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: isCollapsed ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedIndex == index;

    return Tooltip(
      message: isCollapsed ? title : '',
      child: InkWell(
        onTap: () => onSelectIndex(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: isCollapsed ? 0 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
