import 'package:flutter/material.dart';

class HistoryHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final ValueChanged<String> onExportSelected;

  const HistoryHeader({
    super.key,
    required this.onRefresh,
    required this.onExportSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View all transactions, activities and records',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: onExportSelected,
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF22C55E),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        size: 16,
                        color: isDark ? Colors.green[400]! : const Color(0xFF166534),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[400]! : const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: isDark ? Colors.green[400]! : const Color(0xFF166534),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Excel_Filtered',
                    child: Text('Export Current Filtered List (Excel)'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'Excel_Today',
                    child: Text('Export Today (Excel)'),
                  ),
                  const PopupMenuItem(
                    value: 'Excel_Week',
                    child: Text('Export This Week (Excel)'),
                  ),
                  const PopupMenuItem(
                    value: 'Excel_Month',
                    child: Text('Export This Month (Excel)'),
                  ),
                  const PopupMenuItem(
                    value: 'Excel_Year',
                    child: Text('Export This Year (Excel)'),
                  ),
                  const PopupMenuItem(
                    value: 'Excel_All',
                    child: Text('Export All Time (Excel)'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'PDF_Filtered',
                    child: Text('Export Current Filtered List (PDF)'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'PDF_Today',
                    child: Text('Export Today (PDF)'),
                  ),
                  const PopupMenuItem(
                    value: 'PDF_Week',
                    child: Text('Export This Week (PDF)'),
                  ),
                  const PopupMenuItem(
                    value: 'PDF_Month',
                    child: Text('Export This Month (PDF)'),
                  ),
                  const PopupMenuItem(
                    value: 'PDF_Year',
                    child: Text('Export This Year (PDF)'),
                  ),
                  const PopupMenuItem(
                    value: 'PDF_All',
                    child: Text('Export All Time (PDF)'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
