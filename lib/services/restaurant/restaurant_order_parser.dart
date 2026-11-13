import '../../models/restaurant_pos_models.dart';

/// Standalone parser for converting backend Restaurant Order JSON into [RestaurantOrder] models.
class RestaurantOrderParser {
  /// Parses a raw JSON object into a [RestaurantOrder].
  static RestaurantOrder fromJson(dynamic json) {
    final rawId = json['id'] ?? json['order_id'] ?? '';
    final rawOrderNum = json['order_number'] ??
        json['order_no'] ??
        '#ORD-${rawId.toString().substring(0, rawId.toString().length > 6 ? 6 : rawId.toString().length)}';

    final rawType = (json['order_type'] ?? 'DINE_IN').toString().toUpperCase();
    OrderType orderType = OrderType.dineIn;
    if (rawType.contains('TAKEAWAY') || rawType.contains('TAKE_AWAY') || rawType.contains('PARCEL')) {
      orderType = OrderType.takeaway;
    } else if (rawType.contains('DELIVERY')) {
      orderType = OrderType.delivery;
    }

    final orderStatusStr =
        (json['status'] ?? json['order_status'] ?? json['state'] ?? 'OPEN').toString().toUpperCase();
    final kitchenStatusStr = (json['kitchen_status'] ?? json['kot_status'] ?? '').toString().toUpperCase();

    // Check attached kitchen tickets and kots
    bool anyKotServed = false;
    bool allKotsServed = true;
    bool hasKots = false;
    bool anyKotReady = false;

    void inspectKots(dynamic list) {
      if (list is List && list.isNotEmpty) {
        hasKots = true;
        for (final kt in list) {
          if (kt is Map) {
            final s = (kt['status'] ?? kt['kot_status'] ?? '').toString().toUpperCase();
            if (s == 'SERVED' || s.contains('SERVED') || s == 'DELIVERED') {
              anyKotServed = true;
            } else {
              allKotsServed = false;
            }
            if (s == 'READY' || s.contains('READY') || s == 'FOOD_READY' || s == 'PREPARED') {
              anyKotReady = true;
            }
          }
        }
      }
    }

    inspectKots(json['kitchen_tickets']);
    inspectKots(json['kots']);

    String rawStatus = orderStatusStr;

    // Priority 1: Explicitly SERVED or DELIVERED (either on order, kitchen, or attached tickets)
    if (kitchenStatusStr == 'SERVED' ||
        kitchenStatusStr == 'DELIVERED' ||
        orderStatusStr == 'SERVED' ||
        orderStatusStr == 'DELIVERED' ||
        (hasKots && (allKotsServed || (anyKotServed && !anyKotReady)))) {
      rawStatus = 'SERVED';
    }
    // Priority 2: Explicitly READY
    else if (kitchenStatusStr == 'READY' ||
        orderStatusStr == 'READY' ||
        orderStatusStr.contains('READY') ||
        orderStatusStr == 'FOOD_READY' ||
        orderStatusStr == 'PREPARED' ||
        anyKotReady) {
      rawStatus = 'READY';
    }

    OrderStatus orderStatus = OrderStatus.active;
    if (rawStatus == 'READY' || rawStatus.contains('READY') || rawStatus == 'FOOD_READY' || rawStatus == 'PREPARED') {
      orderStatus = OrderStatus.ready;
    } else if (rawStatus == 'SERVED' || rawStatus == 'DELIVERED') {
      orderStatus = OrderStatus.served;
    } else if (rawStatus.contains('SETTLED') || rawStatus.contains('COMPLETE') || rawStatus.contains('PAID')) {
      orderStatus = OrderStatus.completed;
    } else if (rawStatus.contains('CANCEL')) {
      orderStatus = OrderStatus.cancelled;
    } else if (rawStatus.contains('HOLD')) {
      orderStatus = OrderStatus.hold;
    }

    final rawPayment = (json['payment_status'] ?? 'PENDING').toString().toUpperCase();
    final rawPaidAmt = double.tryParse((json['paid_amount'] ?? '0').toString()) ?? 0.0;
    final rawGrandAmt = double.tryParse((json['grand_total'] ?? json['total'] ?? '0').toString()) ?? 0.0;
    PaymentStatus paymentStatus = PaymentStatus.pending;
    if (rawPayment.contains('PAID') ||
        rawStatus.contains('SETTLED') ||
        rawStatus.contains('COMPLET') ||
        (rawPaidAmt > 0 && rawPaidAmt >= rawGrandAmt)) {
      paymentStatus = PaymentStatus.paid;
    } else if (rawPayment.contains('REFUND')) {
      paymentStatus = PaymentStatus.refunded;
    }

    final rawItems = json['items'] ?? json['lines'] ?? json['order_lines'] ?? [];
    final List<PosCartItem> items = [];
    if (rawItems is List) {
      for (final it in rawItems) {
        final rawQty = it['quantity'] ?? it['qty'] ?? 1;
        final qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
        final rawPrice = it['unit_price'] ?? it['price'] ?? it['rate'] ?? 0.0;
        final price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
        final itemName = it['name'] ?? it['item_name'] ?? it['menu_item_name'] ?? 'Item';
        final itemId = it['menu_item_id'] ?? it['item_id'] ?? it['id'] ?? '';
        final itemNotes = it['notes']?.toString();

        items.add(
          PosCartItem(
            item: PosMenuItem(
              id: itemId.toString(),
              name: itemName.toString(),
              categoryId: it['category_id']?.toString() ?? 'all',
              price: price,
            ),
            quantity: qty,
            notes: itemNotes,
          ),
        );
      }
    }

    final rawSubtotal = json['subtotal'] ?? json['total_amount'] ?? json['sub_total'] ?? 0.0;
    final rawDiscount = json['discount_amount'] ?? json['discount'] ?? 0.0;
    final rawGst = json['tax_amount'] ?? json['gst_amount'] ?? json['tax'] ?? 0.0;
    final rawGrand = json['grand_total'] ?? json['total'] ?? json['settled_amount'] ?? 0.0;

    final createdAtStr = json['created_at'] ?? json['order_time'] ?? json['date'];
    DateTime createdAt = DateTime.now();
    if (createdAtStr != null) {
      try {
        String s = createdAtStr.toString().trim();
        if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
          s = '${s}Z';
        }
        createdAt = DateTime.parse(s).toLocal();
      } catch (_) {}
    }

