import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurant_report_provider.dart';
import 'widgets/reports/report_filter_header.dart';
import 'widgets/reports/sales_overview_tab.dart';
import 'widgets/reports/item_wise_sales_tab.dart';
import 'widgets/reports/audit_logs_tab.dart';
import 'widgets/reports/restaurant_report_export_helper.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(restaurantReportProvider);
    final reportNotifier = ref.read(restaurantReportProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget content;
    switch (reportState.activeTab) {
      case 0:
        content = SalesOverviewTab(summary: reportState.summary);
        break;
      case 1:
        content = ItemWiseSalesTab(
          topDishes: reportState.topDishes,
          summary: reportState.summary,
          orders: reportState.orders,
        );
        break;
      case 2:
        content = AuditLogsTab(
          logs: reportState.filteredAuditLogs,
          onSearch: reportNotifier.setAuditSearchQuery,
        );
        break;
      default:
        content = SalesOverviewTab(summary: reportState.summary);
    }

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Report Filters Header (Date Range Presets & Custom Picker, Segmented Tabs, Export PDF)
          ReportFilterHeader(
            datePreset: reportState.datePreset,
            customRange: reportState.customRange,
            activeTab: reportState.activeTab,
            isLoading: reportState.isLoading,
            onSelectDatePreset: reportNotifier.setDatePreset,
            onSelectCustomRange: reportNotifier.setCustomRange,
            onSelectTab: reportNotifier.setActiveTab,
            onRefresh: reportNotifier.loadReportData,
            onExportPdf: () {
              RestaurantReportExportHelper.showExportOptions(
                context: context,
                periodLabel: reportState.dateRangeLabel,
                summary: reportState.summary,
                topDishes: reportState.topDishes,
                orders: reportState.orders,
                auditLogs: reportState.auditLogs,
              );
            },
          ),

          // 2. Tab Content View
          Expanded(
            child: reportState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : content,
          ),
        ],
      ),
    );
  }
}
