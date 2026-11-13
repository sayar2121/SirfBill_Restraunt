import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../services/shop_service.dart';
import '../../../../services/inventory_service.dart';
import 'pos_top_bar_components.dart';

/// Top App Bar for the POS Billing screen.
/// Refactored into reusable presentation components:
/// - [PosBranchSelector]: Branch / Outlet dropdown selector.
/// - [PosSearchBox]: Food dish search input box.
/// - [PosOrderTypeSelector]: Segmented order type switch (Dine-in, Takeaway, Delivery).
/// - [PosAdminButton]: Quick Admin Panel navigation button for administrators.
/// - [PosCashierProfilePill]: Cashier user avatar and role indicator.
class PosTopBar extends ConsumerStatefulWidget {
  final VoidCallback? onBranchChanged;
  final VoidCallback? onRefresh;
  const PosTopBar({super.key, this.onBranchChanged, this.onRefresh});

  @override
  ConsumerState<PosTopBar> createState() => _PosTopBarState();
}

class _PosTopBarState extends ConsumerState<PosTopBar> {
  String _branchName = 'Loading...';
  String _cashierName = 'Cashier';
  String _initials = 'AS';
  List<Shop> _shops = [];
  String? _currentShopId;
  bool _isAdmin = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val, WidgetRef ref) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(restaurantPosProvider.notifier).setSearchQuery(val);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadShops();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? prefs.getString('role_login_name');
    final role = prefs.getString('user_role');

    if (mounted) {
      setState(() {
        final normalizedRole = (role ?? '').trim().toUpperCase();
        _isAdmin = normalizedRole == 'ADMIN' || normalizedRole == 'OWNER' || normalizedRole == 'SUPER_ADMIN';
        if (name != null && name.trim().isNotEmpty) {
          _cashierName = name.trim();
          final parts = _cashierName.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            _initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          } else if (_cashierName.isNotEmpty) {
            _initials = _cashierName.substring(0, _cashierName.length >= 2 ? 2 : 1).toUpperCase();
          }
        } else if (role != null && role.isNotEmpty) {
          _cashierName = role[0].toUpperCase() + role.substring(1);
          _initials = _cashierName.substring(0, _cashierName.length >= 2 ? 2 : 1).toUpperCase();
        } else {
          _cashierName = 'Cashier';
          _initials = 'CS';
        }
      });
    }
  }

  Future<void> _loadShops() async {
    try {
      final allShops = await ShopService.getShops();
      final prefs = await SharedPreferences.getInstance();
      String? savedShopId = prefs.getString('selected_shop_id');
      final assignedOutletId = prefs.getString('assigned_outlet_id');
      final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();

      // Super Admin always has full access to ALL outlets; only restrict non-admin staff
      final isAdmin = role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN';
      final isRestrictedStaff = !isAdmin && (assignedOutletId != null && assignedOutletId.isNotEmpty);

      List<Shop> shops = allShops;
      final targetShopId = (assignedOutletId != null && assignedOutletId.isNotEmpty)
          ? assignedOutletId
          : savedShopId;

      // When the user has an assigned outlet or is a cashier/staff, only show their outlet
      if (isRestrictedStaff && targetShopId != null && targetShopId.isNotEmpty) {
        final filtered = allShops.where((s) => s.id == targetShopId).toList();
        if (filtered.isNotEmpty) {
          shops = filtered;
          savedShopId = targetShopId;
          await prefs.setString('selected_shop_id', targetShopId);
          await InventoryService.setShopId(targetShopId);
        }
      }

      if (savedShopId == null || savedShopId.isEmpty) {
        if (shops.isNotEmpty) {
          savedShopId = shops.first.id;
          await prefs.setString('selected_shop_id', savedShopId);
          await InventoryService.setShopId(savedShopId);
        }
      }

      Shop? currentShop;
      if (shops.isNotEmpty) {
        currentShop = shops.firstWhere(
          (s) => s.id == savedShopId,
          orElse: () => shops.first,
        );
      }

      if (mounted) {
        setState(() {
          _shops = shops;
          _currentShopId = currentShop?.id ?? savedShopId;
          _branchName = currentShop?.name ?? (shops.isNotEmpty ? shops.first.name : 'Main Branch');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _branchName = 'Main Branch';
        });
      }
    }
  }

  Future<void> _selectShop(Shop shop) async {
    await InventoryService.setShopId(shop.id);
    setState(() {
      _currentShopId = shop.id;
      _branchName = shop.name;
    });
    widget.onBranchChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(restaurantPosProvider);
    final posNotifier = ref.read(restaurantPosProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 82,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Branch / Outlet Selector Pill
              PosBranchSelector(
                shops: _shops,
                currentShopId: _currentShopId,
                branchName: _branchName,
                onSelectShop: _selectShop,
              ),
              const SizedBox(width: 14),

              // 2. Search Bar
              PosSearchBox(
                onChanged: (val) => _onSearchChanged(val, ref),
                isMobile: isMobile,
              ),
              const SizedBox(width: 14),

              // 3. Segmented Order Mode Selector
              PosOrderTypeSelector(
                selectedType: posState.orderType,
                onSelectType: posNotifier.setOrderType,
              ),
              const SizedBox(width: 14),

              // 4. Refresh Button
              if (widget.onRefresh != null) ...[
                Tooltip(
                  message: 'Refresh Menu & POS',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.onRefresh,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.4),
                      ),
                      child: const Center(
                        child: Icon(Icons.refresh_rounded, size: 24, color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // Quick Admin Panel Switcher for Super Admin
              if (_isAdmin) ...[
                PosAdminButton(
                  onTap: () => context.go('/admin'),
                ),
                const SizedBox(width: 14),
              ],

              // 5. Cashier Profile Pill
              PosCashierProfilePill(
                cashierName: _cashierName,
                initials: _initials,
                isAdmin: _isAdmin,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
