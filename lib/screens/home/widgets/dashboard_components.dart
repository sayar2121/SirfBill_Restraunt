import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../config/api_constants.dart';

/// 1. Subtle dotted canvas background painter.
class DotGridPainter extends CustomPainter {
  final Color color;

  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 22.0;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 2. Server IP & connection settings dialog.
class ServerConfigDialog {
  static Future<void> show(BuildContext context) async {
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Server IP & URL Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the local backend IP address or server URL running your restaurant database (e.g. http://192.168.0.31:8000 or http://127.0.0.1:8000):',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'http://192.168.0.31:8000',
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await ApiConstants.setCustomBaseUrl(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL updated to ${ApiConstants.baseUrl}'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}

/// 3. Top Action Bar with Update checker, Server settings, and Theme toggle.
class DashboardTopBar extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final bool isCheckingUpdate;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenServerSettings;
  final VoidCallback onToggleTheme;

  const DashboardTopBar({
    super.key,
    required this.isDark,
    required this.isMobile,
    required this.isCheckingUpdate,
    required this.onCheckUpdate,
    required this.onOpenServerSettings,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!kIsWeb)
          isMobile
              ? IconButton(
                  tooltip: 'Check Updates',
                  onPressed: isCheckingUpdate ? null : onCheckUpdate,
                  icon: isCheckingUpdate
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        )
                      : Icon(
                          Icons.system_update_alt_rounded,
                          size: 19,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                )
              : TextButton.icon(
                  onPressed: isCheckingUpdate ? null : onCheckUpdate,
                  icon: isCheckingUpdate
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        )
                      : Icon(
                          Icons.system_update_alt_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                  label: Text(
                    isCheckingUpdate ? 'Checking...' : 'Check Updates',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Server Connection Settings',
          onPressed: onOpenServerSettings,
          icon: Icon(
            Icons.dns_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            size: isMobile ? 19 : 20,
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: isMobile ? 20 : 22,
          ),
        ),
      ],
    );
  }
}

/// 4. Dashboard Title and Module Selection Header.
class DashboardHeader extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final bool isTablet;
  final bool isWeb;
  final bool isCompactHeight;

  const DashboardHeader({
    super.key,
    required this.isDark,
    required this.isMobile,
    required this.isTablet,
    required this.isWeb,
    required this.isCompactHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // SirfBill Branded Logo
        Center(
          child: Image.asset(
            isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
            height: isMobile
                ? 40
                : (isTablet
                    ? (isCompactHeight ? 48 : 58)
                    : (isCompactHeight ? 60 : (isWeb ? 100 : 80))),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  color: const Color(0xFF10B981),
                  size: isMobile ? 32 : (isTablet ? 36 : 42),
                ),
                const SizedBox(height: 2),
                Text(
                  'sirfbill',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : (isTablet ? 20 : 24),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isMobile ? 6 : (isTablet ? (isCompactHeight ? 8 : 12) : (isCompactHeight ? 16 : 24))),

        // Welcome Badge
        if (!isMobile) ...[
          Center(
            child: Text(
              'WELCOME BACK!',
              style: TextStyle(
                fontSize: isTablet ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],

        // "Select a Module" Header
        Center(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isWeb ? 32 : (isMobile ? 20 : (isTablet ? 22 : 24)),
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'Select a '),
                TextSpan(
                  text: 'Module',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              isMobile
                  ? 'Tap a module to continue and manage orders.'
                  : 'Choose a module to continue and manage your restaurant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWeb ? 14 : (isMobile ? 11.5 : (isTablet ? 12 : 12.5)),
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 5. Footer branding widget.
class DashboardFooter extends StatelessWidget {
  final bool isDark;
  final bool isMobile;

  const DashboardFooter({
    super.key,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isMobile ? 20 : 32,
          height: 1,
          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Text(
          'SirfBill Restaurant • Naiyo24',
          style: TextStyle(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: isMobile ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Container(
          width: isMobile ? 20 : 32,
          height: 1,
          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}

