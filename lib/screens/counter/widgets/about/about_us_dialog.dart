import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_widgets.dart';

class AboutUsDialog extends StatelessWidget {
  const AboutUsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const AboutUsDialog(),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(320.0, 620.0);
    final dialogHeight = (screenSize.height * 0.85).clamp(400.0, 760.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Hero Banner
            AboutHeroHeader(onClose: () => Navigator.pop(context)),

            // 2. Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVELOPED & OPERATED BY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Organization Card
                    AboutCompanyCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'KEY SYSTEM HIGHLIGHTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Feature highlights grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 450;
                        final features = [
                          AboutFeatureCard(
                            icon: Icons.cloud_done_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Cloud-Powered',
                            desc: 'Live inventory sync & secure cloud backup',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          AboutFeatureCard(
                            icon: Icons.print_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'Universal Print',
                            desc: 'Thermal (58/80mm) & A4 PDF',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          AboutFeatureCard(
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFF059669),
                            title: 'GST Compliant',
                            desc: 'Instant tax & HSN tracking',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ];

                        if (isCompact) {
                          return Column(
                            children: features
                                .map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: f,
                                    ))
                                .toList(),
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: features[0]),
                            const SizedBox(width: 10),
                            Expanded(child: features[1]),
                            const SizedBox(width: 10),
                            Expanded(child: features[2]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'OFFICIAL CONTACT & SUPPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Support channels
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          AboutContactRow(
                            icon: Icons.business_rounded,
                            label: 'Organization',
                            value: 'NAIYO24 PVT. LTD.',
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          AboutContactRow(
                            icon: Icons.language_rounded,
                            label: 'Website',
                            value: 'www.naiyo24.com',
                            isLink: true,
                            onTap: () => _launchUrl('https://www.naiyo24.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          AboutContactRow(
                            icon: Icons.email_rounded,
                            label: 'Support Email',
                            value: 'services.naiyo@gmail.com',
                            isLink: true,
                            onTap: () => _launchUrl('mailto:services.naiyo@gmail.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          AboutContactRow(
                            icon: Icons.headset_mic_rounded,
                            label: 'Customer Support',
                            value: '+91 6289171798',
                            isLink: true,
                            onTap: () => _launchUrl('tel:+916289171798'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'LEGAL & COMPLIANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Privacy policy and Terms row
                    AboutLegalComplianceCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Footer with update checker & close
            AboutDialogFooter(
              borderColor: borderColor,
              subtitleColor: subtitleColor,
              onClose: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
