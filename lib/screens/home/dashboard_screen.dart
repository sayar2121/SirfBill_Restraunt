import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../services/windows_auto_updater.dart';
import '../../widgets/restaurant_module_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _manualCheckUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      await WindowsAutoUpdater.checkAndShowUpdateIfAvailable(
        context,
        showFeedbackWhenLatest: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WindowsAutoUpdater.checkAndShowUpdateIfAvailable(context);
      }
    });
  }

  final List<ModuleCardData> _modules = const [
    ModuleCardData(
      indexText: '01',
      title: 'Restaurant POS',
      description: 'Billing, dine-in, takeaway and payments.',
      icon: Icons.restaurant_menu_rounded,
      primaryColor: Color(0xFF10B981), // Emerald green
      nextRoute: '/counter/billing',
    ),
    ModuleCardData(
      indexText: '02',
      title: 'Kitchen Display',
      description: 'Manage KOTs and live kitchen orders.',
      icon: Icons.soup_kitchen_rounded,
      primaryColor: Color(0xFFF97316), // Warm orange
      nextRoute: '/counter/kitchen',
      isComingSoon: false,
    ),
    ModuleCardData(
      indexText: '03',
      title: 'Inventory & Purchase',
      description: 'Ingredients, recipes, suppliers and stock.',
      icon: Icons.inventory_2_rounded,
      primaryColor: Color(0xFF3B82F6), // Blue
      nextRoute: '/counter/inventory',
    ),
    ModuleCardData(
      indexText: '04',
      title: 'CRM & Reports',
      description: 'Customers, loyalty and sales performance.',
      icon: Icons.groups_rounded,
      primaryColor: Color(0xFF8B5CF6), // Royal purple
      nextRoute: '/counter/customers',
    ),
    ModuleCardData(
      indexText: '05',
      title: 'Admin Panel',
      description: 'Manage outlets, branches, staff roles and users.',
      icon: Icons.admin_panel_settings_rounded,
      primaryColor: Color(0xFF6366F1), // Indigo
      nextRoute: '/admin',
    ),
  ];

  Future<void> _onModuleSelected(ModuleCardData module, bool isDark) async {
    if (module.isComingSoon) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.soup_kitchen_rounded,
                  size: 48,
                  color: module.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Kitchen Display (KDS)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'KDS live board and station management are being connected for Phase 3.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: module.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();
      final isAdmin = token != null && token.isNotEmpty &&
          (role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN');

      // Super Admin can access all modules instantly without re-prompt
      if (isAdmin && mounted) {
        context.go(module.nextRoute);
        return;
      }

      if (mounted) {
        context.push(
          '/role_login',
          extra: {
            'roleName': module.title,
            'themeColor': module.primaryColor,
            'nextRoute': module.nextRoute,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B132B)
            : const Color(0xFFF1F8F5),
        body: SafeArea(
          child: CustomPaint(
            painter: _DotGridPainter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFD1E8DE),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isWeb = screenWidth > 900;
                final isCompactHeight = screenHeight < 720;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar: Update button + Theme toggle
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 48.0 : 16.0,
                            vertical: isCompactHeight ? 6.0 : 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!kIsWeb)
                                TextButton.icon(
                                  onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                                  icon: _isCheckingUpdate
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
                                    _isCheckingUpdate ? 'Checking...' : 'Check Updates',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => ref
                                    .read(themeProvider.notifier)
                                    .toggleTheme(),
                                icon: Icon(
                                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center Content
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 36.0 : 16.0,
                            vertical: isCompactHeight ? 8.0 : 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // SirfBill Branded Logo
                              Center(
                                child: Image.asset(
                                  isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                                  height: isCompactHeight ? (isWeb ? 80 : 60) : (isWeb ? 110 : 80),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Column(
                                    children: [
                                      const Icon(
                                        Icons.restaurant_rounded,
                                        color: Color(0xFF10B981),
                                        size: 42,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'sirfbill',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Accounting without error',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isCompactHeight ? 16 : 24),

                              // Welcome Badge
                              Center(
                                child: Text(
                                  'WELCOME BACK!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // "Select a Module" Header
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: isWeb ? 32 : 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Select a '),
                                      TextSpan(
                                        text: 'Module',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Subtitle
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Choose a module to continue and manage your restaurant.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isWeb ? 14 : 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompactHeight ? 24 : 36),

                              // Responsive Cards Layout: 5 Cards in 1 Row on Desktop
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1380),
                                  child: LayoutBuilder(
                                    builder: (context, cardConstraints) {
                                      final width = cardConstraints.maxWidth;

                                      // Breakpoints calculation:
                                      // Wide desktop (>= 1100px): All 5 cards in 1 sleek row
                                      // Medium laptop / tablet (>= 720px): 3 or 4 cards per row
                                      // Tablet / Small desktop (>= 500px): 2 cards per row
                                      // Mobile (< 500px): 1 card per row
                                      int crossAxisCount;
                                      double childAspectRatio;

                                      if (width >= 1100) {
                                        crossAxisCount = 5;
                                        childAspectRatio = isCompactHeight ? 0.88 : 0.78;
                                      } else if (width >= 800) {
                                        crossAxisCount = 3;
                                        childAspectRatio = 0.95;
                                      } else if (width >= 520) {
                                        crossAxisCount = 2;
                                        childAspectRatio = 1.05;
                                      } else {
                                        crossAxisCount = 1;
                                        childAspectRatio = 1.6;
                                      }

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _modules.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemBuilder: (context, index) {
                                          final module = _modules[index];
                                          return RestaurantModuleCard(
                                            data: module,
                                            onTap: () => _onModuleSelected(module, isDark),
                                            isDark: isDark,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Footer
                        Container(
                          padding: EdgeInsets.symmetric(vertical: isCompactHeight ? 16 : 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SirfBill Restaurant • Naiyo24',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 32,
                                height: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;

  _DotGridPainter({required this.color});

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
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
