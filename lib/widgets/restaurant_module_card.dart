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
        final cardHeight = constraints.maxHeight;
        final isMobile = cardWidth < 210 || (cardHeight.isFinite && cardHeight < 190);
        final isCompact = isMobile || cardWidth < 240;

        final double horizontalPadding = isMobile ? 12.0 : (isCompact ? 14.0 : 20.0);
        final double topPadding = isMobile ? 12.0 : (isCompact ? 14.0 : 20.0);
        final double bottomPadding = isMobile ? 10.0 : (isCompact ? 14.0 : 20.0);
        final double iconBoxSize = isMobile ? 34.0 : (isCompact ? 40.0 : 48.0);
        final double iconSize = isMobile ? 18.0 : (isCompact ? 22.0 : 26.0);
        final double titleFontSize = isMobile ? 13.5 : (isCompact ? 15.5 : 18.0);
        final double descFontSize = isMobile ? 10.5 : (isCompact ? 11.5 : 12.5);
        final double cardRadius = isMobile ? 18.0 : 24.0;

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
              borderRadius: BorderRadius.circular(cardRadius),
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
                borderRadius: BorderRadius.circular(cardRadius),
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Top-right watermark number (01, 02, etc.)
                    Positioned(
                      top: isMobile ? 10 : (isCompact ? 14 : 18),
                      right: isMobile ? 12 : (isCompact ? 14 : 20),
                      child: Text(
                        widget.data.indexText,
                        style: TextStyle(
                          fontSize: isMobile ? 11.5 : (isCompact ? 12.5 : 15),
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
                              borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                            ),
                            child: Center(
                              child: Icon(
                                widget.data.icon,
                                color: primaryColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : (isCompact ? 14 : 18)),

                          // Title (2-line container for unified alignment across cards)
                          SizedBox(
                            height: isMobile ? 34 : (isCompact ? 40 : 46),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.data.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  height: 1.15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 2 : 4),

                          // Description
                          SizedBox(
                            height: isMobile ? 14 : (isCompact ? 34 : 40),
                            child: Text(
                              widget.data.description,
                              maxLines: isMobile ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: descFontSize,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                                color: descColor,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom Right "Open ->" Pill Button (pinned to bottom right corner)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : (isCompact ? 14 : 20),
                                vertical: isMobile ? 5 : (isCompact ? 7 : 9),
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
                                      fontSize: isMobile ? 10.5 : (isCompact ? 11.5 : 13),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 3 : 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: isMobile ? 11 : (isCompact ? 12 : 14),
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
