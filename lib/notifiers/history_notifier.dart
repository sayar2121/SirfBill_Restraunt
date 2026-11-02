import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/billing_service.dart';

import 'package:intl/intl.dart';
import '../services/billing_history_service.dart';

class HistoryState {
  final List<Map<String, dynamic>> transactions;
  final Map<String, dynamic> summary;

  HistoryState({required this.transactions, required this.summary});
}

class HistoryNotifier extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    return _fetchHistory();
  }

  Future<HistoryState> _fetchHistory() async {
    final response = await BillingService.getPosHistory();

    final historyList = response['history'] as List? ?? [];

    final serverTransactions = historyList.map((item) {
      String dateStr = item['date'].toString();
      dateStr = dateStr.replaceAll(' ', 'T');
      if (!dateStr.endsWith('Z')) {
        dateStr += 'Z';
      }
      final dt = (DateTime.tryParse(dateStr) ?? DateTime.now()).toLocal();
      
      final rawItemsList =
          (item['items_detail'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i))
              .toList() ??
          [];
      final itemsList = rawItemsList.map((i) {
        final double price = (i['mrp'] as num?)?.toDouble() ??
            (i['price'] as num?)?.toDouble() ??
            (i['unit_price'] as num?)?.toDouble() ??
            0.0;
        final int qty = (i['qty'] as num?)?.toInt() ??
            (i['quantity'] as num?)?.toInt() ??
            1;
        final itemName = i['name'] ?? i['item_name'] ?? 'Custom Item';
        final sku = i['sku'] ?? (i['inventory_item_id'] == null ? 'CUSTOM' : '-');
        final brand = i['brand'] ?? (i['inventory_item_id'] == null ? 'Custom Item' : '-');
        return <String, dynamic>{
          'name': itemName,
          'item_name': itemName,
          'sku': sku,
          'brand': brand,
          'qty': qty,
          'quantity': qty,
          'price': price,
          'unit_price': price,
          'mrp': price,
          'total': (i['total'] as num?)?.toDouble() ?? price * qty,
          'batch': i['batch']?.toString() ?? '-',
          'expiry': i['expiry']?.toString() ?? '-',
          'hsn': i['hsn']?.toString() ?? '-',
          'cgst': (i['cgst'] as num?)?.toDouble() ?? 0.0,
          'sgst': (i['sgst'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
      double calculatedSubtotal = 0.0;
      for (var i in itemsList) {
        calculatedSubtotal +=
            ((i['mrp'] as num?)?.toDouble() ?? 0.0) *
            ((i['qty'] as num?)?.toInt() ?? 1);
      }
      double grandTotalVal = (item['amount'] as num?)?.toDouble() ?? 0.0;
      double calculatedDiscount = calculatedSubtotal > grandTotalVal
          ? calculatedSubtotal - grandTotalVal
          : 0.0;

      String rawType = item['type'] ?? 'Sale';
      if (rawType == 'POS Sale') rawType = 'Sale';
      
      String rawPayment = item['payment_mode'] ?? 'Cash';
      if (rawPayment.toUpperCase() == 'CASH') rawPayment = 'Cash';
      if (rawPayment.toUpperCase() == 'CARD') rawPayment = 'Card';
      if (rawPayment.toUpperCase() == 'UPI') rawPayment = 'UPI';

      return {
        'date': DateFormat('dd MMM yyyy').format(dt),
        'time': DateFormat('hh:mm a').format(dt),
        'createdAtDate': dt,
        'refNo': item['bill_no'],
        'customerName': item['customer_name']?.isEmpty ?? true
            ? 'Walk-in'
            : item['customer_name'],
        'customerPhone': item['customer_phone'] ?? '',
        'type': rawType,
        'items': item['items'] ?? 0,
        'amount': grandTotalVal,
        'paymentMode': rawPayment,
        'status': item['status'] ?? 'Completed',
        'originalBill': SavedBill(
          id: item['id'].toString(),
          invoiceNo: item['bill_no'].toString(),
          customerName: item['customer_name']?.isEmpty ?? true
              ? 'Walk-in'
              : item['customer_name'],
          customerPhone: item['customer_phone']?.toString() ?? '',
          customerLocation: item['customer_location']?.toString() ?? '',
          customerGstin: item['customer_gstin']?.toString() ?? '',
          doctorName: '',
          paymentMode: item['payment_mode'] ?? 'Cash',
          subtotal: calculatedSubtotal > 0 ? calculatedSubtotal : grandTotalVal,
          discount: calculatedDiscount,
          tax: 0.0,
          grandTotal: grandTotalVal,
          items: itemsList,
          createdAt: dt,
        ),
      };
    }).toList();

    // Also include local saved bills (e.g. bills with custom items)
    final localBills = await BillingHistoryService.getBillingHistory();
    final List<Map<String, dynamic>> combinedTransactions = List.from(serverTransactions);
    final Set<String> existingInvoiceNos = serverTransactions
        .map((t) => t['refNo']?.toString() ?? '')
        .where((ref) => ref.isNotEmpty)
        .toSet();

    for (final bill in localBills) {
      if (!existingInvoiceNos.contains(bill.invoiceNo)) {
        existingInvoiceNos.add(bill.invoiceNo);
        String rawPayment = bill.paymentMode;
        if (rawPayment.toUpperCase() == 'CASH') rawPayment = 'Cash';
        if (rawPayment.toUpperCase() == 'CARD') rawPayment = 'Card';
        if (rawPayment.toUpperCase() == 'UPI') rawPayment = 'UPI';

        combinedTransactions.add({
          'date': DateFormat('dd MMM yyyy').format(bill.createdAt),
          'time': DateFormat('hh:mm a').format(bill.createdAt),
          'createdAtDate': bill.createdAt,
          'refNo': bill.invoiceNo,
          'customerName': bill.customerName.isEmpty ? 'Walk-in' : bill.customerName,
          'customerPhone': bill.customerPhone,
          'type': 'Sale',
          'items': bill.items.length,
          'amount': bill.grandTotal,
          'paymentMode': rawPayment,
          'status': 'Completed',
          'originalBill': bill,
        });
      }
    }

    // Sort combined by createdAtDate descending (newest first)
    combinedTransactions.sort((a, b) {
      final dtA = a['createdAtDate'] as DateTime? ?? DateTime(2000);
      final dtB = b['createdAtDate'] as DateTime? ?? DateTime(2000);
      return dtB.compareTo(dtA);
    });

    return HistoryState(
      transactions: combinedTransactions,
      summary: Map<String, dynamic>.from(response['summary'] ?? {}),
    );
  }

  Future<void> reloadHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory());
  }
}
