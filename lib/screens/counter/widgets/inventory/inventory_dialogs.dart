import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/rack_dropdown.dart';
import '../../../../widgets/category_dropdown.dart';
import '../../../../widgets/distributor_dropdown.dart';
import '../../../../services/inventory_service.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../utils/responsive.dart';

class InventoryDialogs {
  static Widget _buildResponsiveRow(BuildContext context, List<Widget> children) {
    if (Responsive.isMobile(context)) {
      final List<Widget> columnChildren = [];
      for (var child in children) {
        if (child is Expanded) {
          columnChildren.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child.child,
          ));
        } else if (child is Spacer) {
          // ignore
        } else if (child is SizedBox && child.width != null) {
          // ignore
        } else {
          columnChildren.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child,
          ));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static void showEditItemDialog(BuildContext context, WidgetRef ref, InventoryItem item, Function onSuccess) {
    final nameCtrl = TextEditingController(text: item.name);
    final skuCtrl = TextEditingController(text: item.sku);
    final mfgCtrl = TextEditingController(text: item.manufacturer);
    final stockCtrl = TextEditingController(
      text: item.stockQuantity.toString(),
    );
    final lowStockCtrl = TextEditingController(
      text: item.lowStockThreshold?.toString() ?? '10',
    );
    final packSizeCtrl = TextEditingController(text: item.packSize.toString());
    final looseStockCtrl = TextEditingController(text: item.looseStock.toString());
    final buyingPriceCtrl = TextEditingController(
      text: item.buyingPrice.toString(),
    );
    final priceCtrl = TextEditingController(text: item.unitPrice.toString());
    final gstCtrl = TextEditingController(text: item.gst?.toString() ?? '0');
    final discountCtrl = TextEditingController(text: item.discount?.toString() ?? '0');
    final hsnCtrl = TextEditingController(text: item.hsnCode ?? '');
    final expiryCtrl = TextEditingController(text: item.expiryDate);
    String? selectedRackId = item.rackId;
    String? selectedCategoryId = item.categoryId;

    final allDistributors = ref.read(distributorsProvider).value ?? [];
    String? selectedDistributorId = item.distributorId;
    if (selectedDistributorId == null && item.distributor != null && item.distributor!.isNotEmpty) {
      final distMatch = allDistributors.firstWhere(
        (d) => d['name']?.toString().toLowerCase() == item.distributor!.toLowerCase(),
        orElse: () => null,
      );
      if (distMatch != null) {
        selectedDistributorId = distMatch['id']?.toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Edit Item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(context, [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: skuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Brand',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: mfgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: hsnCtrl,
                      decoration: const InputDecoration(labelText: 'HSN Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    child: TextField(
                      controller: buyingPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buying Price (₹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: gstCtrl,
                      decoration: const InputDecoration(labelText: 'GST (%)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity (Packs)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: packSizeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pieces/Pack',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: looseStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Loose Stock (Pieces)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    child: TextField(
                      controller: lowStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert At',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    child: TextField(
                      controller: discountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Discount (%)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RackDropdown(
                      selectedRackId: selectedRackId,
                      onChanged: (value) {
                        setState(() {
                          selectedRackId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryDropdown(
                      selectedCategoryId: selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResponsiveRow(context, [
                  Expanded(
                    child: DistributorDropdown(
                      selectedDistributorId: selectedDistributorId,
                      onChanged: (value) {
                        setState(() {
                          selectedDistributorId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            expiryCtrl.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await InventoryService.updateItem(item.id, {
                          'name': nameCtrl.text,
                          'sku': skuCtrl.text,
                          'manufacturer': mfgCtrl.text,
                          'stock_quantity': int.tryParse(stockCtrl.text) ?? 0,
                          'pack_size': int.tryParse(packSizeCtrl.text) ?? 1,
                          'loose_stock': int.tryParse(looseStockCtrl.text) ?? 0,
                          'low_stock_threshold':
                              int.tryParse(lowStockCtrl.text) ?? 10,
                          'buying_price':
                              double.tryParse(buyingPriceCtrl.text) ?? 0.0,
                          'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                          'gst': double.tryParse(gstCtrl.text) ?? 0.0,
                          'discount': double.tryParse(discountCtrl.text) ?? 0.0,
                          'rack_id': selectedRackId,
                          'category_id': selectedCategoryId,
                          'distributor_id': selectedDistributorId,
                          if (selectedDistributorId != null) ...{
                            'distributor': allDistributors.firstWhere(
                              (d) => d['id']?.toString() == selectedDistributorId,
                              orElse: () => null,
                            )?['name'],
                            'distributor_name': allDistributors.firstWhere(
                              (d) => d['id']?.toString() == selectedDistributorId,
                              orElse: () => null,
                            )?['name'],
                          },
                          'hsn_code': hsnCtrl.text,
                          'expiry_date': expiryCtrl.text,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onSuccess();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ), // closes Column
        ), // closes SingleChildScrollView
        ), // closes Container
      ), // closes Dialog
    ), // closes StatefulBuilder
    ); // closes showDialog
  }
}
