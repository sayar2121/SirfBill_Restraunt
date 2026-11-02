import 'package:flutter/material.dart';

/// Information teaser card for upcoming Multi-Branch management features.
class MultiBranchTeaserCard extends StatelessWidget {
  final bool isDark;

  const MultiBranchTeaserCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.hub_rounded,
              size: 72,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Multi-Branch Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We are designing a powerful new way for you\nto manage multiple\nprint shop branches from a single unified\ndashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
