import 'package:flutter/material.dart';

class PosBottomActionBar extends StatelessWidget {
  final VoidCallback onSaveHold;
  final VoidCallback onPrintKot;
  final VoidCallback onProceedToPayment;
  final String? activeOrderLabel;

  const PosBottomActionBar({
    super.key,
    required this.onSaveHold,
    required this.onPrintKot,
    required this.onProceedToPayment,
    this.activeOrderLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // On compact panes, adapt layout and text
        final isCompact = totalWidth < 430;

        return Row(
          children: [
            // Save / Hold or Update Button
            Expanded(
              flex: 11,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onSaveHold,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeOrderLabel != null ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeOrderLabel != null ? Icons.update_rounded : Icons.bookmark_border_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          activeOrderLabel != null
                              ? (isCompact ? 'Update' : 'Update Order')
                              : (isCompact ? 'Hold' : 'Save / Hold'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Print KOT Button
            Expanded(
              flex: 11,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onPrintKot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print_rounded, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Print KOT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Proceed to Payment Button
            Expanded(
              flex: 16,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onProceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCompact ? 'Pay' : 'Proceed to Payment',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
