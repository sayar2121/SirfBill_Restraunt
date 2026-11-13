import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/distributor_provider.dart';
import 'widgets/distributors/distributor_components.dart';
import 'widgets/distributors/purchase_bill_detail_dialog.dart';

/// Screen displaying complete distributor profile, sales analytics, and purchase history.
class DistributorDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> distributor;
  const DistributorDetailScreen({super.key, required this.distributor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(distributorAnalyticsProvider(distributor['id']));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(distributor['name'] ?? 'Distributor Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Distributor Contact & Info Card
            DistributorInfoCard(distributor: distributor),
            const SizedBox(height: 24),

            // 2. Sales Analytics Section
            const Text(
              'Sales Analytics (Top 5 Items)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            analyticsAsync.when(
              data: (analytics) => DistributorAnalyticsSection(analytics: analytics),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
              error: (err, stack) => Center(child: Text('Error loading analytics: $err', style: const TextStyle(color: Colors.red))),
            ),

            const SizedBox(height: 32),

            // 3. Previous Purchase Bills List
            const Text(
              'Previous Purchase Bills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final billsAsync = ref.watch(purchaseBillsProvider);

                return billsAsync.when(
                  data: (bills) {
                    final distBills = bills.where((b) => b['distributor_id'] == distributor['id']).toList();
                    distBills.sort((a, b) {
                      final da = DateTime.tryParse(a['bill_date'] ?? '') ?? DateTime(2000);
                      final db = DateTime.tryParse(b['bill_date'] ?? '') ?? DateTime(2000);
                      return db.compareTo(da);
                    });

                    if (distBills.isEmpty) {
                      return const Card(
                        color: Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No previous bills found for this distributor.', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: distBills.length,
                      itemBuilder: (context, index) {
                        final bill = distBills[index];
                        final dateStr = bill['bill_date'] != null
                            ? bill['bill_date'].toString().split('T')[0]
                            : 'Unknown Date';

                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.receipt_long, color: Color(0xFF3B82F6)),
                            ),
                            title: Text('Invoice: ${bill['invoice_no'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: $dateStr • Items: ${bill['items']?.length ?? 0}'),
                            trailing: Builder(
                              builder: (context) {
                                final totalAmount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
                                final subtotal = (bill['subtotal'] as num?)?.toDouble() ?? 0.0;
                                final totalGst = (bill['total_gst'] as num?)?.toDouble() ?? 0.0;
                                final totalDiscount = (bill['total_discount'] as num?)?.toDouble() ?? 0.0;
                                final billTotal = totalAmount > 0
                                    ? totalAmount
                                    : (subtotal + totalGst - totalDiscount);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${billTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(
                                      bill['payment_status'] ?? 'UNPAID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: bill['payment_status'] == 'PAID' ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            onTap: () => PurchaseBillDetailDialog.show(context, bill),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text('Error loading bills: $err', style: const TextStyle(color: Colors.red))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
