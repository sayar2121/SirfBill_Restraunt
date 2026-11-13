import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../services/windows_auto_updater.dart';
import '../../widgets/restaurant_module_card.dart';
import 'widgets/dashboard_components.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _manualCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      await WindowsAutoUpdater.checkAndShowUpdateIfAvailable(
        context,
        showFeedbackWhenLatest: true,
      );
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
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
      nextRoute: '/kitchen',
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
      title: 'Waiter / Captain',
      description: 'Table order taking & automated KOT dispatch.',
      icon: Icons.room_service_rounded,
      primaryColor: Color(0xFFF59E0B), // Amber
      nextRoute: '/waiter',
    ),
    ModuleCardData(
      indexText: '06',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                Icon(Icons.soup_kitchen_rounded, size: 48, color: module.primaryColor),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            painter: DotGridPainter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFD1E8DE),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isWeb = screenWidth > 900;
                final isMobile = screenWidth < 500;
                final isTablet = screenWidth >= 500 && screenWidth <= 1100;
                final isCompactHeight = screenHeight < 720;

                return SingleChildScrollView(
                  physics: screenHeight >= 500
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Top Bar: Update button + Server config + Theme toggle
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 48.0 : (isMobile ? 12.0 : 16.0),
                            vertical: isMobile ? 4.0 : (isTablet ? 6.0 : (isCompactHeight ? 6.0 : 12.0)),
                          ),
                          child: DashboardTopBar(
                            isDark: isDark,
                            isMobile: isMobile,
                            isCheckingUpdate: _isCheckingUpdate,
                            onCheckUpdate: _manualCheckUpdate,
                            onOpenServerSettings: () => ServerConfigDialog.show(context),
                            onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
                          ),
                        ),

                        // 2. Center Content: Logo, Welcome Title & 6-Module Grid
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 36.0 : (isMobile ? 12.0 : 16.0),
                            vertical: isMobile ? 2.0 : (isTablet ? 4.0 : (isCompactHeight ? 8.0 : 16.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DashboardHeader(
                                isDark: isDark,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isWeb: isWeb,
                                isCompactHeight: isCompactHeight,
                              ),
                              SizedBox(height: isMobile ? 10 : (isTablet ? (isCompactHeight ? 12 : 18) : (isCompactHeight ? 24 : 36))),

                              // Responsive Cards Grid: 6 Cards in 1 Row on Desktop, 3x2 on Tablet, 2x3 on Mobile
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1560),
                                  child: LayoutBuilder(
                                    builder: (context, cardConstraints) {
                                      final width = cardConstraints.maxWidth;

                                      int crossAxisCount;
                                      double childAspectRatio;

                                      if (width >= 1050) {
                                        crossAxisCount = 6;
                                        childAspectRatio = isCompactHeight ? 0.90 : 0.78;
                                      } else if (width >= 580) {
                                        crossAxisCount = 3;
                                        final availableGridHeight = screenHeight - (isCompactHeight ? 200 : 250);
                                        final rowHeight = (availableGridHeight - 14) / 2;
                                        final colWidth = (width - 24) / 3;
                                        final calculatedRatio = (colWidth / rowHeight.clamp(160.0, 240.0));
                                        childAspectRatio = calculatedRatio.clamp(1.0, 1.25);
                                      } else {
                                        crossAxisCount = 2;
                                        final availableGridHeight = screenHeight - (isMobile ? 165 : 200);
                                        final rowHeight = (availableGridHeight - 16) / 3;
                                        final colWidth = (width - 8) / 2;
                                        final calculatedRatio = (colWidth / rowHeight.clamp(120.0, 180.0));
                                        childAspectRatio = calculatedRatio.clamp(1.08, 1.30);
                                      }

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _modules.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: isMobile ? 8 : 12,
                                          mainAxisSpacing: isMobile ? 8 : 12,
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

                        // 3. Footer Branding
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8 : (isTablet ? (isCompactHeight ? 8 : 12) : (isCompactHeight ? 16 : 24)),
                          ),
                          child: DashboardFooter(
                            isDark: isDark,
                            isMobile: isMobile,
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
