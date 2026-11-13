import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';

import 'widgets/purchase/add_purchase_item_dialog.dart';
import 'widgets/purchase/purchase_search_panel.dart';
import 'widgets/purchase/purchase_items_list.dart';
import 'widgets/purchase/purchase_bill_summary.dart';
import 'widgets/purchase/purchase_actions_bar.dart';
import 'widgets/purchase/purchase_bill_submit_helper.dart';

class AddPurchaseBillScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> distributor;
  const AddPurchaseBillScreen({super.key, required this.distributor});

  @override
  ConsumerState<AddPurchaseBillScreen> createState() =>
      _AddPurchaseBillScreenState();
}

class _AddPurchaseBillScreenState extends ConsumerState<AddPurchaseBillScreen> {
  final List<Map<String, dynamic>> _items = [];
  final _searchCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  String _paymentStatus = 'UNPAID';
  double _amountPaid = 0.0;
  double _globalDiscount = 0.0;

  bool _isLoading = false;
  bool _filterByDistributor = false;
  Timer? _searchDebounce;

  double get _subtotal {
    double total = 0;
    for (var item in _items) {
      total += (item['buying_price'] as double) * (item['quantity'] as int);
    }
    return total;
  }

  double get _totalGst {
    double total = 0;
    for (var item in _items) {
      double bp = (item['buying_price'] as double);
      double qty = (item['quantity'] as int).toDouble();
      double gstPercent = (item['gst'] as double?) ?? 0.0;
      double itemTotal = bp * qty;
      total += itemTotal * (gstPercent / 100);
    }
    return total;
  }

  double get _grandTotal {
    return _subtotal + _totalGst - _globalDiscount;
  }

