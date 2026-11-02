import 'package:flutter/material.dart';

class InventorySortableHeader extends StatelessWidget {
  final String title;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSort;

  const InventorySortableHeader({
    super.key,
    required this.title,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onSort(title),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (sortColumn == title)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: const Color(0xFF22C55E),
            )
          else
            const Icon(Icons.unfold_more, size: 14, color: Colors.black26),
        ],
      ),
    );
  }
}
