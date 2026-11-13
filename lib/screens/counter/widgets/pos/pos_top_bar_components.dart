import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/shop_service.dart';

/// 1. Outlet / Branch selector pill with popup menu.
class PosBranchSelector extends StatelessWidget {
  final List<Shop> shops;
  final String? currentShopId;
  final String branchName;
  final ValueChanged<Shop> onSelectShop;

  const PosBranchSelector({
    super.key,
    required this.shops,
    required this.currentShopId,
    required this.branchName,
    required this.onSelectShop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final content = Container(
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
              branchName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (shops.length > 1) ...[
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ],
      ),
    );

    if (shops.length <= 1) return content;

    return PopupMenuButton<Shop>(
      tooltip: 'Select Outlet / Branch',
      onSelected: onSelectShop,
      itemBuilder: (ctx) => shops.map((shop) {
        final isCurrent = shop.id == currentShopId;
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
      child: content,
    );
  }
}

/// 2. Touch Screen Search Bar with large touch target.
class PosSearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isMobile;

  const PosSearchBox({
    super.key,
    required this.onChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
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
                onChanged: onChanged,
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
    );
  }
}

/// 3. Segmented Order Mode Selector (Dine-in, Takeaway, Delivery).
class PosOrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final ValueChanged<OrderType> onSelectType;

  const PosOrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          PosOrderTypePill(
            label: 'Dine-in',
            icon: Icons.table_restaurant_rounded,
            isSelected: selectedType == OrderType.dineIn,
            onTap: () => onSelectType(OrderType.dineIn),
            activeColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 5),
          PosOrderTypePill(
            label: 'Takeaway',
            icon: Icons.shopping_bag_rounded,
            isSelected: selectedType == OrderType.takeaway,
            onTap: () => onSelectType(OrderType.takeaway),
            activeColor: const Color(0xFF10B981),
          ),
          const SizedBox(width: 5),
          PosOrderTypePill(
            label: 'Delivery',
            icon: Icons.moped_rounded,
            isSelected: selectedType == OrderType.delivery,
            onTap: () => onSelectType(OrderType.delivery),
            activeColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

/// 4. Individual order type pill.
class PosOrderTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const PosOrderTypePill({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

/// 5. Admin Panel shortcut pill for administrators.
class PosAdminButton extends StatelessWidget {
  final VoidCallback onTap;

  const PosAdminButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Open Admin Panel',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
    );
  }
}

/// 6. Cashier Profile badge with circular avatar and role label.
class PosCashierProfilePill extends StatelessWidget {
  final String cashierName;
  final String initials;
  final bool isAdmin;
  final bool isMobile;

  const PosCashierProfilePill({
    super.key,
    required this.cashierName,
    required this.initials,
    required this.isAdmin,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
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
                initials,
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
                    cashierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    isAdmin ? 'Super Admin' : 'Counter POS',
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
    );
  }
}