    String resolvedPayment = '';
    if (json['tenders'] is List && (json['tenders'] as List).isNotEmpty) {
      final firstTender = (json['tenders'] as List).first;
      resolvedPayment =
          (firstTender['method'] ?? firstTender['payment_method'] ?? firstTender['mode'] ?? '').toString();
    }
    if (resolvedPayment.isEmpty && json['payments'] is List && (json['payments'] as List).isNotEmpty) {
      final firstPay = (json['payments'] as List).first;
      resolvedPayment =
          (firstPay['payment_mode'] ?? firstPay['method'] ?? firstPay['payment_method'] ?? '').toString();
    }
    if (resolvedPayment.isEmpty && json['settlements'] is List && (json['settlements'] as List).isNotEmpty) {
      final firstSet = (json['settlements'] as List).first;
      resolvedPayment = (firstSet['method'] ?? firstSet['payment_mode'] ?? '').toString();
    }
    if (resolvedPayment.isEmpty && json['payment_mode'] != null && json['payment_mode'].toString().isNotEmpty) {
      resolvedPayment = json['payment_mode'].toString();
    }
    if (resolvedPayment.isEmpty && json['payment_method'] != null && json['payment_method'].toString().isNotEmpty) {
      resolvedPayment = json['payment_method'].toString();
    }
    if (resolvedPayment.isEmpty &&
        json['settlement_mode'] != null &&
        json['settlement_mode'].toString().isNotEmpty) {
      resolvedPayment = json['settlement_mode'].toString();
    }
    if (resolvedPayment.isEmpty && json['tender_method'] != null && json['tender_method'].toString().isNotEmpty) {
      resolvedPayment = json['tender_method'].toString();
    }
    if (resolvedPayment.isEmpty) {
      resolvedPayment = 'CASH';
    }

    return RestaurantOrder(
      id: rawId.toString(),
      orderNumber: rawOrderNum.toString(),
      orderType: orderType,
      status: orderStatus,
      paymentStatus: paymentStatus,
      paymentMethod: resolvedPayment,
      tableId: json['table_id']?.toString(),
      tableLabel: json['table_label']?.toString() ??
          json['table_number']?.toString() ??
          json['table_name']?.toString() ??
          json['table_id']?.toString(),
      floor: json['floor']?.toString(),
      customerName: json['customer_name']?.toString() ?? 'Walk-in Guest',
      customerPhone: json['customer_phone']?.toString() ?? '',
      items: items,
      subtotal:
          (rawSubtotal is num) ? rawSubtotal.toDouble() : (double.tryParse(rawSubtotal.toString()) ?? 0.0),
      discount:
          (rawDiscount is num) ? rawDiscount.toDouble() : (double.tryParse(rawDiscount.toString()) ?? 0.0),
      gstAmount: (rawGst is num) ? rawGst.toDouble() : (double.tryParse(rawGst.toString()) ?? 0.0),
      grandTotal: (rawGrand is num) ? rawGrand.toDouble() : (double.tryParse(rawGrand.toString()) ?? 0.0),
      createdAt: createdAt,
      notes: json['notes']?.toString(),
      version: (json['version'] is num)
          ? (json['version'] as num).toInt()
          : (int.tryParse(json['version']?.toString() ?? '1') ?? 1),
    );
  }
}

