import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';

class WaiterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String waiterName;
  final String restaurantName;
  final int readyOrdersCount;
  final VoidCallback? onOpenReadyNotifications;
  final VoidCallback onRefresh;

  const WaiterAppBar({
    super.key,
    required this.waiterName,
    this.restaurantName = '',
    this.readyOrdersCount = 0,
    this.onOpenReadyNotifications,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrow = screenWidth < 500;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AppBar(
      elevation: 0,
      toolbarHeight: 62,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      titleSpacing: isVeryNarrow ? 10 : 16,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: borderColor,
          height: 1,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. SirfBill Logo (Enlarged & Prominent)
          Image.asset(
            isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.restaurant_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),

          // Divider
          Container(
            height: 28,
            width: 1.2,
            color: borderColor,
          ),
          const SizedBox(width: 12),

          // Waiter Module Badge & Identity
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.room_service_rounded,
                    color: Color(0xFFF59E0B),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              restaurantName.isNotEmpty ? restaurantName : 'Waiter Order Pad',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restaurantName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'WAITER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Captain: $waiterName',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Ready Orders Notification Button (when food is cooked and ready to serve)
        if (readyOrdersCount > 0) ...[
          Tooltip(
            message: '$readyOrdersCount order(s) ready to serve!',
            child: InkWell(
              onTap: onOpenReadyNotifications,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$readyOrdersCount Ready',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Back to Dashboard / Modules
        Tooltip(
          message: 'Back to Modules',
          child: InkWell(
            onTap: () => context.go('/dashboard'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  if (screenWidth >= 650) ...[
                    const SizedBox(width: 5),
                    Text(
                      'Modules',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Refresh Menu & Tables
        Tooltip(
          message: 'Refresh Menu & Tables',
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: const Icon(Icons.refresh_rounded, size: 17, color: Color(0xFF10B981)),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Logout
        Tooltip(
          message: 'Logout',
          child: InkWell(
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) context.go('/dashboard');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.logout_rounded, size: 17, color: Color(0xFFEF4444)),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
