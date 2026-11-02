import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/counter_providers.dart';

class PurchaseSearchPanel extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final bool filterByDistributor;
  final Map<String, dynamic> distributor;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFilterByDistributorChanged;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final Function(Map<String, dynamic> item) onAddItem;

  const PurchaseSearchPanel({
    super.key,
    required this.searchCtrl,
    required this.filterByDistributor,
    required this.distributor,
    required this.onSearchChanged,
    required this.onFilterByDistributorChanged,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(purchaseInventoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Search items (name, brand, barcode, batch, rack, HSN)...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Items',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.green.shade900.withValues(alpha: 0.3)
                        : Colors.green.shade50,
                    foregroundColor:
                        isDark ? Colors.greenAccent : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(
                'Show only items from this distributor',
                style: TextStyle(fontSize: 14),
              ),
              value: filterByDistributor,
              activeThumbColor: const Color(0xFF166534),
              contentPadding: EdgeInsets.zero,
              onChanged: onFilterByDistributorChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: inventory.when(
                data: (items) {
                  final q = searchCtrl.text.toLowerCase();
                  final filtered = items.where((i) {
                    final matchesSearch = i.name.toLowerCase().contains(q) ||
                        i.sku.toLowerCase().contains(q);
                    final matchesDistributor = !filterByDistributor ||
                        (i.distributorId != null &&
                            distributor['id'] != null &&
                            i.distributorId.toString() ==
                                distributor['id'].toString()) ||
                        (i.distributor != null &&
                            distributor['name'] != null &&
                            i.distributor!.toLowerCase() ==
                                distributor['name']
                                    .toString()
                                    .toLowerCase());
                    return matchesSearch && matchesDistributor;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Stock: ${item.stockQuantity} | BP: ₹${item.buyingPrice}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF166534),
                          ),
                          onPressed: () => onAddItem({
                            'id': item.id,
                            'name': item.name,
                            'buying_price': item.buyingPrice,
                            'unit_price': item.unitPrice,
                            'batch_number': item.batchNumber,
                            'expiry_date': item.expiryDate,
                            'hsn_code': item.hsnCode,
                            'gst': item.gst,
                            'rack_id': item.rackId,
                            'category_id': item.categoryId,
                          }),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF166534),
                  side: const BorderSide(color: Color(0xFF166534)),
                ),
                child: const Text('Load More Items'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
