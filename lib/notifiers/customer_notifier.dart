import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/customer_service.dart';
import '../services/billing_service.dart';
import '../services/restaurant_pos_service.dart';

class CustomerNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<List<Map<String, dynamic>>> _fetchCustomers() async {
    final realCustomers = await CustomerService.getCustomers();

    List<dynamic> historyList = [];
    try {
      final response = await BillingService.getPosHistory();
      historyList = List<dynamic>.from(response['history'] as List? ?? []);
    } catch (e) {
      // Ignore if billing service fails
    }

    try {
      final restaurantOrders = await RestaurantPosService.fetchOrders();
      for (final ro in restaurantOrders) {
        final itemsDetail = ro.items.map((it) => {
          'name': it.item.name,
          'item_name': it.item.name,
          'qty': it.quantity,
          'quantity': it.quantity,
          'price': it.item.price,
          'unit_price': it.item.price,
          'notes': it.notes,
        }).toList();

        historyList.add({
          'id': ro.id,
          'bill_no': ro.orderNumber,
          'customer_name': ro.customerName,
          'customer_phone': ro.customerPhone,
          'amount': ro.grandTotal,
          'total': ro.grandTotal,
          'date': ro.createdAt.toIso8601String(),
          'payment_mode': ro.paymentMethod,
          'status': ro.status.name,
          'order_type': ro.orderType.name,
          'table_label': ro.tableLabel,
          'items_detail': itemsDetail,
          'lines': itemsDetail,
        });
      }
    } catch (e) {
      // Ignore if restaurant orders fetch fails
    }

    final List<Map<String, dynamic>> mappedRealCustomers = realCustomers
        .map<Map<String, dynamic>>((c) {
          final names = c.name.split(' ');
          final initials = names.length > 1
              ? '${names[0][0]}${names[1][0]}'.toUpperCase()
              : c.name.isNotEmpty
              ? c.name[0].toUpperCase()
              : 'C';

          final custHistory = historyList.where((h) {
            final hPhone = h['customer_phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
            final cPhone = c.phone.replaceAll(RegExp(r'\D'), '');
            final hName = (h['customer_name']?.toString().trim() ?? '').toLowerCase();
            final cName = c.name.trim().toLowerCase();

            // If phone numbers are present on both, match by phone
            if (cPhone.isNotEmpty && hPhone.isNotEmpty) {
              final phoneMatches = (hPhone == cPhone || hPhone.endsWith(cPhone) || cPhone.endsWith(hPhone));
              if (phoneMatches) {
                // If an order name is present, check that it's compatible
                if (hName.isNotEmpty && cName.isNotEmpty && hName != 'walk-in guest' && hName != 'null') {
                  final nameCompatible = hName == cName ||
                      hName.contains(cName) ||
                      cName.contains(hName) ||
                      hName.split(' ').first == cName.split(' ').first;
                  return nameCompatible;
                }
                return true;
              }
            }

            // Fallback: match by full name if phone is missing
            if (cName.isNotEmpty && hName.isNotEmpty && hName != 'walk-in guest' && hName != 'null') {
              return hName == cName || hName.contains(cName) || cName.contains(hName);
            }
            return false;
          }).toList();

          double totalPurchases = 0.0;
          DateTime? lastPurchaseDate;

          for (var h in custHistory) {
            totalPurchases += (h['amount'] as num?)?.toDouble() ?? 0.0;
            String dateStr = h['date'].toString();
            dateStr = dateStr.replaceAll(' ', 'T');
            if (!dateStr.endsWith('Z')) {
              dateStr += 'Z';
            }
            final dt = DateTime.tryParse(dateStr)?.toLocal();
            if (dt != null) {
              if (lastPurchaseDate == null || dt.isAfter(lastPurchaseDate)) {
                lastPurchaseDate = dt;
              }
            }
          }

          return {
            'full_id': c.id,
            'id': c.id.substring(c.id.length > 8 ? c.id.length - 8 : 0),
            'name': c.name,
            'initials': initials,
            'phone': c.phone,
            'email': c.email.isNotEmpty ? c.email : 'N/A',
            'city': c.location.isNotEmpty ? c.location : 'Local',
            'totalPurchases': totalPurchases,
            'bills': custHistory.length,
            'lastPurchase': lastPurchaseDate != null
                ? DateFormat('dd MMM yyyy').format(lastPurchaseDate)
                : 'N/A',
            'status': c.isActive ? 'Active' : 'Inactive',
            'memberSince': c.createdAt != null
                ? DateFormat('MMM yyyy').format(DateTime.parse(c.createdAt!))
                : 'Unknown',
            'raw_created_at': c.createdAt,
            'history': custHistory,
          };
        })
        .toList();

    return mappedRealCustomers;
  }
}
