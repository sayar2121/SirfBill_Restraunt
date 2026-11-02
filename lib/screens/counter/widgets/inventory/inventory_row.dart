import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/inventory_service.dart';
import '../../../../config/api_constants.dart';
import 'status_badge.dart';

class InventoryRowLeftWidget extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final bool isDesktopWidth;

  const InventoryRowLeftWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.isDesktopWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFF1F5F9),
      child: Container(
        height: 72,
        padding: EdgeInsets.symmetric(horizontal: isDesktopWidth ? 24 : 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                image:
                    (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(
                          '${ApiConstants.baseUrl}${item.imageUrl}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                  ? const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.manufacturer.isNotEmpty
                        ? item.manufacturer
                        : 'Unknown',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryRowRightWidget extends StatelessWidget {
  final InventoryItem item;
  final String rackName;
  final String categoryName;
  final String? distributorName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDesktopWidth;

  const InventoryRowRightWidget({
    super.key,
    required this.item,
    required this.rackName,
    required this.categoryName,
    this.distributorName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isDesktopWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.stockQuantity <= 0
        ? 'Out of Stock'
        : (item.stockQuantity <= (item.lowStockThreshold ?? 10)
              ? 'Low Stock'
              : (item.stockQuantity <= 50 ? 'Medium Stock' : 'OK'));

    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFF1F5F9),
      child: Container(
        height: 72,
        padding: EdgeInsets.symmetric(horizontal: isDesktopWidth ? 24 : 8),
        child: Row(
          children: [
            Expanded(
              flex: 120,
              child: Text(
                categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.createdAt != null
                        ? DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(item.createdAt!).toLocal(),
                          )
                        : 'N/A',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12,
                    ),
                  ),
                  if (item.updatedAt != null)
                    Text(
                      'Updated: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(item.updatedAt!).toLocal())}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 100,
              child: Text(
                item.looseStock > 0
                    ? '${item.stockQuantity} Pk, ${item.looseStock} Pc'
                    : item.stockQuantity.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.stockQuantity <= 0 && item.looseStock <= 0
                      ? const Color(0xFFDC2626) // Red
                      : (item.stockQuantity <=
                                (item.lowStockThreshold ?? 10)
                            ? const Color(0xFFD97706) // Yellow/Orange
                            : (item.stockQuantity <= 50
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF16A34A))), // Blue / Green
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 80,
              child: Text(
                rackName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 100,
              child: Text(
                '₹${item.buyingPrice.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 100,
              child: Text(
                '₹${item.unitPrice.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 80,
              child: Text(
                item.gst != null && item.gst! > 0
                    ? '${item.gst!.toStringAsFixed(1)}%'
                    : '-',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 120,
              child: Text(
                (distributorName != null && distributorName!.isNotEmpty)
                    ? distributorName!
                    : (item.distributor ?? '-'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 100,
              child: Text(
                item.expiryDate,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
            Expanded(
              flex: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: status),
              ),
            ),
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
