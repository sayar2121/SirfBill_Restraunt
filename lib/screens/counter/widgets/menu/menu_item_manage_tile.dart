import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../utils/app_image_cache_manager.dart';
import '../pos/pos_menu_card.dart';

class MenuItemManageTile extends StatelessWidget {
  final PosMenuItem item;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const MenuItemManageTile({
    super.key,
    required this.item,
    required this.categoryName,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isAvailable ? borderColor : const Color(0xFFEF4444).withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Food Image + Badge + Availability (Matches PosMenuCard flex 5)
              Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: () {
                    final img = (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                        ? item.imageUrl!.trim()
                        : PosMenuCard.foodImages[item.name];
                    return (img != null && img.isNotEmpty)
                        ? CachedAppImage(
                            url: img,
                            fit: BoxFit.cover,
                            cacheWidth: 340,
                            cacheHeight: 240,
                            errorBuilder: (_, isDark) => _buildFallbackImage(isDark),
                          )
                        : _buildFallbackImage(isDark);
                  }(),
                ),

                // Badge (e.g. Popular, Bestseller - identical to PosMenuCard)
                if (item.badge != null && item.badge!.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.badge == 'Bestseller' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Top Right: Stock Status Indicator
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? const Color(0xFF10B981).withValues(alpha: 0.9)
                          : const Color(0xFFEF4444).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.isAvailable ? 'In Stock' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Toggle availability quick overlay button (bottom right of image)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Tooltip(
                    message: item.isAvailable ? 'Mark Out of Stock' : 'Mark In Stock',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onToggleAvailability,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          item.isAvailable ? Icons.check_circle_rounded : Icons.block_rounded,
                          size: 14,
                          color: item.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Name & Price & Edit Actions (Matches PosMenuCard flex 3)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Veg indicator + Dish Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom row: Price, Short Code and Edit / Delete actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹ ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          if (item.shortCode != null && item.shortCode!.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item.shortCode!,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Edit Item',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: onEdit,
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFF3B82F6)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Delete Item',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: onDelete,
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildFallbackImage(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 32,
          color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