  @override
  void initState() {
    super.initState();
    _invoiceCtrl.text =
        'INV-PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  void _addItem(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _items.indexWhere(
        (i) => i['inventory_item_id'] == product['id'],
      );
      if (existingIndex >= 0) {
        _items[existingIndex]['quantity'] += 1;
      } else {
        _items.add({
          'inventory_item_id': product['id'],
          'name': product['name'],
          'quantity': 1,
          'buying_price': product['buying_price'] ?? 0.0,
          'selling_price': product['unit_price'] ?? 0.0,
          'batch_number': product['batch_number'] ?? '',
          'expiry_date': product['expiry_date'] ?? '',
          'hsn_code': product['hsn_code'] ?? '',
          'gst': product['gst'] ?? 0.0,
          'rack_id': product['rack_id'],
          'category_id': product['category_id'],
        });
      }
    });
  }

  void _submit() async {
    if (_items.isEmpty) return;

    setState(() => _isLoading = true);
    await PurchaseBillSubmitHelper.submitPurchaseBill(
      context: context,
      ref: ref,
      distributorId: widget.distributor['id'],
      invoiceNo: _invoiceCtrl.text,
      paymentStatus: _paymentStatus,
      amountPaid: _amountPaid,
      grandTotal: _grandTotal,
      subtotal: _subtotal,
      totalDiscount: _globalDiscount,
      totalGst: _totalGst,
      items: _items,
      onPaymentStatusChangedToUnpaid: () {
        setState(() {
          _paymentStatus = 'UNPAID';
          _amountPaid = 0.0;
        });
      },
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchPanel = PurchaseSearchPanel(
      searchCtrl: _searchCtrl,
      filterByDistributor: _filterByDistributor,
      distributor: widget.distributor,
      onSearchChanged: (val) {
        if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 500), () {
          ref.read(purchaseInventoryProvider.notifier).loadInventory(
                searchQuery: val,
                distributorId:
                    _filterByDistributor ? widget.distributor['id'] : null,
              );
        });
        setState(() {});
      },
      onFilterByDistributorChanged: (val) {
        setState(() => _filterByDistributor = val);
        ref.read(purchaseInventoryProvider.notifier).loadInventory(
              searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
              distributorId: val ? widget.distributor['id'] : null,
            );
      },
      onRefresh: () {
        ref.read(purchaseInventoryProvider.notifier).loadInventory(
              searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
              distributorId:
                  _filterByDistributor ? widget.distributor['id'] : null,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item list refreshed!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onLoadMore: () =>
          ref.read(purchaseInventoryProvider.notifier).loadMore(),
      onAddItem: _addItem,
    );

    final billPanel = Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Incoming Stock',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (!isDesktop)
                Text(
                  'Items: ${_items.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PurchaseItemsList(
              items: _items,
              onQuantityChanged: (i, qty) =>
                  setState(() => _items[i]['quantity'] = qty),
              onBuyingPriceChanged: (i, bp) =>
                  setState(() => _items[i]['buying_price'] = bp),
              onSellingPriceChanged: (i, sp) =>
                  setState(() => _items[i]['selling_price'] = sp),
              onBatchChanged: (i, b) =>
                  setState(() => _items[i]['batch_number'] = b),
              onExpiryChanged: (i, exp) =>
                  setState(() => _items[i]['expiry_date'] = exp),
              onGstChanged: (i, gst) =>
                  setState(() => _items[i]['gst'] = gst),
              onHsnChanged: (i, hsn) =>
                  setState(() => _items[i]['hsn_code'] = hsn),
              onRackChanged: (i, rId) =>
                  setState(() => _items[i]['rack_id'] = rId),
              onCategoryChanged: (i, cId) =>
                  setState(() => _items[i]['category_id'] = cId),
              onRemoveItem: (i) => setState(() => _items.removeAt(i)),
            ),
          ),
          const Divider(),
          PurchaseBillSummary(
            subtotal: _subtotal,
            totalGst: _totalGst,
            globalDiscount: _globalDiscount,
            grandTotal: _grandTotal,
            paymentStatus: _paymentStatus,
            amountPaid: _amountPaid,
            onDiscountChanged: (disc) =>
                setState(() => _globalDiscount = disc),
            onPaymentStatusChanged: (status) {
              setState(() {
                _paymentStatus = status;
                if (_paymentStatus == 'PAID') _amountPaid = _grandTotal;
              });
            },
            onAmountPaidChanged: (paid) => setState(() => _amountPaid = paid),
          ),
        ],
      ),
    );

    final actionsBar = PurchaseActionsBar(
      invoiceController: _invoiceCtrl,
      isLoading: _isLoading,
      onAddNewItem: () => showAddPurchaseItemDialog(
        context: context,
        ref: ref,
        distributor: widget.distributor,
        onItemAdded: (newItem, requestedQty) {
          setState(() {
            _items.add({
              'inventory_item_id': newItem['id'],
              'name': newItem['name'],
              'quantity': requestedQty > 0 ? requestedQty : 1,
              'loose_quantity': 0,
              'pack_size': newItem['pack_size'] ?? 1,
              'buying_price':
                  (newItem['buying_price'] as num?)?.toDouble() ?? 0.0,
              'selling_price':
                  (newItem['unit_price'] as num?)?.toDouble() ?? 0.0,
              'expiry_date': newItem['expiry_date'] ?? '',
              'hsn_code': newItem['hsn_code'] ?? '',
              'gst': (newItem['gst'] as num?)?.toDouble() ?? 0.0,
              'rack_id': newItem['rack_id'],
              'category_id': newItem['category_id'],
            });
          });
        },
      ),
      onConfirmPurchase: _submit,
    );

    if (!isDesktop) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Purchase from ${widget.distributor['name']}',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: isDark
                ? Theme.of(context).appBarTheme.backgroundColor
                : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 1,
            bottom: const TabBar(
              labelColor: Color(0xFF166534),
              indicatorColor: Color(0xFF166534),
              tabs: [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.receipt), text: 'Bill'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              searchPanel,
              billPanel,
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: actionsBar,
              ),
            ),
          ),
        ),
      );
    }

    // Desktop Layout
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Purchase from ${widget.distributor['name']}'),
        backgroundColor: isDark
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: actionsBar,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(flex: 1, child: searchPanel),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          Expanded(flex: 2, child: billPanel),
        ],
      ),
    );
  }
}
