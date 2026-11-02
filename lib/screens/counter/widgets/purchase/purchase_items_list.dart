import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/counter_providers.dart';

class PurchaseItemsList extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index, int qty) onQuantityChanged;
  final Function(int index, double price) onBuyingPriceChanged;
  final Function(int index, double price) onSellingPriceChanged;
  final Function(int index, String batch) onBatchChanged;
  final Function(int index, String expiry) onExpiryChanged;
  final Function(int index, double gst) onGstChanged;
  final Function(int index, String hsn) onHsnChanged;
  final Function(int index, String? rackId) onRackChanged;
  final Function(int index, String? categoryId) onCategoryChanged;
  final Function(int index) onRemoveItem;

  const PurchaseItemsList({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onBuyingPriceChanged,
    required this.onSellingPriceChanged,
    required this.onBatchChanged,
    required this.onExpiryChanged,
    required this.onGstChanged,
    required this.onHsnChanged,
    required this.onRackChanged,
    required this.onCategoryChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final racks = ref.watch(rackProvider);
    final categories = ref.watch(categoryProvider);

    if (items.isEmpty) {
      return const Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No items added yet. Select items from search or add new.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(
              item['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Qty: '),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: item['quantity'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            onQuantityChanged(index, int.tryParse(v) ?? 1),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('BP: ₹'),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item['buying_price'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            onBuyingPriceChanged(index, double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SP: ₹'),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item['selling_price'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            onSellingPriceChanged(index, double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Batch: '),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: item['batch_number'].toString(),
                        onChanged: (v) => onBatchChanged(index, v),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Exp: '),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: item['expiry_date'].toString(),
                        decoration:
                            const InputDecoration(hintText: 'YYYY-MM-DD'),
                        onChanged: (v) => onExpiryChanged(index, v),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('GST %: '),
                    SizedBox(
                      width: 50,
                      child: TextFormField(
                        initialValue: item['gst'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            onGstChanged(index, double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('HSN: '),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item['hsn_code'].toString(),
                        onChanged: (v) => onHsnChanged(index, v),
                      ),
                    ),
                  ],
                ),
                racks.when(
                  data: (rList) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Rack: '),
                      DropdownButton<String>(
                        value: item['rack_id'],
                        hint: const Text('Select'),
                        items: rList
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.rackNumber),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => onRackChanged(index, v),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                categories.when(
                  data: (cList) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Category: '),
                      DropdownButton<String>(
                        value: item['category_id'],
                        hint: const Text('Select'),
                        items: cList
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => onCategoryChanged(index, v),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onRemoveItem(index),
            ),
          );
        },
      ),
    );
  }
}
