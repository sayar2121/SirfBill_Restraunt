import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../services/shop_service.dart';
import '../../../../services/inventory_service.dart';

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
              // 1. Branch / Outlet Badge Pill (Touch Optimized: 54px height)
              if (_shops.length > 1)
                PopupMenuButton<Shop>(
                  tooltip: 'Select Outlet / Branch',
                  onSelected: _selectShop,
                  itemBuilder: (ctx) => _shops.map((shop) {
                    final isCurrent = shop.id == _currentShopId;
                    return PopupMenuItem<Shop>(
                      value: shop,
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 22,
                            color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              shop.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent ? const Color(0xFF10B981) : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.check, size: 20, color: Color(0xFF10B981)),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 19, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            _branchName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 19, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          _branchName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 14),

              // 2. Touch Screen Search Bar: 54px height, large icon and touch target
              SizedBox(
                width: isMobile ? 240 : 340,
                height: 54,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 22, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => _onSearchChanged(val, ref),
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search food name or code (e.g. PBM)...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 3. Segmented Order Mode Selector (Touch Screen Optimized: 54px height)
              Container(
                height: 54,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOrderTypePill(
                      label: 'Dine-in',
                      icon: Icons.table_restaurant_rounded,
                      isSelected: posState.orderType == OrderType.dineIn,
                      onTap: () => posNotifier.setOrderType(OrderType.dineIn),
                      activeColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 5),
                    _buildOrderTypePill(
                      label: 'Takeaway',
                      icon: Icons.shopping_bag_rounded,
                      isSelected: posState.orderType == OrderType.takeaway,
                      onTap: () => posNotifier.setOrderType(OrderType.takeaway),
                      activeColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 5),
                    _buildOrderTypePill(
                      label: 'Delivery',
                      icon: Icons.moped_rounded,
                      isSelected: posState.orderType == OrderType.delivery,
                      onTap: () => posNotifier.setOrderType(OrderType.delivery),
                      activeColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 4. Large Touch-Friendly Refresh Button: 54x54px
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
                Tooltip(
                  message: 'Open Admin Panel',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go('/admin'),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1.4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF6366F1)),
                          SizedBox(width: 8),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // 5. Cashier Profile Pill: 54px height
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _cashierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _isAdmin ? 'Super Admin' : 'Counter POS',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.38),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
