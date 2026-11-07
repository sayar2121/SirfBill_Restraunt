import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/auth/role_login_screen.dart';
import '../screens/counter/counter_dashboard.dart';
import '../screens/counter/billing_screen.dart';
import '../screens/counter/customers_screen.dart';
// import '../screens/counter/accounts_screen.dart';
import '../screens/counter/bill_customization_screen.dart';
import '../screens/counter/table_management_screen.dart';
import '../screens/counter/order_management_screen.dart';
import '../screens/counter/kitchen_display_screen.dart';
import '../screens/counter/menu_management_screen.dart';
import '../screens/counter/reports_screen.dart';
import '../screens/admin/restaurant_admin_panel_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final isLoggedIn = token != null && token.isNotEmpty;
    
    final loc = state.matchedLocation;
    final isPublicRoute = loc == '/role_login' || loc == '/splash' || loc == '/dashboard';

    // If not logged in and not on a public route, redirect to dashboard
    if (!isLoggedIn && !isPublicRoute) {
      return '/dashboard';
    }

    // Redirect disabled inventory route to billing
    if (loc.startsWith('/counter/inventory')) {
      return '/counter/billing';
    }

    // Auto-forward from splash based on role
    if (loc == '/splash') {
      if (isLoggedIn) {
        final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();
        if (role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN') {
          return '/admin';
        } else if (role == 'KITCHEN' || role == 'CHEF' || role == 'KDS') {
          return '/kitchen';
        }
        return '/counter/billing';
      }
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const RestaurantAdminPanelScreen(),
    ),
    GoRoute(
      path: '/kitchen',
      builder: (context, state) => const KitchenDisplayScreen(isStandalone: true),
    ),
    GoRoute(
      path: '/role_login',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : {};
        return RoleLoginScreen(
          roleName: extra['roleName'] is String
              ? extra['roleName'] as String
              : 'Restaurant POS',
          themeColor: extra['themeColor'] is Color
              ? extra['themeColor'] as Color
              : const Color(0xFF10B981),
          nextRoute: extra['nextRoute'] is String
              ? extra['nextRoute'] as String
              : '/counter/billing',
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CounterDashboard(navigationShell: navigationShell);
      },
      branches: [
        // 0: POS Billing
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/billing',
              builder: (context, state) => const BillingScreen(),
            ),
          ],
        ),
        // 1: Tables
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/tables',
              builder: (context, state) => const TableManagementScreen(),
            ),
          ],
        ),
        // 2: Orders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/orders',
              builder: (context, state) => const OrderManagementScreen(),
            ),
          ],
        ),
        // 3: Kitchen (KOT)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/kitchen',
              builder: (context, state) => const KitchenDisplayScreen(),
            ),
          ],
        ),
        // 4: Menu Management
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/menu',
              builder: (context, state) => const MenuManagementScreen(),
            ),
          ],
        ),
        // 5: Customers (CRM)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/customers',
              builder: (context, state) => const CustomersScreen(),
            ),
          ],
        ),
        // 6: Inventory (Commented out - not required for this restaurant POS)
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: '/counter/inventory',
        //       builder: (context, state) => const InventoryScreen(),
        //       routes: [
        //         GoRoute(
        //           path: 'upload',
        //           builder: (context, state) => const UploadManagementScreen(),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
        // 6: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
        // 7: Expenses (Commented out)
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: '/counter/expenses',
        //       builder: (context, state) => const AccountsScreen(),
        //     ),
        //   ],
        // ),
        // 8: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/settings',
              builder: (context, state) => const BillCustomizationScreen(),
            ),
          ],
        ),
      ],
    ),

  ],
);
