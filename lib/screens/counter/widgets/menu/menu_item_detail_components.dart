import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

/// 1. Header image banner with gradient overlay, badges, and close button.
class MenuItemDetailHeader extends StatelessWidget {
  final PosMenuItem item;
  final String categoryName;
  final VoidCallback? onClose;

  const MenuItemDetailHeader({
    super.key,
    required this.item,
    required this.categoryName,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Image / Fallback
        SizedBox(
          height: 200,
          width: double.infinity,
          child: (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
              ? Image.network(
                  item.imageUrl!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackBanner(isDark),
                )
              : _buildFallbackBanner(isDark),
        ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Top Left: Stock status & Promo Badges
        Positioned(
          top: 12,
          left: 14,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isAvailable ? Icons.check_circle_rounded : Icons.block_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isAvailable ? 'In Stock' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.badge != null && item.badge!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.badge == 'Bestseller' ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Top Right: Close button
        Positioned(
          top: 10,
          right: 12,
          child: InkWell(
            onTap: onClose ?? () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),

        // Bottom Left: Veg/Non-Veg tag & Category pill
        Positioned(
          bottom: 12,
          left: 14,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuItemDietaryPill(isVeg: item.isVeg),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBanner(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 54,
          color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

/// 2. Reusable Veg / Non-Veg badge with circular color indicator.
class MenuItemDietaryPill extends StatelessWidget {
  final bool isVeg;

  const MenuItemDietaryPill({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final textColor = isVeg ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            isVeg ? 'VEG' : 'NON-VEG',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Dish Name, Short Code badge & Price with Tax percentage.
class MenuItemPriceHeader extends StatelessWidget {
  final PosMenuItem item;

  const MenuItemPriceHeader({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              if (item.shortCode != null && item.shortCode!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Item Code: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        item.shortCode!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${item.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
              ),
            ),
            Text(
              '+${item.taxPercent.toStringAsFixed(1)}% GST',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 4. Item Description Section with empty fallback state.
class MenuItemDescriptionSection extends StatelessWidget {
  final String? description;

  const MenuItemDescriptionSection({super.key, this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardInnerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final hasDescription = description != null && description!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 16,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 6),
            Text(
              'Item Description',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardInnerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: hasDescription
              ? Text(
                  description!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                )
              : Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No description provided for this item yet. Tap Edit below to add preparation details, ingredients, or taste notes.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// 5. Quick Specs Card row (Category, Tax Rate, Diet Type).
class MenuItemSpecsGrid extends StatelessWidget {
  final PosMenuItem item;
  final String categoryName;

  const MenuItemSpecsGrid({
    super.key,
    required this.item,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: MenuItemSpecCard(
            isDark: isDark,
            label: 'Category',
            value: categoryName,
            icon: Icons.category_outlined,
            accentColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MenuItemSpecCard(
            isDark: isDark,
            label: 'Tax Rate',
            value: '${item.taxPercent.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            accentColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MenuItemSpecCard(
            isDark: isDark,
            label: 'Diet Type',
            value: item.isVeg ? 'Vegetarian' : 'Non-Veg',
            icon: Icons.eco_outlined,
            accentColor: item.isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

/// 6. Individual spec card used in MenuItemSpecsGrid.
class MenuItemSpecCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const MenuItemSpecCard({
    super.key,
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 7. Action Buttons Footer: Toggle Stock, Delete, and Edit buttons.
class MenuItemActionsFooter extends StatelessWidget {
  final PosMenuItem item;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MenuItemActionsFooter({
    super.key,
    required this.item,
    required this.onToggleAvailability,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardInnerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardInnerBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              onToggleAvailability();
              Navigator.of(context).pop();
            },
            icon: Icon(
              item.isAvailable ? Icons.block_rounded : Icons.check_circle_rounded,
              size: 15,
            ),
            label: Text(
              item.isAvailable ? 'Mark Out of Stock' : 'Mark In Stock',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: item.isAvailable ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              side: BorderSide(
                color: item.isAvailable ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Delete Dish',
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Edit Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

