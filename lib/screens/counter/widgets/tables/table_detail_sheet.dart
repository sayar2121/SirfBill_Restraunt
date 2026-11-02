import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class TableDetailSheet extends StatelessWidget {
  final DiningTable table;
  final ValueChanged<TableStatus> onUpdateStatus;
  final VoidCallback onOpenPos;

  const TableDetailSheet({
    super.key,
    required this.table,
    required this.onUpdateStatus,
    required this.onOpenPos,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Table ${table.label}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Floor: ${table.floor} • Capacity: ${table.capacity} Guests',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const Divider(height: 24),

          // Status Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  onUpdateStatus(TableStatus.available);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Available'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  onUpdateStatus(TableStatus.occupied);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.people_alt_rounded, size: 16),
                label: const Text('Occupied'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  onUpdateStatus(TableStatus.reserved);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.bookmark_added_rounded, size: 16),
                label: const Text('Reserve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Open POS CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onOpenPos();
              },
              icon: const Icon(Icons.point_of_sale_rounded),
              label: const Text('Open POS & Take Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
