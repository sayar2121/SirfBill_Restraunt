import 'package:flutter/material.dart';

class AccountsHeader extends StatelessWidget {
  final Function(String) onExport;
  final VoidCallback onRefresh;
  final VoidCallback onAddTransaction;

  const AccountsHeader({
    super.key,
    required this.onExport,
    required this.onRefresh,
    required this.onAddTransaction,
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
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).cardColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accounts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage income, expenses, payments and financial reports',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              PopupMenuButton<String>(
                tooltip: 'Export Options',
                onSelected: onExport,
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Export as PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          color: Colors.green,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Export as Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Export as CSV'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                ),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddTransaction,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
