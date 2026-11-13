import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 1. Top card displaying distributor contact details and New Purchase Bill CTA.
class DistributorInfoCard extends StatelessWidget {
  final Map<String, dynamic> distributor;

  const DistributorInfoCard({super.key, required this.distributor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.business, color: Color(0xFF166534), size: 32),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(distributor['name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text('Contact Person: ${distributor['contact_person'] ?? 'N/A'}',
                      style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('Phone: ${distributor['phone'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('Email: ${distributor['email'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('Address: ${distributor['address'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('GSTIN: ${distributor['gstin'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/counter/distributors/purchase', extra: distributor);
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('New Purchase Bill', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. KPI cards and Top Selling Items list for this distributor.
class DistributorAnalyticsSection extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const DistributorAnalyticsSection({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final topItems = (analytics['top_selling_items'] ?? analytics['top_selling_medicines']) as List<dynamic>? ?? [];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                color: const Color(0xFFE8F5E9),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Revenue Generated',
                          style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('₹${analytics['total_revenue_generated'] ?? 0.0}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: const Color(0xFFEFF6FF),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Items Sold',
                          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('${analytics['total_items_sold'] ?? 0}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (topItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No sales data available for this distributor yet.',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
          )
        else
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = topItems[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Text('${index + 1}',
                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Sold: ${item['quantity_sold'] ?? 0} units'),
                  trailing: const Icon(Icons.trending_up, color: Color(0xFF166534)),
                );
              },
            ),
          ),
      ],
    );
  }
}

