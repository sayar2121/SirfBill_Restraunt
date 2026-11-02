import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../services/shop_service.dart';
import 'pos_cash_card_note.dart';
import 'pos_pay_chip.dart';
import 'pos_upi_qr_card.dart';

/// Interactive modal for selecting payment mode.
/// On confirm, calls [onConfirm] with the selected mode and pops itself.
/// Settlement logic is intentionally kept in the CALLER (PosCartPanel) so that
/// the caller's live BuildContext and WidgetRef are used — never a disposed widget's.
class PosOrderPaymentDialog extends ConsumerStatefulWidget {
  final RestaurantPosState state;
  final Map<String, dynamic>? shopSettings;
  final Shop? activeOutlet;
  final List<DiningTable> tables;

  /// Called when the cashier confirms payment. Receives the selected payment mode string.
  /// The caller is responsible for running the settlement with its own context + ref.
  final void Function(String selectedMode) onConfirm;

  const PosOrderPaymentDialog({
    super.key,
    required this.state,
    required this.shopSettings,
    required this.activeOutlet,
    required this.tables,
    required this.onConfirm,
  });

  @override
  ConsumerState<PosOrderPaymentDialog> createState() => _PosOrderPaymentDialogState();
}

class _PosOrderPaymentDialogState extends ConsumerState<PosOrderPaymentDialog> {
  String _selectedMode = 'UPI / QR';

  void _onConfirmSettlement() {
    final selectedMode = _selectedMode;
    // Pop the dialog FIRST so the dialog is removed from the tree.
    Navigator.pop(context);
    // Then call back into the CALLER (which has its own live context + ref).
    widget.onConfirm(selectedMode);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isUpi = _selectedMode.contains('UPI');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveUpi = (widget.activeOutlet?.upiId != null && widget.activeOutlet!.upiId!.trim().isNotEmpty)
        ? widget.activeOutlet!.upiId!.trim()
        : (widget.shopSettings?['upi_id']?.toString().trim().isNotEmpty ?? false
            ? widget.shopSettings!['upi_id'].toString().trim()
            : 'sirfbill.pos@okhdfcbank');

    final effectiveShopName = (widget.activeOutlet?.name != null && widget.activeOutlet!.name.trim().isNotEmpty)
        ? widget.activeOutlet!.name.trim()
        : (widget.shopSettings?['shop_name']?.toString() ?? 'SirfBill Restaurant');

    final upiPayload = 'upi://pay?pa=$effectiveUpi&pn=${Uri.encodeComponent(effectiveShopName)}&am=${state.grandTotal.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Table POS Bill")}';
    final upiQrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(upiPayload)}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Settle Bill & Pay', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Grand Total Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Grand Total: ', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    Text(
                      '₹ ${state.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Selector Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Payment Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey[300] : const Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PosPayChip(
                    title: 'UPI / QR',
                    icon: Icons.qr_code_rounded,
                    selected: _selectedMode == 'UPI / QR',
                    onTap: () => setState(() => _selectedMode = 'UPI / QR'),
                  ),
                  const SizedBox(width: 8),
                  PosPayChip(
                    title: 'Cash',
                    icon: Icons.money_rounded,
                    selected: _selectedMode == 'Cash',
                    onTap: () => setState(() => _selectedMode = 'Cash'),
                  ),
                  const SizedBox(width: 8),
                  PosPayChip(
                    title: 'Card',
                    icon: Icons.credit_card_rounded,
                    selected: _selectedMode == 'Card',
                    onTap: () => setState(() => _selectedMode = 'Card'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode Specific Content
              if (isUpi)
                PosUpiQrCard(
                  upiQrUrl: upiQrUrl,
                  effectiveUpi: effectiveUpi,
                  isDark: isDark,
                )
              else
                PosCashCardNote(
                  selectedMode: _selectedMode,
                  grandTotal: state.grandTotal,
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF64748B))),
        ),
        ElevatedButton.icon(
          icon: Icon(isUpi ? Icons.check_circle_rounded : Icons.done_rounded, size: 16),
          label: Text(
            isUpi ? 'Confirm UPI Payment Received' : 'Complete Settlement',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _onConfirmSettlement,
        ),
      ],
    );
  }
}
