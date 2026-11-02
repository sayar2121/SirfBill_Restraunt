import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/windows_auto_updater.dart';

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

  void _showPolicyDialog(BuildContext context, {required String title, required String content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFF166534), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF166534);
    const accentGreen = Color(0xFF22C55E);
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
            // Header Hero Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, Color(0xFF15803D), accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Product Icon Box
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/icon.png',
                            height: 48,
                            width: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.receipt_long_rounded,
                              color: primaryGreen,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'SirfBill',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FutureBuilder<PackageInfo>(
                                  future: PackageInfo.fromPlatform(),
                                  builder: (context, snapshot) {
                                    final version = snapshot.hasData
                                        ? snapshot.data!.version
                                        : '1.0.3';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'v$version',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Bill Karo, Befikar Raho',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization Section with Official Logo
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/naiyo24_logo.jpeg',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) {
                                  debugPrint('Error loading naiyo24_logo.jpeg: $err');
                                  return const Center(
                                    child: Text(
                                      'NAIYO24',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NAIYO24 PVT. LTD.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Empowering businesses with modern point-of-sale and digital automation platforms.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtitleColor,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Key Highlights
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 450;
                        if (isCompact) {
                          return Column(
                            children: [
                              _buildFeatureCard(
                                icon: Icons.cloud_done_rounded,
                                iconColor: const Color(0xFF0284C7),
                                title: 'Cloud-Powered',
                                desc: 'Live inventory sync & secure cloud backup',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureCard(
                                icon: Icons.print_rounded,
                                iconColor: const Color(0xFF2563EB),
                                title: 'Universal Print',
                                desc: 'Thermal (58/80mm) & A4 PDF',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureCard(
                                icon: Icons.shield_rounded,
                                iconColor: const Color(0xFF059669),
                                title: 'GST Compliant',
                                desc: 'Instant tax & HSN tracking',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.cloud_done_rounded,
                                iconColor: const Color(0xFF0284C7),
                                title: 'Cloud-Powered',
                                desc: 'Live inventory sync & secure cloud backup',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.print_rounded,
                                iconColor: const Color(0xFF2563EB),
                                title: 'Universal Print',
                                desc: 'Thermal (58/80mm) & A4 PDF',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.shield_rounded,
                                iconColor: const Color(0xFF059669),
                                title: 'GST Compliant',
                                desc: 'Instant tax & HSN tracking',
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Official Contact & Support
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildContactRow(
                            icon: Icons.business_rounded,
                            label: 'Organization',
                            value: 'NAIYO24 PVT. LTD.',
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          _buildContactRow(
                            icon: Icons.language_rounded,
                            label: 'Website',
                            value: 'www.naiyo24.com',
                            isLink: true,
                            onTap: () => _launchUrl('https://www.naiyo24.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          _buildContactRow(
                            icon: Icons.email_rounded,
                            label: 'Support Email',
                            value: 'services.naiyo@gmail.com',
                            isLink: true,
                            onTap: () => _launchUrl('mailto:services.naiyo@gmail.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 16, color: borderColor),
                          _buildContactRow(
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

                    // Legal / Policies section
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showPolicyDialog(
                                context,
                                title: 'Privacy Policy',
                                content: '''
NAIYO24 PVT. LTD. Privacy Policy

Last Updated: October 2026

1. Data Collection & Processing
SirfBill processes transaction and inventory data solely for the operation of your business, generating invoices, maintaining customer ledger, and managing inventory stock.

2. Offline & Local Storage
All your operational data, receipts, and invoices are securely stored in your local device and securely synchronized with authenticated cloud endpoints.

3. Customer Privacy
Customer phone numbers, addresses, and purchase histories are collected solely for billing and communication at your explicit discretion. We never sell, lease, or share your merchant or customer data with third parties.

4. Security & Encryption
Communications between SirfBill and server backends are strictly encrypted with TLS/SSL protocols. 

For inquiries regarding data privacy, please contact: services.naiyo@gmail.com.
''',
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.privacy_tip_outlined, size: 16, color: primaryGreen),
                                    SizedBox(width: 8),
                                    Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(height: 20, width: 1, color: borderColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showPolicyDialog(
                                context,
                                title: 'Terms & Conditions',
                                content: '''
NAIYO24 PVT. LTD. Terms & Conditions

1. License & Usage
SirfBill is licensed to your registered enterprise for point-of-sale billing, inventory auditing, customer records, and tax calculations. Unauthorized reverse engineering or redistribution is strictly prohibited.

2. Accuracy of Financial Records
While SirfBill provides automated GST, discount, and tax calculations, the user/merchant is solely responsible for verifying the regulatory compliance and accuracy of their tax filings and invoices.

3. Software Updates & Maintenance
NAIYO24 PVT. LTD. regularly issues software updates for performance, security, and feature improvements. Users are encouraged to maintain the latest version for optimum stability.

4. Support & Service
Customer assistance is provided through official support channels:
- Email: services.naiyo@gmail.com
- Hotline: +91 6289171798
- Website: www.naiyo24.com
''',
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.gavel_rounded, size: 16, color: primaryGreen),
                                    SizedBox(width: 8),
                                    Text(
                                      'Terms & Conditions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
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

            // Footer / Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Text(
                    '© 2026 NAIYO24 PVT. LTD. All rights reserved.',
                    style: TextStyle(fontSize: 11, color: subtitleColor),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!kIsWeb && Platform.isWindows) ...[
                        TextButton.icon(
                          icon: const Icon(Icons.system_update_rounded, size: 16),
                          label: const Text('Check for Updates'),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryGreen,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final updateInfo = await WindowsAutoUpdater.checkForUpdate();
                            if (context.mounted) {
                              if (updateInfo != null) {
                                WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You are using the latest version of SirfBill!'),
                                    backgroundColor: primaryGreen,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    Color? subtitleColor,
  }) {
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

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
    VoidCallback? onTap,
    required Color textColor,
    Color? subtitleColor,
  }) {
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
