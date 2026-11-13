import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable square icon action button with tooltip and tap feedback
class KdsIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;
  final Color borderColor;
  final double size;

  const KdsIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
    required this.borderColor,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: size * 0.48, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Reusable pill action button that adapts between compact icon and full pill with label
class KdsPillButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isCompact;
  final double size;

  const KdsPillButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isCompact,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: size,
            width: isCompact ? size : null,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: size * 0.46, color: color),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable search field with clear suffix icon and debounced input
class KdsSearchInput extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final bool isDark;
  final Color borderColor;
  final double height;
  final String hintText;

  const KdsSearchInput({
    super.key,
    required this.onSearch,
    required this.isDark,
    required this.borderColor,
    this.height = 38,
    this.hintText = 'Search KOT / table / item...',
  });

  @override
  State<KdsSearchInput> createState() => _KdsSearchInputState();
}

class _KdsSearchInputState extends State<KdsSearchInput> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => widget.onSearch(val));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        style: const TextStyle(fontSize: 12.5),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Color(0xFF94A3B8)),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                    setState(() {});
                  },
                )
              : null,
          hintText: widget.hintText,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.6),
          ),
        ),
      ),
    );
  }
}

/// Composite row of KDS actions (Sound, Sync, Export, Exit)
class KdsHeaderActions extends StatelessWidget {
  final bool isCompact;
  final bool isMobile;
  final bool isDark;
  final Color borderColor;
  final bool isSoundEnabled;
  final VoidCallback? onToggleSound;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final bool isStandalone;
  final VoidCallback? onExitStandalone;

  const KdsHeaderActions({
    super.key,
    required this.isCompact,
    required this.isMobile,
    required this.isDark,
    required this.borderColor,
    required this.isSoundEnabled,
    required this.onToggleSound,
    required this.onRefresh,
    required this.onExport,
    required this.isStandalone,
    required this.onExitStandalone,
  });

  @override
  Widget build(BuildContext context) {
    final size = isMobile ? 34.0 : (isCompact ? 36.0 : 38.0);
    final gap = isMobile ? 6.0 : 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggleSound != null) ...[
          KdsIconButton(
            tooltip: isSoundEnabled ? 'Sound Alerts: ON' : 'Sound Alerts: OFF',
            icon: isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            iconColor: isSoundEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            onTap: onToggleSound!,
            isDark: isDark,
            borderColor: borderColor,
            size: size,
          ),
          SizedBox(width: gap),
        ],
        KdsIconButton(
          tooltip: 'Sync live tickets now',
          icon: Icons.refresh_rounded,
          iconColor: const Color(0xFFF97316),
          onTap: onRefresh,
          isDark: isDark,
          borderColor: borderColor,
          size: size,
        ),
        if (onExport != null) ...[
          SizedBox(width: gap),
          KdsPillButton(
            tooltip: 'Export kitchen data (Excel / PDF)',
            icon: Icons.file_download_outlined,
            label: 'Export Data',
            color: const Color(0xFF10B981),
            onTap: onExport!,
            isCompact: isCompact,
            size: size,
          ),
        ],
        if (isStandalone && onExitStandalone != null) ...[
          SizedBox(width: gap),
          KdsPillButton(
            tooltip: 'Exit Kitchen Mode / Logout',
            icon: Icons.logout_rounded,
            label: 'Exit',
            color: const Color(0xFFEF4444),
            onTap: onExitStandalone!,
            isCompact: isCompact,
            size: size,
          ),
        ],
      ],
    );
  }
}

