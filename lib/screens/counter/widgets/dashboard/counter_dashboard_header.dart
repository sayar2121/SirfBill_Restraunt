import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../about/about_us_dialog.dart';

class CounterDashboardHeader extends StatelessWidget {
  final bool isDesktop;
  final DateTime currentTime;
  final String shopName;
  final VoidCallback onMenuPressed;
  final VoidCallback onLogout;

  const CounterDashboardHeader({
    super.key,
    required this.isDesktop,
    required this.currentTime,
    required this.shopName,
    required this.onMenuPressed,
    required this.onLogout,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  Widget _buildShortcutChip(BuildContext context, String key, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    VoidCallback? onTap;
    switch (label.toLowerCase()) {
      case 'billing':
        onTap = () => context.go('/counter/billing');
        break;
      case 'tables':
        onTap = () => context.go('/counter/tables');
        break;
      case 'orders':
        onTap = () => context.go('/counter/orders');
        break;
      case 'kitchen':
        onTap = () => context.go('/counter/kitchen');
        break;
      case 'menu':
        onTap = () => context.go('/counter/menu');
        break;
      case 'customers':
        onTap = () => context.go('/counter/customers');
        break;
      case 'reports':
        onTap = () => context.go('/counter/reports');
        break;
      case 'expenses':
        onTap = () => context.go('/counter/expenses');
        break;
      case 'settings':
        onTap = () => context.go('/counter/settings');
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuPressed,
          ),
          SizedBox(width: isDesktop ? 16 : 8),
          Image.asset(
            isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
            height: isDesktop ? 75 : 45,
            width: isDesktop ? null : 110,
            alignment: Alignment.centerLeft,
            fit: BoxFit.contain,
            cacheHeight: 225,
          ),

          if (isDesktop) const Spacer(),

          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.keyboard,
                    size: 16,
                    color: Color(0xFF1E293B),
                  ),
                  _buildShortcutChip(context, 'F1', 'Billing'),
                  _buildShortcutChip(context, 'F2', 'Tables'),
                  _buildShortcutChip(context, 'F3', 'Orders'),
                  _buildShortcutChip(context, 'F4', 'Kitchen'),
                  _buildShortcutChip(context, 'F5', 'Menu'),
                  _buildShortcutChip(context, 'F6', 'Customers'),
                  _buildShortcutChip(context, 'F7', 'Reports'),
                  // _buildShortcutChip(context, 'F8', 'Expenses'),
                  _buildShortcutChip(context, 'F8', 'Settings'),
                ],
              ),
            ),

          if (isDesktop) const Spacer(),

          // Right side Profile and Date Pills
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Date & Time Pill
                  InkWell(
                    onTap: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: currentTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF166534),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF1E293B),
                                surface: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                ),
                              ),
                              dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                            ),
                            child: child!,
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 8,
                        vertical: isDesktop ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDesktop) ...[
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF166534),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isDesktop
                                    ? _formatDate(currentTime)
                                    : DateFormat('d MMM yyyy').format(currentTime),
                                style: TextStyle(
                                  color: const Color(0xFF166534),
                                  fontSize: isDesktop ? 12 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(currentTime),
                                style: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontSize: isDesktop ? 12 : 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Profile Pill
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == 'about') {
                        AboutUsDialog.show(context);
                      } else if (value == 'logout') {
                        onLogout();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF166534)),
                            SizedBox(width: 8),
                            Text(
                              'About SirfBill',
                              style: TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 8,
                        vertical: isDesktop ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: isDesktop
                            ? BorderRadius.circular(12)
                            : BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFFF1F5F9),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName.isEmpty ? 'Print Shop' : shopName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Text(
                                  'Counter',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF1E293B),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
