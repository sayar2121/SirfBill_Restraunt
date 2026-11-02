import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kitchen_display_provider.dart';
import 'widgets/kitchen/kitchen_filter_header.dart';
import 'widgets/kitchen/kitchen_ticket_card.dart';
import 'widgets/kitchen/kot_receipt_preview_modal.dart';

class KitchenDisplayScreen extends ConsumerWidget {
  const KitchenDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kdsState = ref.watch(kitchenDisplayProvider);
    final kdsNotifier = ref.read(kitchenDisplayProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final tickets = kdsState.filteredTickets;

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Kitchen Filter Header (Status, Type, Search, Refresh)
          KitchenFilterHeader(
            totalCount: kdsState.totalCount,
            activeCount: kdsState.activeCount,
            newCount: kdsState.newCount,
            preparingCount: kdsState.preparingCount,
            readyCount: kdsState.readyCount,
            servedCount: kdsState.servedCount,
            statusFilter: kdsState.statusFilter,
            typeFilter: kdsState.typeFilter,
            onlyActive: kdsState.onlyActive,
            onSelectStatus: kdsNotifier.setStatusFilter,
            onSelectActive: kdsNotifier.filterActiveOnly,
            onSelectAll: kdsNotifier.showAll,
            onSelectType: kdsNotifier.setTypeFilter,
            onSearch: kdsNotifier.setSearchQuery,
            onRefresh: () async {
              await kdsNotifier.loadTickets();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('KDS refreshed with latest kitchen orders!'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
          ),

          // 2. Responsive KDS Ticket Matrix
          Expanded(
            child: (kdsState.isLoading == true && tickets.isEmpty)
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFF97316)),
                        SizedBox(height: 16),
                        Text(
                          'Loading live kitchen tickets...',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : tickets.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.soup_kitchen_outlined, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No active KOT tickets for this filter',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Kitchen is all caught up!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount;
                      double childAspectRatio;

                      if (width < 500) {
                        crossAxisCount = 1;
                        childAspectRatio = 1.05;
                      } else if (width < 800) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.95;
                      } else if (width < 1200) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.92;
                      } else if (width < 1600) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.96;
                      } else {
                        crossAxisCount = 5;
                        childAspectRatio = 1.0;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tickets.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return KitchenTicketCard(
                            ticket: ticket,
                            onUpdateStatus: (next) => kdsNotifier.updateTicketStatus(ticket.id, next),
                            onToggleItem: (itemId) => kdsNotifier.toggleItemPrepared(ticket.id, itemId),
                            onPrintKot: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => KotReceiptPreviewModal(ticket: ticket),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
