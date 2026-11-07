import 'package:flutter/material.dart';

class AboutFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color? subtitleColor;

  const AboutFeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: subtitleColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AboutContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? subtitleColor;

  const AboutContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
    required this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF166534)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLink ? const Color(0xFF2563EB) : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

