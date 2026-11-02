import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../services/inventory_service.dart';

void showAddPurchaseItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> distributor,
  required Function(Map<String, dynamic> newItem, int requestedQty) onItemAdded,
}) {
  final nameCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final mfgCtrl = TextEditingController();
  final bpCtrl = TextEditingController();
  final spCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final packSizeCtrl = TextEditingController(text: '1');
  final gstCtrl = TextEditingController(text: '0');
  final discountCtrl = TextEditingController(text: '0');
  final expiryCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();

  String? selectedRackId;
  String? selectedCategoryId;
  bool isSaving = false;

  final rList = ref.read(rackProvider).value ?? [];
  final cList = ref.read(categoryProvider).value ?? [];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        InputDecoration inputDec(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF166534), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 850,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF166534),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Add New Item',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: inputDec('Item Name *'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: mfgCtrl,
                            decoration: inputDec('Manufacturer'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: bpCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('Buying Price (₹) *'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: spCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('Selling Price (MRP ₹) *'),
                          ),
                        ),
                        SizedBox(
                          width: 173,
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('Initial Stock (Packs)'),
                          ),
                        ),
                        SizedBox(
                          width: 173,
                          child: TextField(
                            controller: packSizeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('Pieces/Pack'),
                          ),
                        ),
                        SizedBox(
                          width: 173,
                          child: TextField(
                            controller: gstCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('GST (%)'),
                          ),
                        ),
                        SizedBox(
                          width: 173,
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDec('Discount (%)'),
                          ),
                        ),
                        SizedBox(
                          width: 173,
                          child: TextField(
                            controller: expiryCtrl,
                            decoration: inputDec('Expiry (Optional)'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: hsnCtrl,
                            decoration: inputDec('HSN Code'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: TextField(
                            controller: skuCtrl,
                            decoration: inputDec('Barcode / SKU'),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: DropdownButtonFormField<String>(
                            decoration: inputDec('Category'),
                            initialValue: selectedCategoryId,
                            items: cList
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedCategoryId = v),
                          ),
                        ),
                        SizedBox(
                          width: 370,
                          child: DropdownButtonFormField<String>(
                            decoration: inputDec('Rack / Location'),
                            initialValue: selectedRackId,
                            items: rList
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.rackNumber),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedRackId = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (nameCtrl.text.isEmpty ||
                                    bpCtrl.text.isEmpty ||
                                    spCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please fill required fields *'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() => isSaving = true);
                                try {
                                  final newItem = await InventoryService.addItem({
                                    'name': nameCtrl.text,
                                    'sku': skuCtrl.text.isNotEmpty
                                        ? skuCtrl.text
                                        : DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                    'manufacturer': mfgCtrl.text,
                                    'buying_price':
                                        double.tryParse(bpCtrl.text) ?? 0.0,
                                    'unit_price':
                                        double.tryParse(spCtrl.text) ?? 0.0,
                                    'stock_quantity': 0,
                                    'pack_size':
                                        int.tryParse(packSizeCtrl.text) ?? 1,
                                    'loose_stock': 0,
                                    'gst':
                                        double.tryParse(gstCtrl.text) ?? 0.0,
                                    'discount':
                                        double.tryParse(discountCtrl.text) ??
                                            0.0,
                                    'expiry_date': expiryCtrl.text,
                                    'hsn_code': hsnCtrl.text.isNotEmpty
                                        ? hsnCtrl.text
                                        : '3004',
                                    'distributor_id': distributor['id'],
                                    'distributor': distributor['name'],
                                    'distributor_name': distributor['name'],
                                    'rack_id': selectedRackId,
                                    'category_id': selectedCategoryId,
                                  });
                                  if (context.mounted) {
                                    final requestedQty =
                                        int.tryParse(stockCtrl.text) ?? 1;
                                    onItemAdded(newItem, requestedQty);
                                    ref.invalidate(inventoryProvider);
                                    ref.invalidate(purchaseInventoryProvider);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Item created & added to bill!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isSaving = false);
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
