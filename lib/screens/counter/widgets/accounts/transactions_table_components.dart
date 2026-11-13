import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/transaction_service.dart';
import 'accounts_common_widgets.dart';

/// 1. Top Filter bar with Period, Type, Category dropdowns, Search bar, and Reset button.
class TransactionFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final String selectedType;
  final String selectedCategory;
  final List<String> periods;
  final List<String> types;
  final List<String> categories;
  final TextEditingController searchController;
  final Function({
    String? period,
    String? type,
    String? category,
    String? query,
  }) onFilterChanged;
  final VoidCallback onResetFilters;

  const TransactionFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.selectedType,
    required this.selectedCategory,
    required this.periods,
    required this.types,
    required this.categories,
    required this.searchController,
    required this.onFilterChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AccountsWidgets.buildDynamicDropdown(
            context,
            selectedPeriod,
            periods,
            (String? newValue) {
              if (newValue != null) onFilterChanged(period: newValue);
            },
          ),
          AccountsWidgets.buildDynamicDropdown(
            context,
            selectedType,
            types,
            (String? newValue) {
              if (newValue != null) onFilterChanged(type: newValue);
            },
          ),
          AccountsWidgets.buildDynamicDropdown(
            context,
            selectedCategory,
            categories,
            (String? newValue) {
              if (newValue != null) onFilterChanged(category: newValue);
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350,
              minWidth: 200,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  icon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.grey[400] : const Color(0xFF1E293B),
                  ),
                  hintText: 'Search by description, customer, invoice no...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
                onChanged: (value) => onFilterChanged(query: value),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onResetFilters,
            icon: Icon(
              Icons.refresh,
              size: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            label: Text(
              'Reset',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Header row for the transactions data table.
class TransactionTableHeader extends StatelessWidget {
  const TransactionTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text('Debit (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 1,
            child: Text('Credit (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 1,
            child: Text('Balance (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 120,
            child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// 3. Individual table row displaying a transaction record.
class TransactionTableRowTile extends StatelessWidget {
  final TransactionModel txn;
  final int globalIndex;
  final VoidCallback onDelete;

  const TransactionTableRowTile({
    super.key,
    required this.txn,
    required this.globalIndex,
    required this.onDelete,
  });

  static String _fmt(double val) =>
      NumberFormat.currency(symbol: '₹ ', decimalDigits: 2).format(val);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$globalIndex', style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.date,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  txn.time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: txn.type == 'Income' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        txn.type == 'Income' ? Icons.arrow_outward : Icons.arrow_downward,
                        size: 12,
                        color: txn.type == 'Income' ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        txn.type,
                        style: TextStyle(
                          fontSize: 11,
                          color: txn.type == 'Income' ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(txn.category, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(txn.description, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              txn.type == 'Expense' ? _fmt(txn.amount) : '-',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              txn.type == 'Income' ? _fmt(txn.amount) : '-',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _fmt(txn.runningBalance),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF64748B)),
                  onPressed: () => AccountsWidgets.showTransactionDetails(context, txn),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

