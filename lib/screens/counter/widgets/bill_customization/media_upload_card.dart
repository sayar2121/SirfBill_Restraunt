import 'package:flutter/material.dart';
import 'package:sirfbill_restaurant/config/api_constants.dart';

class MediaUploadCard extends StatelessWidget {
  final String? logoUrl;
  final String? qrUrl;
  final VoidCallback onPickLogo;
  final VoidCallback onPickQr;
  final VoidCallback onClearLogo;
  final VoidCallback onClearQr;

  const MediaUploadCard({
    super.key,
    required this.logoUrl,
    required this.qrUrl,
    required this.onPickLogo,
    required this.onPickQr,
    required this.onClearLogo,
    required this.onClearQr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media (Logo & UPI QR)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MediaItem(
                  title: 'Shop Logo',
                  url: logoUrl,
                  fallbackIcon: Icons.image,
                  onPick: onPickLogo,
                  onClear: onClearLogo,
                ),
                _MediaItem(
                  title: 'UPI QR Code',
                  url: qrUrl,
                  fallbackIcon: Icons.qr_code,
                  onPick: onPickQr,
                  onClear: onClearQr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaItem extends StatelessWidget {
  final String title;
  final String? url;
  final IconData fallbackIcon;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _MediaItem({
    required this.title,
    required this.url,
    required this.fallbackIcon,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: (url != null && url!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url!.startsWith('http://') || url!.startsWith('https://')
                            ? url!
                            : '${ApiConstants.baseUrl}${url!.startsWith('/') ? '' : '/'}$url',
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(fallbackIcon, size: 36, color: Colors.orange.shade300),
                              const SizedBox(height: 4),
                              const Text(
                                'Preview error',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : Icon(
                      fallbackIcon,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            if (url != null)
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: onClear,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}
