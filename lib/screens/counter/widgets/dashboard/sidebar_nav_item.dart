import 'package:flutter/material.dart';

class SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool isSelected;
  final bool isExpanded;
  final bool isDesktop;
  final VoidCallback onTap;
  final Color? customTextColor;
  final Color? customIconColor;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.shortcut,
    this.isSelected = false,
    required this.isExpanded,
    required this.isDesktop,
    required this.onTap,
    this.customTextColor,
    this.customIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemBgSelected = isDark
        ? const Color(0xFF166534).withValues(alpha: 0.2)
        : const Color(0xFFE8F5E9);
    final itemBorderSelected = isDark
        ? const Color(0xFF22C55E).withValues(alpha: 0.5)
        : const Color(0xFF22C55E).withValues(alpha: 0.3);

    final iconColorSelected = customIconColor ??
        (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534));
    final iconColorUnselected = customIconColor ??
        (isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B));

    final textColorSelected = customTextColor ??
        (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534));
    final textColorUnselected = customTextColor ??
        (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B));

    final shortcutColor = isDark
        ? const Color(0xFF64748B) // Slate 500, clean readable muted text on dark background
        : const Color(0xFF94A3B8);
    final shortcutColorSelected = isDark
        ? const Color(0xFF4ADE80) // Vibrant emerald green matching selected item
        : const Color(0xFF166534).withValues(alpha: 0.7);

    Widget content = Container(
      width: isDesktop ? (isExpanded ? 228 : 48) : double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 16 : 0,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isSelected ? itemBgSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: itemBorderSelected, width: 1)
            : null,
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: isExpanded
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        alignment: Alignment.centerLeft,
        firstChild: isDesktop
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? iconColorSelected : iconColorUnselected,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? textColorSelected : textColorUnselected,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (shortcut != null)
                            Text(
                              shortcut!,
                              style: TextStyle(
                                color: isSelected ? shortcutColorSelected : shortcutColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? iconColorSelected : iconColorUnselected,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? textColorSelected : textColorUnselected,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (shortcut != null)
                          Text(
                            shortcut!,
                            style: TextStyle(
                              color: isSelected ? shortcutColorSelected : shortcutColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        secondChild: Center(
          child: Icon(
            icon,
            color: isSelected ? iconColorSelected : iconColorUnselected,
            size: 20,
          ),
        ),
      ),
    );

    if (!isExpanded) {
      content = Tooltip(message: label, child: content);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
