import 'package:flutter/material.dart';
import '../../../../widgets/custom_pagination.dart';
import 'history_pills.dart';

class HistoryTable extends StatelessWidget {
  final List<Map<String, dynamic>> pagedTransactions;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int startIdx;
  final int endIdx;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<dynamic> onViewBill;

  const HistoryTable({
    super.key,
    required this.pagedTransactions,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.startIdx,
    required this.endIdx,
    required this.onPageChanged,
    required this.onViewBill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date & Time',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Bill No / Ref No',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Customer Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Amount (₹)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Payment Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),

                  // Table Body
                  pagedTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('No history found')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedTransactions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final tx = pagedTransactions[index];
                            final isNegative = tx['amount'] < 0;
                            final amountStr = tx['amount'] == 0
                                ? '-'
                                : tx['amount'].toStringAsFixed(2);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${startIdx + index + 1}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx['date'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tx['time'],
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tx['refNo'],
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx['customerName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (tx['customerPhone'].isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            tx['customerPhone'],
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : const Color(0xFF64748B),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: HistoryPills.buildTypePill(
                                        context,
                                        tx['type'],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${tx['items']} ${tx['items'] == 1 ? 'item' : 'items'}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF475569),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      amountStr,
                                      style: TextStyle(
                                        color: isNegative
                                            ? Colors.red
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B)),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: HistoryPills.buildPaymentModePill(
                                        context,
                                        tx['paymentMode'],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          tx['status'],
                                          style: const TextStyle(
                                            color: Color(0xFF166534),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            if (tx['originalBill'] != null) {
                                              onViewBill(tx['originalBill']);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Detailed view not available for synced backend bills yet.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            Icons.visibility,
                                            size: 14,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                          label: Text(
                                            'View',
                                            style: TextStyle(
                                              color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 32),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: Image.asset(
                                            'assets/whatsapp.png',
                                            height: 14,
                                            errorBuilder: (c, e, s) => const Icon(
                                              Icons.chat,
                                              size: 14,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                          label: const Text(
                                            'Send',
                                            style: TextStyle(
                                              color: Color(0xFF166534),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 32),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF22C55E),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            backgroundColor: const Color(0xFFDCFCE7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${totalRecords == 0 ? 0 : startIdx + 1} to $endIdx of $totalRecords records',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        CustomPagination(
                          currentPage: currentPage,
                          totalPages: totalPages,
                          onPageChanged: onPageChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
