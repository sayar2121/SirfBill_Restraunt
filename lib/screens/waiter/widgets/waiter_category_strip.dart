import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';

class WaiterCategoryStrip extends StatelessWidget {
  final List<MenuCategory> categories;
  final String selectedCategory;
  final String searchQuery;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const WaiterCategoryStrip({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.onSelectCategory,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  String _getCategoryEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani')) return '🍲 ';
    if (lower.contains('tandoor') || lower.contains('tikka') || lower.contains('kebab')) return '🍗 ';
    if (lower.contains('pizza')) return '🍕 ';
    if (lower.contains('bread') || lower.contains('naan') || lower.contains('roti')) return '🫓 ';
    if (lower.contains('dessert') || lower.contains('sweet') || lower.contains('ice cream')) return '🍨 ';
    if (lower.contains('drink') || lower.contains('beverage') || lower.contains('tea') || lower.contains('coffee')) return '🥤 ';
    if (lower.contains('chinese') || lower.contains('noodle') || lower.contains('rice')) return '🥢 ';
    if (lower.contains('curry') || lower.contains('gravy') || lower.contains('indian')) return '🍛 ';
    if (lower.contains('snack') || lower.contains('starter')) return '🥟 ';
    return '🍽️ ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Deduplicate 'All Items'
    final displayCats = categories.where((c) =>
        c.id.toLowerCase() != 'all' &&
        c.name.trim().toLowerCase() != 'all items').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Search Bar with Clear Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: searchQuery,
                  selection: TextSelection.collapsed(offset: searchQuery.length),
                ),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                prefixIcon: const Icon(Icons.search_rounded, size: 19, color: Color(0xFFF59E0B)),
                hintText: 'Search dishes, code, or ingredients...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.normal,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Horizontal Category Strip
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: displayCats.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final catId = isAll ? 'all' : displayCats[index - 1].id;
              final catName = isAll ? 'All Items' : displayCats[index - 1].name;
              final emoji = isAll ? '🍽️ ' : _getCategoryEmoji(catName);
              final isSelected = selectedCategory == catId;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelectCategory(catId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: 1.1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: isDark ? Colors.black12 : const Color(0xFF0F172A).withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          catName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
