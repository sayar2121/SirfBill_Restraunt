import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/distributor_provider.dart';
import '../../providers/counter_providers.dart';
import '../../config/api_constants.dart';
import '../../services/account_service.dart';
import 'package:go_router/go_router.dart';

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
            // Info Card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
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
                          Text(distributor['name'] ?? 'N/A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Text('Contact Person: ${distributor['contact_person'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B))),
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
                          child: Text('GSTIN: ${distributor['gstin'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/counter/distributors/purchase', extra: distributor);
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 16),
                          label: const Text('New Purchase Bill', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Analytics Section
            const Text(
              'Sales Analytics (Top 5 Items)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            analyticsAsync.when(
              data: (analytics) {
                final topItems = (analytics['top_selling_items'] ??
                        analytics['top_selling_medicines'])
                    as List<dynamic>? ??
                    [];
                
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
                                  const Text('Total Revenue Generated', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text('₹${analytics['total_revenue_generated'] ?? 0.0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
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
                                  const Text('Total Items Sold', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text('${analytics['total_items_sold'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
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
                          child: Text('No sales data available for this distributor yet.', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      )
                    else
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
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
                                child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
              error: (err, stack) => Center(child: Text('Error loading analytics: $err', style: const TextStyle(color: Colors.red))),
            ),
            
            const SizedBox(height: 32),
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
                    // Sort descending by date
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
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
                            onTap: () {
                              _showBillDetails(context, ref, bill);
                            },
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

  void _showBillDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> bill) {
    final items = (bill['items'] as List<dynamic>?) ?? [];
    final inventoryList = ref.read(inventoryProvider).value ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice: ${bill['invoice_no'] ?? 'N/A'}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: bill['payment_status'] == 'PAID' ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bill['payment_status'] ?? 'UNPAID',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: bill['payment_status'] == 'PAID' ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${bill['bill_date']?.toString().split('T')[0] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final invItem = inventoryList.where((i) => i.id == item['inventory_item_id']).firstOrNull;
                      final itemName = invItem != null ? invItem.name : 'Unknown Item (${item['inventory_item_id']})';
                      
                      return ListTile(
                        title: Text(itemName),
                        subtitle: Text('Qty: ${item['quantity']} • Batch: ${item['batch_number'] ?? 'N/A'} • Exp: ${item['expiry_date'] ?? 'N/A'}'),
                        trailing: Text('₹${item['unit_price'] ?? 0.0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final totalAmount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
                  final subtotal = (bill['subtotal'] as num?)?.toDouble() ?? 0.0;
                  final totalGst = (bill['total_gst'] as num?)?.toDouble() ?? 0.0;
                  final totalDiscount = (bill['total_discount'] as num?)?.toDouble() ?? 0.0;
                  final billTotal = totalAmount > 0
                      ? totalAmount
                      : (subtotal + totalGst - totalDiscount);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text('₹${billTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Generate PDF'),
            onPressed: () async {
              final billId = bill['id'];
              if (billId != null) {
                final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/purchases/$billId/pdf');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
          if (bill['payment_status'] != 'PAID')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
              onPressed: () async {
                final billTotal = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
                final amountPaid = (bill['amount_paid'] as num?)?.toDouble() ?? 0.0;
                final dueAmount = (billTotal - amountPaid) > 0 ? (billTotal - amountPaid) : billTotal;

                List<AccountModel> accounts = [];
                try {
                  accounts = await AccountService.getAccounts();
                } catch (_) {}

                final assetAccounts = accounts
                    .where((a) => a.accountType.toUpperCase() == 'ASSET')
                    .toList();
                final totalFunds = assetAccounts.fold<double>(
                  0.0,
                  (sum, acc) => sum + acc.balance,
                );

                if (assetAccounts.isEmpty || totalFunds < dueAmount) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 52),
                        title: const Text('No Money in Accounts Section', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'There is not enough money in the accounts section to pay this purchase bill.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Bill Due Amount:'),
                                      Text('₹${dueAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Available in Accounts:'),
                                      Text('₹${totalFunds.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Shortage:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('₹${(dueAmount - totalFunds).clamp(0.0, double.infinity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Please deposit money into Accounts first before marking this purchase bill as paid.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Understood'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                try {
                  // Call service to pay bill
                  final svc = ref.read(purchaseServiceProvider);
                  await svc.markBillAsPaid(bill['id']);
                  
                  // Refresh the UI
                  ref.invalidate(purchaseBillsProvider);
                  ref.invalidate(accountsProvider);
                  ref.invalidate(historyProvider);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill marked as PAID! Deducted from Accounts.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        title: const Text('Payment Failed'),
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: const TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
