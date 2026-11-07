import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/app_session_manager.dart';
import '../../providers/kitchen_display_provider.dart';
import 'widgets/kitchen/kitchen_filter_header.dart';
import 'widgets/kitchen/kitchen_ticket_card.dart';
import 'widgets/kitchen/kot_receipt_preview_modal.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  final bool isStandalone;
  const KitchenDisplayScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  Timer? _liveClockTimer;

  @override
  void initState() {
    super.initState();
    // Live clock timer for re-evaluating SLA elapsed minutes every 30 seconds
    _liveClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    super.dispose();
  }

  void _toggleSound() {
    ref.read(kitchenDisplayProvider.notifier).toggleSound();
    final isSound = ref.read(kitchenDisplayProvider).isSoundEnabled;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSound ? 'KDS Sound alerts enabled' : 'KDS Sound alerts muted'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleExitStandalone() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Exit Kitchen Display', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to close Kitchen Display mode and return to main screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit KDS'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AppSessionManager.resetSession(ref: ref);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kdsState = ref.watch(kitchenDisplayProvider);
    final kdsNotifier = ref.read(kitchenDisplayProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final tickets = kdsState.filteredTickets;

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Kitchen Filter Header (Matches POS Billing Control Style)
          KitchenFilterHeader(
            totalCount: kdsState.totalCount,
            activeCount: kdsState.activeCount,
            newCount: kdsState.newCount,
            preparingCount: kdsState.preparingCount,
            readyCount: kdsState.readyCount,
            delayedCount: kdsState.delayedCount,
            servedCount: kdsState.servedCount,
            statusFilter: kdsState.statusFilter,
            typeFilter: kdsState.typeFilter,
            onlyActive: kdsState.onlyActive,
            onlyDelayed: kdsState.onlyDelayed,
            onSelectStatus: kdsNotifier.setStatusFilter,
            onSelectActive: kdsNotifier.filterActiveOnly,
            onSelectDelayed: kdsNotifier.filterDelayedOnly,
            onSelectAll: kdsNotifier.showAll,
            onSelectType: kdsNotifier.setTypeFilter,
            onSearch: kdsNotifier.setSearchQuery,
            isSoundEnabled: widget.isStandalone && kdsState.isSoundEnabled,
            onToggleSound: widget.isStandalone ? _toggleSound : null,
            isStandalone: widget.isStandalone,
            onExitStandalone: _handleExitStandalone,
            onRefresh: () async {
              await kdsNotifier.loadTickets();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('KDS refreshed with live kitchen orders!'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
          ),

          // 2. High-Contrast Kitchen Ticket Matrix (Touchscreen & Desktop Optimized)
          Expanded(
            child: (kdsState.isLoading == true && tickets.isEmpty)
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3.5, color: Color(0xFFF97316)),
                        SizedBox(height: 16),
                        Text(
                          'Loading live kitchen tickets...',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                : tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF1E293B) : Colors.white),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.soup_kitchen_outlined, size: 54, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No KOT tickets for current filter',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kitchen is all caught up! New POS orders will appear automatically.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int crossAxisCount;
                          double childAspectRatio;

                          if (width < 600) {
                            crossAxisCount = 1;
                            childAspectRatio = 1.05;
                          } else if (width < 960) {
                            crossAxisCount = 2;
                            childAspectRatio = 0.88;
                          } else if (width < 1400) {
                            crossAxisCount = 3;
                            childAspectRatio = 0.82;
                          } else if (width < 1850) {
                            crossAxisCount = 4;
                            childAspectRatio = 0.84;
                          } else {
                            crossAxisCount = 5;
                            childAspectRatio = 0.88;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: tickets.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              final ticket = tickets[index];
                              return KitchenTicketCard(
                                ticket: ticket,
                                isReadOnly: !widget.isStandalone,
                                onUpdateStatus: widget.isStandalone
                                    ? (next) => kdsNotifier.updateTicketStatus(ticket.id, next)
                                    : null,
                                onToggleItem: widget.isStandalone
                                    ? (itemId) => kdsNotifier.toggleItemPrepared(ticket.id, itemId)
                                    : null,
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
