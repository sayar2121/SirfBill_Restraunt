import 'package:flutter/material.dart';

class BillingHeaderWidget extends StatelessWidget {
  final VoidRefreshCallback onRefresh;

  const BillingHeaderWidget({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Bill',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Create a new invoice, search items and add to cart',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef VoidRefreshCallback = void Function();
