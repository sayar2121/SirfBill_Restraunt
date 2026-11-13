import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'menu_item_detail_components.dart';

/// Modal dialog that presents detailed information for a selected menu item.
/// Refactored into reusable presentation components:
/// - [MenuItemDetailHeader]: Top image, status badges, close button, and category tag.
/// - [MenuItemPriceHeader]: Item name, code chip, price, and GST details.
/// - [MenuItemDescriptionSection]: Formatted dish description with empty state.
/// - [MenuItemSpecsGrid]: Category, tax rate, and dietary classification chips.
/// - [MenuItemActionsFooter]: Stock status toggle, delete, and edit action triggers.
class MenuItemDetailModal extends StatelessWidget {
  final PosMenuItem item;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;

  const MenuItemDetailModal({
    super.key,
    required this.item,
    required this.categoryName,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Image / Banner with Badges & Close Button
            MenuItemDetailHeader(
              item: item,
              categoryName: categoryName,
            ),

            // 2. Content Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dish Name, Short Code, and Price
                    MenuItemPriceHeader(item: item),

                    const SizedBox(height: 16),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 16),

                    // Item Description Section
                    MenuItemDescriptionSection(description: item.description),

                    const SizedBox(height: 16),

                    // Quick Specs Grid (Category, Tax Rate, Diet Type)
                    MenuItemSpecsGrid(
                      item: item,
                      categoryName: categoryName,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Action Buttons Footer
            MenuItemActionsFooter(
              item: item,
              onToggleAvailability: onToggleAvailability,
              onDelete: onDelete,
              onEdit: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
