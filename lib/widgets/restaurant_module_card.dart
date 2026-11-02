import 'package:flutter/material.dart';

class ModuleCardData {
  final String indexText;
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final String nextRoute;
  final bool isComingSoon;

  const ModuleCardData({
    required this.indexText,
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.nextRoute,
    this.isComingSoon = false,
  });
}

class RestaurantModuleCard extends StatefulWidget {
  final ModuleCardData data;
  final VoidCallback onTap;
  final bool isDark;

  const RestaurantModuleCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<RestaurantModuleCard> createState() => _RestaurantModuleCardState();
}

class _RestaurantModuleCardState extends State<RestaurantModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = widget.data.primaryColor;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 220;

        final double horizontalPadding = isCompact ? 16.0 : 22.0;
        final double topPadding = isCompact ? 16.0 : 22.0;
        final double bottomPadding = isCompact ? 16.0 : 22.0;
        final double iconBoxSize = isCompact ? 44.0 : 52.0;
        final double iconSize = isCompact ? 24.0 : 28.0;
        final double titleFontSize = isCompact ? 17.0 : 19.0;
        final double descFontSize = isCompact ? 12.0 : 13.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0.0, _isHovered ? -6.0 : 0.0, 0.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? primaryColor.withValues(alpha: 0.55)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? primaryColor.withValues(alpha: 0.22)
                      : (isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.06)),
                  blurRadius: _isHovered ? 26 : 14,
                  offset: Offset(0, _isHovered ? 12 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Top-right watermark number (01, 02, etc.)
                    Positioned(
                      top: 18,
                      right: 20,
                      child: Text(
                        widget.data.indexText,
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: primaryColor.withValues(alpha: 0.75),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Card Content
                    Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: topPadding,
                        bottom: bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Badge
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                widget.data.icon,
                                color: primaryColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Title
                          Text(
                            widget.data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Description
                          Text(
                            widget.data.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: descFontSize,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: descColor,
                            ),
                          ),

                          const Spacer(),

                          // Bottom Right "Open ->" Pill Button (pinned to bottom right corner)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 16 : 22,
                                vertical: isCompact ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: _isHovered ? 0.45 : 0.28),
                                    blurRadius: _isHovered ? 14 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Open',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isCompact ? 12 : 13,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: isCompact ? 13 : 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
