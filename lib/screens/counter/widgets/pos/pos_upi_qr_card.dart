import 'package:flutter/material.dart';

/// Interactive UPI QR Code card for on-screen scanning.
class PosUpiQrCard extends StatelessWidget {
  final String upiQrUrl;
  final String effectiveUpi;
  final bool isDark;

  const PosUpiQrCard({
    super.key,
    required this.upiQrUrl,
    required this.effectiveUpi,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Scan QR with any UPI App',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Image.network(
              upiQrUrl,
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 170,
                  height: 170,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 170,
                height: 170,
                alignment: Alignment.center,
                child: const Text('UPI: Scan with phone', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'VPA: $effectiveUpi',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'GPay • PhonePe • Paytm • BHIM',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
