import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_report_models.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_settings_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/pdf_thermal_generator.dart';
import '../pos/pos_bill_receipt_modal.dart';

class AuditLogsTab extends StatefulWidget {
  final List<AuditLogEntry> logs;
  final ValueChanged<String>? onSearch;

  const AuditLogsTab({
    super.key,
    required this.logs,
    this.onSearch,
  });

  @override
  State<AuditLogsTab> createState() => _AuditLogsTabState();
}

class _AuditLogsTabState extends State<AuditLogsTab> {
  String _searchQuery = '';
  String _selectedSeverity = 'All'; // 'All', 'Settled', 'Warning', 'Critical'
  String _selectedActor = 'All';
  String _sortBy = 'newest'; // 'newest', 'oldest'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openOrderThermalBill(BuildContext context, AuditLogEntry log) async {
    final orderId = log.id;
    final match = RegExp(r'#?(ORD-\d+-\d+)').firstMatch(log.details);
    final orderNumber = match != null ? match.group(1)! : (orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening thermal bill for $orderNumber...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // 1. Fetch official backend thermal PDF bytes
    Uint8List? thermalPdfBytes;
    try {
      thermalPdfBytes = await RestaurantPosService.fetchBackendBillPdfBytes(orderId);
    } catch (e) {
      debugPrint('Error fetching backend thermal bill for audit log: $e');
    }

    // 2. Fallback generator if needed
    if (thermalPdfBytes == null) {
      Map<String, dynamic>? shopSettings;
      try {
        shopSettings = await ShopSettingsService.getSettings();
      } catch (_) {}

      final authName = await AuthService.getUserName();
      final shopName = (shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
          ? shopSettings!['shop_name'].toString()
          : ((authName != null && authName.trim().isNotEmpty) ? authName : 'SirfBill Restaurant');

      final address = shopSettings?['address']?.toString() ??
          shopSettings?['shop_address']?.toString() ??
          'Restaurant Counter';
      final phone = shopSettings?['phone']?.toString() ??
          shopSettings?['mobile']?.toString() ??
          '';
      final shopGstNo = shopSettings?['gst_number']?.toString() ??
          shopSettings?['shop_gst_no']?.toString() ??
          shopSettings?['gstin']?.toString() ??
          '';
      final upiId = shopSettings?['upi_id']?.toString() ?? '';
      final cinNumber = shopSettings?['cin_number']?.toString() ??
          shopSettings?['drug_licence']?.toString() ??
          '';

      // Parse amount from details if available e.g. "settled for ₹199.50"
      final amtMatch = RegExp(r'₹\s*([0-9.]+)').firstMatch(log.details);
      final grandTotalVal = amtMatch != null ? (double.tryParse(amtMatch.group(1)!) ?? 0.0) : 0.0;

      try {
        thermalPdfBytes = await PdfThermalGenerator.generateThermalBill(
          items: [
            {
              'name': 'Restaurant Culinary Order',
              'quantity': 1,
              'price': grandTotalVal,
              'total': grandTotalVal,
              'gst': 5.0,
              'discount': 0.0,
            }
          ],
          subtotal: grandTotalVal,
          discount: 0.0,
          tax: 0.0,
          grandTotal: grandTotalVal,
          roundedTotal: grandTotalVal.roundToDouble(),
          invoiceNumber: orderNumber,
          customerName: log.actorName.isNotEmpty ? log.actorName : 'Customer',
          customerPhone: '',
          shopName: shopName,
          address: address,
          phone: phone,
          shopGstNo: shopGstNo,
          upiId: upiId,
          cinNumber: cinNumber,
        );
      } catch (genErr) {
        debugPrint('Thermal generator error: $genErr');
      }
    }

    if (context.mounted && thermalPdfBytes != null) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: orderNumber,
        title: 'Tax Invoice Receipt',
        pdfBytes: thermalPdfBytes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final allLogs = widget.logs;

    // Calculate Metrics
    final totalEvents = allLogs.length;
    final settledCount = allLogs.where((l) => l.action.toLowerCase().contains('settle')).length;
    final warningCount = allLogs.where((l) => l.severity == 'warning' || l.action.toLowerCase().contains('hold')).length;
    final criticalCount = allLogs.where((l) => l.severity == 'critical' || l.action.toLowerCase().contains('cancel')).length;

    // Unique Actors
    final actors = {'All', ...allLogs.map((l) => l.actorName).where((name) => name.isNotEmpty)};

    // Filter logs
    List<AuditLogEntry> filtered = allLogs.where((l) {
      final matchesSearch = l.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.actorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.details.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedSeverity == 'Settled') {
        if (!l.action.toLowerCase().contains('settle')) return false;
      } else if (_selectedSeverity == 'Warning') {
        if (l.severity != 'warning' && !l.action.toLowerCase().contains('hold')) return false;
      } else if (_selectedSeverity == 'Critical') {
        if (l.severity != 'critical' && !l.action.toLowerCase().contains('cancel')) return false;
      }

      if (_selectedActor != 'All' && l.actorName != _selectedActor) {
        return false;
      }

      return true;
    }).toList();

    // Sort logs
    if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Executive Audit KPI Strip (4 Stat Cards)
          _buildKpiMetricsStrip(
            isDark: isDark,
            totalEvents: totalEvents,
            settledCount: settledCount,
            warningCount: warningCount,
            criticalCount: criticalCount,
          ),
          const SizedBox(height: 20),

          // 2. Interactive Search & Filter Controls Bar
          _buildFilterBar(
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            subtextColor: subtextColor,
            totalCount: totalEvents,
            settledCount: settledCount,
            warningCount: warningCount,
            criticalCount: criticalCount,
            actors: actors.toList(),
          ),
          const SizedBox(height: 20),

          // 3. Responsive Dual-Column Layout: Stream & Insights
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 980;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Activity Stream (Flex 3)
                    Expanded(
                      flex: 3,
                      child: _buildLogStreamCard(
                        context,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        logs: filtered,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Side Insights Column (Flex 2)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSecurityHealthCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            totalCount: totalEvents,
                            settledCount: settledCount,
                            criticalCount: criticalCount,
                          ),
                          const SizedBox(height: 20),
                          _buildActorBreakdownCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            logs: allLogs,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Mobile / Tablet: Stacked Layout
              return Column(
                children: [
                  _buildLogStreamCard(
                    context,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    logs: filtered,
                  ),
                  const SizedBox(height: 20),
                  _buildSecurityHealthCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    totalCount: totalEvents,
                    settledCount: settledCount,
                    criticalCount: criticalCount,
                  ),
                  const SizedBox(height: 20),
                  _buildActorBreakdownCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    logs: allLogs,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. TOP METRICS STRIP
  // =========================================================================
  Widget _buildKpiMetricsStrip({
    required bool isDark,
    required int totalEvents,
    required int settledCount,
    required int warningCount,
    required int criticalCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w < 600 ? 1 : (w < 1100 ? 2 : 4);
        final aspect = w < 600 ? 2.6 : (w < 1100 ? 2.3 : 1.95);

        final items = [
          _AuditKpiData(
            title: 'Immutable Event Logs',
            value: '$totalEvents events',
            subtitle: 'Real-time ledger entries',
            badge: 'Audit Trail',
            icon: Icons.shield_rounded,
            gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            accentColor: const Color(0xFF8B5CF6),
          ),
          _AuditKpiData(
            title: 'Settled Transactions',
            value: '$settledCount bills',
            subtitle: 'Verified cash & online settlements',
            badge: 'Completed',
            icon: Icons.check_circle_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            accentColor: const Color(0xFF10B981),
          ),
          _AuditKpiData(
            title: 'Holds & Operational Alerts',
            value: '$warningCount alerts',
            subtitle: 'Pending billing & held orders',
            badge: 'In Review',
            icon: Icons.pending_actions_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            accentColor: const Color(0xFFF59E0B),
          ),
          _AuditKpiData(
            title: 'Voids & Order Cancels',
            value: '$criticalCount voids',
            subtitle: 'Sensitive operations logged',
            badge: criticalCount == 0 ? 'Secure 0 Voids' : 'Attention',
            icon: Icons.gpp_maybe_rounded,
            gradient: criticalCount == 0
                ? const [Color(0xFF0EA5E9), Color(0xFF0284C7)]
                : const [Color(0xFFEF4444), Color(0xFFB91C1C)],
            accentColor: criticalCount == 0 ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final card = items[idx];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: card.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: card.accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(card.icon, color: Colors.white, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: card.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          card.badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: card.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 2. INTERACTIVE FILTER & SEARCH BAR
  // =========================================================================
  Widget _buildFilterBar({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required int totalCount,
    required int settledCount,
    required int warningCount,
    required int criticalCount,
    required List<String> actors,
  }) {
    final severityPills = [
      ('All', 'All Events ($totalCount)', const Color(0xFF8B5CF6)),
      ('Settled', 'Settlements ($settledCount)', const Color(0xFF10B981)),
      ('Warning', 'Holds & Alerts ($warningCount)', const Color(0xFFF59E0B)),
      ('Critical', 'Voids & Cancels ($criticalCount)', const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 750;

              final searchBox = Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    widget.onSearch?.call(val);
                  },
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search audit records by order #, cashier, or details...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              widget.onSearch?.call('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );

              final actorDropdown = (actors.length > 1)
                  ? Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedActor,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF8B5CF6)),
                          isExpanded: isCompact,
                          items: actors.map((a) {
                            return DropdownMenuItem(
                              value: a,
                              child: Text(
                                a == 'All' ? 'All Actors / Staff' : a,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedActor = val);
                          },
                        ),
                      ),
                    )
                  : null;

              final sortDropdown = Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF8B5CF6)),
                    isExpanded: isCompact,
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Sort: Newest First', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'oldest', child: Text('Sort: Oldest First', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    searchBox,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (actorDropdown != null) ...[
                          Expanded(child: actorDropdown),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: sortDropdown),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchBox),
                  if (actorDropdown != null) ...[
                    const SizedBox(width: 12),
                    actorDropdown,
                  ],
                  const SizedBox(width: 12),
                  sortDropdown,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Severity Quick Filters Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: severityPills.map((pill) {
                final key = pill.$1;
                final label = pill.$2;
                final color = pill.$3;
                final isSelected = _selectedSeverity == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedSeverity = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : borderColor,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. MAIN ACTIVITY STREAM CARD
  // =========================================================================
  Widget _buildLogStreamCard(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required List<AuditLogEntry> logs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security & Action Audit Trail',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        'Immutable cryptographic activity ledger (${logs.length} events matching filter)',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${logs.length} Events',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Empty state
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 44, color: subtextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No matching audit trail events found',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try resetting your search query or selecting "All Events"',
                      style: TextStyle(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
              itemBuilder: (context, index) {
                final log = logs[index];

                Color accentColor;
                IconData actionIcon;
                String severityLabel;

                final actLower = log.action.toLowerCase();
                if (log.severity == 'critical' || actLower.contains('cancel') || actLower.contains('void')) {
                  accentColor = const Color(0xFFEF4444);
                  actionIcon = Icons.warning_rounded;
                  severityLabel = 'CRITICAL';
                } else if (log.severity == 'warning' || actLower.contains('hold') || actLower.contains('discount')) {
                  accentColor = const Color(0xFFF59E0B);
                  actionIcon = Icons.pending_actions_rounded;
                  severityLabel = 'AUDIT';
                } else {
                  accentColor = const Color(0xFF10B981);
                  actionIcon = Icons.check_circle_rounded;
                  severityLabel = 'INFO';
                }

                // Format timestamp
                final timeFormatted = DateFormat('hh:mm a').format(log.timestamp);
                final dateFormatted = DateFormat('dd MMM yyyy').format(log.timestamp);

                // Extract details tokens (payment mode, order type, order number)
                final d = log.details;
                String? tenderBadge;
                if (d.contains('via UPI')) {
                  tenderBadge = 'UPI';
                } else if (d.contains('via CASH')) {
                  tenderBadge = 'CASH';
                } else if (d.contains('via CARD')) {
                  tenderBadge = 'CARD';
                }

                String? fulfillmentBadge;
                if (d.contains('TAKEAWAY')) {
                  fulfillmentBadge = 'TAKEAWAY';
                } else if (d.contains('DINE_IN') || d.contains('DINE-IN')) {
                  fulfillmentBadge = 'DINE-IN';
                } else if (d.contains('DELIVERY')) {
                  fulfillmentBadge = 'DELIVERY';
                }

                return InkWell(
                  onTap: () => _openOrderThermalBill(context, log),
                  hoverColor: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.35)
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Icon with gradient background
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                          ),
                          child: Center(
                            child: Icon(actionIcon, size: 18, color: accentColor),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Action Row
                              Row(
                                children: [
                                  Text(
                                    log.action,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Severity Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      severityLabel,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Actor Name Pill
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_rounded, size: 10, color: subtextColor),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              log.actorName,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Details narrative
                              Text(
                                log.details,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Sub-badges (Payment Tender & Fulfillment)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (tenderBadge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tenderBadge,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  if (fulfillmentBadge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        fulfillmentBadge,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    dateFormatted,
                                    style: TextStyle(fontSize: 10, color: subtextColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Time Badge + View Bill Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: subtextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeFormatted,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'View Bill',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }


  // =========================================================================
  // 4. SECURITY COMPLIANCE & HEALTH CARD
  // =========================================================================
  Widget _buildSecurityHealthCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required int totalCount,
    required int settledCount,
    required int criticalCount,
  }) {
    final healthPercent = totalCount > 0 ? (((totalCount - criticalCount) / totalCount) * 100) : 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compliance & Security Health',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      'Cryptographic integrity and cashier compliance',
                      style: TextStyle(fontSize: 10.5, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Health Score Meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Register Integrity Score',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              ),
              Text(
                '${healthPercent.toStringAsFixed(1)}% High',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (healthPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),

          // Bullet Items
          _buildHealthItem(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            title: 'Append-Only Ledger',
            desc: 'Every cashier settlement and discount transition is permanently logged.',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 10),
          _buildHealthItem(
            icon: Icons.lock_clock_rounded,
            color: const Color(0xFF6366F1),
            title: 'Cashier Traceability',
            desc: 'Actions are attributed to unique authenticated staff user accounts.',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 10.5, color: subtextColor, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 5. ACTOR & CASHIER BREAKDOWN CARD
  // =========================================================================
  Widget _buildActorBreakdownCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required List<AuditLogEntry> logs,
  }) {
    final Map<String, int> actorCounts = {};
    for (final l in logs) {
      final name = l.actorName.isNotEmpty ? l.actorName : 'Unknown Staff';
      actorCounts[name] = (actorCounts[name] ?? 0) + 1;
    }
    final sortedActors = actorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0EA5E9), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operator & Cashier Velocity',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      'Action distribution by authenticated user',
                      style: TextStyle(fontSize: 10.5, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          if (sortedActors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No cashier records found', style: TextStyle(color: subtextColor, fontSize: 12)),
              ),
            )
          else
            ...sortedActors.take(5).map((entry) {
              final actor = entry.key;
              final count = entry.value;
              final percent = logs.isNotEmpty ? ((count / logs.length) * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              child: Text(
                                actor.isNotEmpty ? actor[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              actor,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                            ),
                          ],
                        ),
                        Text(
                          '$count actions (${percent.toStringAsFixed(0)}%)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: subtextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AuditKpiData {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  const _AuditKpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}
