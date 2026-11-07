import 'package:flutter/material.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import 'pos_customer_bar.dart';
import 'pos_table_selector.dart';

/// Clean top header component for POS Cart: Table selector, customer selector, active order badge, and clear cart
class PosCartHeaderSection extends StatelessWidget {
  final RestaurantPosState posState;
  final List<DiningTable> liveTables;
  final List<Map<String, dynamic>> customersList;
  final void Function(String floor) onSelectFloor;
  final void Function(String tableId) onSelectTable;
  final Future<void> Function() onRefreshTables;
  final void Function(Map<String, dynamic> cust) onSelectCustomer;
  final VoidCallback onClearCustomer;
  final VoidCallback onAddNewCustomer;
  final VoidCallback onClearCart;

  const PosCartHeaderSection({
    super.key,
    required this.posState,
    required this.liveTables,
    required this.customersList,
    required this.onSelectFloor,
    required this.onSelectTable,
    required this.onRefreshTables,
    required this.onSelectCustomer,
    required this.onClearCustomer,
    required this.onAddNewCustomer,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Selector (Dine-in only)
          if (posState.orderType == OrderType.dineIn) ...[
            PosTableSelector(
              selectedFloor: posState.selectedFloor,
              selectedTableId: posState.selectedTableId,
              tables: liveTables,
              onSelectFloor: onSelectFloor,
              onSelectTable: onSelectTable,
              onRefresh: onRefreshTables,
            ),
            const SizedBox(height: 8),
          ],

          // Customer Bar
          PosCustomerBar(
            customers: customersList,
            selectedCustomerName: posState.customerName,
            selectedCustomerPhone: posState.customerPhone,
            onSelectCustomer: onSelectCustomer,
            onClearCustomer: onClearCustomer,
            onAddNew: onAddNewCustomer,
          ),
          const SizedBox(height: 8),

          // Active Order Banner (when editing an existing held order)
          if (posState.activeOrderNumber != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editing Saved Order: ${posState.activeOrderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const Text(
                          'Add new items or modify, then tap "Update Order".',
                          style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'HELD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Items Header with Cart Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${posState.cart.length})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              InkWell(
                onTap: posState.cart.isEmpty ? null : onClearCart,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: posState.cart.isEmpty
                        ? Colors.transparent
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: posState.cart.isEmpty
                          ? Colors.transparent
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        size: 16,
                        color: posState.cart.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear Cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: posState.cart.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 10),
        ],
      ),
    );
  }
}
