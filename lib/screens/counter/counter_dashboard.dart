import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/shop_settings_service.dart';
import '../../services/windows_auto_updater.dart';
import '../../providers/counter_providers.dart';
import '../../providers/theme_provider.dart';

import 'widgets/dashboard/counter_dashboard_header.dart';
import 'widgets/dashboard/counter_dashboard_sidebar.dart';

class CounterDashboard extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CounterDashboard({super.key, required this.navigationShell});

  @override
  ConsumerState<CounterDashboard> createState() => _CounterDashboardState();
}

class _CounterDashboardState extends ConsumerState<CounterDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  bool _isSidebarExpanded = true;
  String _shopName = 'Print Shop';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _fetchShopName();
    _checkWindowsUpdates();
  }

  Future<void> _checkWindowsUpdates() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WindowsAutoUpdater.checkAndShowUpdateIfAvailable(context);
      }
    });
  }

  Future<void> _fetchShopName() async {
    try {
      final userName = await AuthService.getUserName();
      if (mounted && userName != null && userName.trim().isNotEmpty) {
        setState(() => _shopName = userName);
        return;
      }

      final settings = await ShopSettingsService.getSettings();
      if (mounted) {
        final name = settings['shop_name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          setState(() => _shopName = name.toString());
        }
      }
    } catch (e) {
      debugPrint('Error fetching shop name: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      const keys = [
        LogicalKeyboardKey.f1,
        LogicalKeyboardKey.f2,
        LogicalKeyboardKey.f3,
        LogicalKeyboardKey.f4,
        LogicalKeyboardKey.f5,
        LogicalKeyboardKey.f6,
        LogicalKeyboardKey.f7,
        LogicalKeyboardKey.f8,
        LogicalKeyboardKey.f9,
        LogicalKeyboardKey.f10,
        LogicalKeyboardKey.f11,
      ];
      final index = keys.indexOf(event.logicalKey);
      if (index != -1) {
        _switchTab(index);
        return true;
      }
    }
    return false;
  }

  void _switchTab(int index) {
    if (index >= 0 &&
        index < widget.navigationShell.route.branches.length &&
        widget.navigationShell.currentIndex != index) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  void _handleSelectTab(int index, bool isDesktop) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (isDesktop) {
      setState(() => _isSidebarExpanded = false);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      context.go('/dashboard');
      ref.invalidate(categoryProvider);
      ref.invalidate(rackProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(billingInventoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget buildSidebar() => CounterDashboardSidebar(
          isDesktop: isDesktop,
          isExpanded: _isSidebarExpanded,
          currentIndex: widget.navigationShell.currentIndex,
          onSelectIndex: (idx) => _handleSelectTab(idx, isDesktop),
          onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
          onLogout: _handleLogout,
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isDesktop ? null : Drawer(child: buildSidebar()),
        body: SafeArea(
          child: Column(
            children: [
              CounterDashboardHeader(
                isDesktop: isDesktop,
                currentTime: _currentTime,
                shopName: _shopName,
                onMenuPressed: () {
                  if (isDesktop) {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                },
                onLogout: _handleLogout,
              ),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) buildSidebar(),
                    Expanded(
                      child: Container(
                        color: scaffoldBg,
                        child: widget.navigationShell,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
