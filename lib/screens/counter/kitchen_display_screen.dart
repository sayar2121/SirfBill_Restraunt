import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_session_manager.dart';
import '../../services/inventory_service.dart';
import '../../services/kitchen_audio_service.dart';
import '../../services/shop_service.dart';
import '../../services/shop_settings_service.dart';
import '../../providers/kitchen_display_provider.dart';
import 'widgets/kitchen/kitchen_filter_header.dart';
import 'widgets/kitchen/kitchen_ticket_card.dart';
import 'widgets/kitchen/kitchen_report_export_helper.dart';
import 'widgets/kitchen/kot_receipt_preview_modal.dart';
import 'widgets/kitchen/new_order_alert_modal.dart';
import '../../models/restaurant_pos_models.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  final bool isStandalone;
  const KitchenDisplayScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  Timer? _liveClockTimer;
  String? _shownAlertTicketId;
  String _restaurantName = '';
  String? _outletLocation;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();

    // In dedicated standalone KDS mode (/kitchen), sound alert is enabled for the kitchen tablet/monitor.
    // In POS counter billing tab, it remains completely muted.
    if (widget.isStandalone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !ref.read(kitchenDisplayProvider).isSoundEnabled) {
          ref.read(kitchenDisplayProvider.notifier).toggleSound();
        }
      });
    }

    // Live clock timer for re-evaluating SLA elapsed minutes every 30 seconds
    _liveClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String restaurantName = prefs.getString('assigned_outlet_name') ?? '';
      String location = '';

      final currentShopId = prefs.getString('selected_shop_id') ??
          prefs.getString('assigned_outlet_id') ??
          await InventoryService.getShopId();

      try {
        final shops = await ShopService.getShops();
        final matched = shops.where((s) => s.id == currentShopId).firstOrNull ?? shops.firstOrNull;
        if (matched != null) {
          if (restaurantName.isEmpty) {
            restaurantName = matched.name;
          }
          location = matched.city.isNotEmpty
              ? matched.city
              : (matched.location.isNotEmpty ? matched.location : '');
        }
      } catch (_) {}

      if (restaurantName.isEmpty) {
        restaurantName = prefs.getString('shop_name') ?? '';
      }
      if (restaurantName.isEmpty) {
        try {
          final settings = await ShopSettingsService.getSettings();
          final n = settings['shop_name']?.toString();
          if (n != null && n.trim().isNotEmpty) {
            restaurantName = n.trim();
          }
        } catch (_) {}
      }
      if (restaurantName.isEmpty) {
        restaurantName = 'SirfBill Restaurant';
      }

      if (mounted) {
        setState(() {
          _restaurantName = restaurantName;
          _outletLocation = location.isNotEmpty ? location : null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    KitchenAudioService.stop();
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

    // Show popup modal when a new order arrives in dedicated KDS mode
    if (widget.isStandalone && kdsState.pendingAlertTicket != null) {
      final alertTicket = kdsState.pendingAlertTicket!;
      if (_shownAlertTicketId != alertTicket.id) {
        _shownAlertTicketId = alertTicket.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => NewOrderAlertModal(
              ticket: alertTicket,
              restaurantName: _restaurantName,
              onAccept: () {
                Navigator.of(ctx).pop();
                kdsNotifier.updateTicketStatus(alertTicket.id, KotStatus.preparing);
              },
              onDismiss: () {
                Navigator.of(ctx).pop();
                kdsNotifier.clearPendingAlert();
              },
            ),
          ).then((_) {
            _shownAlertTicketId = null;
          });
        });
      }
    }

    return Scaffold(
      backgroundColor: screenBg,
      body: SafeArea(
        top: widget.isStandalone,
        bottom: true,
        child: Column(
          children: [
          // 1. Kitchen Filter Header (Matches POS Billing Control Style)
          KitchenFilterHeader(
            restaurantName: _restaurantName,
            outletLocation: _outletLocation,
            totalCount: kdsState.totalCount,
            activeCount: kdsState.activeCount,
            newCount: kdsState.newCount,
            preparingCount: kdsState.preparingCount,
            readyCount: kdsState.readyCount,
            delayedCount: kdsState.delayedCount,
            servedCount: kdsState.servedCount,
            statusFilter: kdsState.statusFilter,
            typeFilter: kdsState.typeFilter,
            datePreset: kdsState.datePreset,
            customRange: kdsState.customRange,
            onlyActive: kdsState.onlyActive,
            onlyDelayed: kdsState.onlyDelayed,
            onSelectStatus: kdsNotifier.setStatusFilter,
            onSelectActive: kdsNotifier.filterActiveOnly,
            onSelectDelayed: kdsNotifier.filterDelayedOnly,
            onSelectAll: kdsNotifier.showAll,
            onSelectType: kdsNotifier.setTypeFilter,
            onSelectDatePreset: kdsNotifier.setDatePreset,
            onSelectCustomRange: kdsNotifier.setCustomRange,
            onSearch: kdsNotifier.setSearchQuery,
            isSoundEnabled: widget.isStandalone && kdsState.isSoundEnabled,
            onToggleSound: widget.isStandalone ? _toggleSound : null,
            isStandalone: widget.isStandalone,
            onExitStandalone: _handleExitStandalone,
            onRefresh: () async {
              _loadRestaurantInfo();
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
            onExport: () {
              KitchenReportExportHelper.showExportOptions(
                context: context,
                tickets: tickets,
                datePreset: kdsState.datePreset,
                customRange: kdsState.customRange,
              );
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                              Text(
                                _restaurantName.trim().isNotEmpty
                                    ? 'Kitchen is all caught up for $_restaurantName! New orders will appear automatically.'
                                    : 'Kitchen is all caught up! New POS orders will appear automatically.',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isMobile = width < 550;
                          final isTablet = width >= 550 && width < 900;
                          int crossAxisCount;
                          double childAspectRatio;

                          if (isMobile) {
                            crossAxisCount = 1;
                            childAspectRatio = 1.05;
                          } else if (isTablet) {
                            crossAxisCount = 2;
                            childAspectRatio = 0.80;
                          } else if (width < 1250) {
                            crossAxisCount = 3;
                            childAspectRatio = 0.82;
                          } else if (width < 1650) {
                            crossAxisCount = 4;
                            childAspectRatio = 0.84;
                          } else {
                            crossAxisCount = 5;
                            childAspectRatio = 0.88;
                          }

                          return GridView.builder(
                            padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 12 : 16)),
                            itemCount: tickets.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isMobile ? 10 : 14,
                              mainAxisSpacing: isMobile ? 10 : 14,
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
    ),
  );
}
}
