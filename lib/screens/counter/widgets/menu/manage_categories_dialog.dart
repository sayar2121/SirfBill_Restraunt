import 'package:flutter/material.dart';

import '../../../../models/restaurant_pos_models.dart';

class ManageCategoriesDialog extends StatelessWidget {
  final List<MenuCategory> categories;
  final VoidCallback? onAddCategory;
  final ValueChanged<MenuCategory>? onEditCategory;
  final ValueChanged<MenuCategory>? onDeleteCategory;

  const ManageCategoriesDialog({
    super.key,
    required this.categories,
    this.onAddCategory,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  static Future<void> show({
    required BuildContext context,
    required List<MenuCategory> categories,
    VoidCallback? onAddCategory,
    ValueChanged<MenuCategory>? onEditCategory,
    ValueChanged<MenuCategory>? onDeleteCategory,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ManageCategoriesDialog(
        categories: categories,
        onAddCategory: onAddCategory,
        onEditCategory: onEditCategory,
        onDeleteCategory: onDeleteCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customCats = categories.where((c) => c.id != 'all').toList();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Manage Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (onAddCategory != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onAddCategory!();
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add New', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                elevation: 0,
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: customCats.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No custom categories created yet.\nClick "+ Category" to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: customCats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final cat = customCats[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cat.iconEmoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEditCategory != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                            tooltip: 'Edit Category',
                            onPressed: () {
                              Navigator.pop(context);
                              onEditCategory!(cat);
                            },
                          ),
                        if (onDeleteCategory != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'Delete Category',
                            onPressed: () {
                              Navigator.pop(context);
                              onDeleteCategory!(cat);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

