import 'package:flutter/material.dart';
import '../../../../notifiers/billing_notifier.dart';
import '../../../../utils/format_utils.dart';
import '../../../../widgets/horizontal_scroll_wrapper.dart';

class BillingCartTable extends StatefulWidget {
  final BillingState billingState;
  final BillingNotifier notifier;
  final Function(int) onIncreaseQty;
  final Function(int) onDecreaseQty;
  final Function(int) onRemoveItem;
  final Function(int, double) onUpdateItemDiscount;

  const BillingCartTable({
    super.key,
    required this.billingState,
    required this.notifier,
    required this.onIncreaseQty,
    required this.onDecreaseQty,
    required this.onRemoveItem,
    required this.onUpdateItemDiscount,
  });

  @override
  State<BillingCartTable> createState() => _BillingCartTableState();
}

class _BillingCartTableState extends State<BillingCartTable> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return       // Bill Table
      LayoutBuilder(
        builder: (context, tableConstraints) {
          return HorizontalMouseTouchpadScroll(
            controller: _scrollController,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 500,
                maxWidth: tableConstraints.maxWidth > 500
                    ? tableConstraints.maxWidth
                    : 500,
              ),
              child: Column(
                children: [
                  // Bill Table Header
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Item Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Disc (%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price (₹)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'GST (%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total (₹)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bill Table Body
                  widget.billingState.currentBill.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Cart is empty',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.billingState.currentBill.length,
                          separatorBuilder: (context, index) =>
                              Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                          itemBuilder: (context, index) {
                            final item = widget.billingState.currentBill[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'].toString().split(' - Item')[0],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          item['brand'],
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                            fontSize: 9,
                                          ),
                                        ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context).dividerColor,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  widget.onDecreaseQty(index),
                                              child: const Padding(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              FormatUtils.formatQty(item),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  widget.onIncreaseQty(index),
                                              child: const Padding(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 24,
                                        width: 40,
                                        child: TextFormField(
                                          initialValue: (item['discount'] as num?)?.toString() ?? '0',
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 10),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            final disc = double.tryParse(val) ?? 0.0;
                                            widget.onUpdateItemDiscount(index, disc);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 24,
                                        width: 55,
                                        child: TextFormField(
                                          key: ValueKey('price_${item['name']}_$index'),
                                          initialValue: (item['price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00',
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            final newPrice = double.tryParse(val) ?? 0.0;
                                            widget.notifier.updateItemPrice(index, newPrice);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 24,
                                        width: 48,
                                        child: TextFormField(
                                          key: ValueKey('gst_${item['name']}_$index'),
                                          initialValue: (((item['cgst'] as num? ?? 0.0) + (item['sgst'] as num? ?? 0.0))).toStringAsFixed(1),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                                          ),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            final newGst = double.tryParse(val) ?? 0.0;
                                            widget.notifier.updateItemGst(index, newGst);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item['total'].toStringAsFixed(2),
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 45,
                                    child: InkWell(
                                      onTap: () => widget.onRemoveItem(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            ),
          ),
          );
        },
      );
  }
}
