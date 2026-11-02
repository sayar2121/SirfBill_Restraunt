import '../../../../utils/kot_printer_helper.dart';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class KotReceiptPreviewModal extends StatelessWidget {
  final KitchenTicket ticket;

  const KotReceiptPreviewModal({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                'KITCHEN ORDER TICKET (KOT)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.kotNumber,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
              ),
              Text(
                'Order: ${ticket.orderNumber} • ${ticket.orderType.name.toUpperCase()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              if (ticket.tableLabel != null)
                Text(
                  'TABLE: ${ticket.tableLabel} (${ticket.floor ?? 'Floor 1'})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              const Divider(thickness: 1.2, color: Colors.black26),

              // Items
              ListView.builder(
                shrinkWrap: true,
                itemCount: ticket.items.length,
                itemBuilder: (context, idx) {
                  final it = ticket.items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${it.quantity}x',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              if (it.notes != null)
                                Text(
                                  '** ${it.notes} **',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFEF4444)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(thickness: 1.2, color: Colors.black26),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time: ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Server: ${ticket.serverName ?? 'POS'}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Print and Close Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final posCartItems = ticket.items.map((it) => PosCartItem(
                          item: PosMenuItem(
                            id: it.name,
                            name: it.name,
                            categoryId: 'kitchen',
                            price: 0,
                          ),
                          quantity: it.quantity,
                          notes: it.notes,
                        )).toList();

                        await KotPrinterHelper.printKotDirectly(
                          context: context,
                          kotNumber: ticket.kotNumber,
                          orderNumber: ticket.orderNumber,
                          orderType: ticket.orderType.name,
                          tableLabel: ticket.tableLabel,
                          floor: ticket.floor,
                          items: posCartItems,
                          timestamp: ticket.createdAt,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
