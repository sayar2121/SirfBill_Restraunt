import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/app_session_manager.dart';
import '../../services/shop_service.dart';
import '../../services/inventory_service.dart';
import '../../services/admin_staff_service.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_header.dart';
import 'widgets/admin_dashboard_tab.dart';
import 'widgets/admin_outlets_tab.dart';
import 'widgets/admin_users_tab.dart';
import 'widgets/admin_dialogs.dart';

class RestaurantAdminPanelScreen extends ConsumerStatefulWidget {
  const RestaurantAdminPanelScreen({super.key});

  @override
  ConsumerState<RestaurantAdminPanelScreen> createState() => _RestaurantAdminPanelScreenState();
}

class _RestaurantAdminPanelScreenState extends ConsumerState<RestaurantAdminPanelScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  List<Shop> _branches = [];
  List<RestaurantStaffUser> _staffUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _userName = '';
  String? _activeShopId;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final branchesFuture = ShopService.getShops();
      final staffFuture = AdminStaffService.getStaffUsers();
      final nameFuture = AuthService.getUserName();
      final shopIdFuture = InventoryService.getShopId();

      final results = await Future.wait([branchesFuture, staffFuture, nameFuture, shopIdFuture]);
      if (mounted) {
        setState(() {
          _branches = results[0] as List<Shop>;
          _staffUsers = results[1] as List<RestaurantStaffUser>;
          _userName = (results[2] as String?) ?? '';
          _activeShopId = results[3] as String?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Logout Admin Session'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the Admin Panel and return to the main dashboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AppSessionManager.resetSession(ref: ref);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _showAddBranchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddBranchDialog(onSaved: _loadAdminData),
    );
  }

  void _showEditBranchDialog(Shop branch) {
    showDialog(
      context: context,
      builder: (ctx) => AddBranchDialog(
        existingBranch: branch,
        onSaved: _loadAdminData,
      ),
    );
  }

  Future<void> _handleDeleteBranch(Shop branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Outlet'),
          ],
        ),
        content: Text('Are you sure you want to delete "${branch.name}" (${branch.code})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ShopService.deleteShop(
          branch.id,
          code: branch.code,
          name: branch.name,
        );
        _loadAdminData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Outlet "${branch.name}" deleted successfully.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete outlet: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSelectActiveBranch(Shop branch) async {
    await InventoryService.setShopId(branch.id);
    if (mounted) {
      setState(() => _activeShopId = branch.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active branch set to "${branch.name}". All POS & inventory operations now point to this outlet.'),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddStaffUserDialog(
        branches: _branches,
        onSaved: _loadAdminData,
      ),
    );
  }

  void _showEditUserDialog(RestaurantStaffUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AddStaffUserDialog(
        existingUser: user,
        branches: _branches,
        onSaved: _loadAdminData,
      ),
    );
  }

  Future<void> _handleDeleteUser(RestaurantStaffUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Staff User'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete user account "${user.name}" (${user.username})? This user will no longer be able to log in to POS or Admin.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminStaffService.deleteStaffUser(user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff user "${user.name}" deleted successfully.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadAdminData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user "${user.name}".'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final sidebarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          // 1. REUSABLE SIDEBAR COMPONENT
          AdminSidebar(
            isDark: isDark,
            isCollapsed: _isSidebarCollapsed,
            selectedIndex: _selectedIndex,
            onSelectIndex: (idx) => setState(() => _selectedIndex = idx),
            onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            onLogout: _handleLogout,
            sidebarBg: sidebarBg,
            borderColor: borderColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),

          // 2. MAIN WORKSPACE CONTENT
          Expanded(
            child: Column(
              children: [
                // TOP HEADER COMPONENT
                AdminTopHeader(
                  selectedIndex: _selectedIndex,
                  onRefresh: _loadAdminData,
                  onLaunchPos: () => context.go('/counter/billing'),
                  onLogout: _handleLogout,
                  userName: _userName,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),

                // WORKSPACE TABS VIEW
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                        )
                      : IndexedStack(
                          index: _selectedIndex,
                          children: [
                            // TAB 0: DASHBOARD
                            AdminDashboardTab(
                              branches: _branches,
                              staffCount: _staffUsers.length,
                              onAddBranch: _showAddBranchDialog,
                              onAddUser: _showAddUserDialog,
                              onViewAllBranches: () => setState(() => _selectedIndex = 1),
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            ),

                            // TAB 1: OUTLETS & BRANCHES
                            AdminOutletsTab(
                              branches: _branches,
                              onAddBranch: _showAddBranchDialog,
                              onEditBranch: _showEditBranchDialog,
                              onDeleteBranch: _handleDeleteBranch,
                              onSelectActiveBranch: _handleSelectActiveBranch,
                              activeShopId: _activeShopId,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            ),

                            // TAB 2: USERS & ROLES
                            AdminUsersTab(
                              staffUsers: _staffUsers,
                              searchQuery: _searchQuery,
                              onSearchChanged: (val) => setState(() => _searchQuery = val),
                              onAddUser: _showAddUserDialog,
                              onEditUser: _showEditUserDialog,
                              onDeleteUser: _handleDeleteUser,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
