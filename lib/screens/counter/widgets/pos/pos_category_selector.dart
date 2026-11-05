import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class PosCategorySelector extends StatefulWidget {
  final String activeCategoryId;
  final ValueChanged<String> onSelectCategory;
  final List<MenuCategory>? categories;

  const PosCategorySelector({
    super.key,
    required this.activeCategoryId,
    required this.onSelectCategory,
    this.categories,
  });

  @override
  State<PosCategorySelector> createState() => _PosCategorySelectorState();
}

class _PosCategorySelectorState extends State<PosCategorySelector> {
  final ScrollController _scrollController = ScrollController();

  static const List<MenuCategory> _emptyList = [
    MenuCategory(id: 'all', name: 'All Items', iconEmoji: '🍱'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = (widget.categories != null && widget.categories!.isNotEmpty) ? widget.categories! : _emptyList;

    return SizedBox(
      height: 84,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final cat = list[index];
            final isSelected = cat.id == widget.activeCategoryId;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onSelectCategory(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.iconEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
