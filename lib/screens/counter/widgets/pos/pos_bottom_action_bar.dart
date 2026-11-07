import 'package:flutter/material.dart';

class PosBottomActionBar extends StatelessWidget {
  final VoidCallback onSaveHold;
  final VoidCallback onPrintKot;
  final VoidCallback? onPrintBill;
  final VoidCallback onProceedToPayment;
  final String? activeOrderLabel;

  const PosBottomActionBar({
    super.key,
    required this.onSaveHold,
    required this.onPrintKot,
    this.onPrintBill,
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
            // 1. Save / Hold or Update Button
            Expanded(
              flex: 10,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onSaveHold,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeOrderLabel != null ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeOrderLabel != null ? Icons.update_rounded : Icons.bookmark_border_rounded, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          activeOrderLabel != null
                              ? (isCompact ? 'Update' : 'Update')
                              : (isCompact ? 'Hold' : 'Save/Hold'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // 2. Print KOT Button
            Expanded(
              flex: 10,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onPrintKot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.soup_kitchen_rounded, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          isCompact ? 'KOT' : 'Print KOT',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onPrintBill != null) ...[
              const SizedBox(width: 5),
              // 3. Print Customer Bill (Pre-Settlement Check)
              Expanded(
                flex: 10,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onPrintBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 17),
                          const SizedBox(width: 4),
                          Text(
                            isCompact ? 'Bill' : 'Print Bill',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 5),

            // 4. Proceed to Payment / Settle Button
            Expanded(
              flex: 14,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onProceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCompact ? 'Pay' : 'Settle & Pay',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
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
