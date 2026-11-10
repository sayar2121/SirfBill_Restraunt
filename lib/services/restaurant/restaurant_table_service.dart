import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../models/restaurant_pos_models.dart';

/// Service handling Dining Tables, layout, occupancy, and status reconciliation
class RestaurantTableService {
  static final Dio _dio = ApiClient().dio;

  /// 3. Fetch Live Dining Tables & Occupancy
  static Future<List<DiningTable>> fetchTables({String? outletId}) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/tables',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['tables'] ?? []);

        // Fetch live orders to reconcile table occupancy accurately:
        // A table remains OCCUPIED if there is any active or served Dine-In order
        // that has not yet been paid/settled by the cashier.
        final Map<String, dynamic> tableUnsettledOrderMap = {};
        try {
          final ordersRes = await _dio.get(
            '/api/restaurant/orders',
            queryParameters: {
              if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
              'limit': 50,
            },
          );
          if (ordersRes.statusCode == 200 && ordersRes.data != null) {
            final List ordersList = ordersRes.data is List
                ? ordersRes.data
                : (ordersRes.data['orders'] ?? ordersRes.data['items'] ?? []);
            for (final o in ordersList) {
              final oType = (o['order_type'] ?? 'DINE_IN').toString().toUpperCase();
              if (!oType.contains('DINE')) continue;

              final oStatus = (o['status'] ?? '').toString().toUpperCase();
              if (oStatus.contains('CANCEL') ||
                  oStatus.contains('VOID') ||
                  oStatus.contains('SETTLE') ||
                  oStatus.contains('COMPLET')) {
                continue;
              }

              final paidAmt = double.tryParse((o['paid_amount'] ?? '0').toString()) ?? 0.0;
              final grandTotal = double.tryParse((o['grand_total'] ?? o['total'] ?? '0').toString()) ?? 0.0;
              final lines = o['lines'] as List? ?? [];
              // Ignore empty dummy orders or fully paid orders
              if (grandTotal <= 0 || lines.isEmpty || paidAmt >= grandTotal) {
                continue;
              }

              final tid = o['table_id']?.toString();
              if (tid != null && tid.isNotEmpty && !tableUnsettledOrderMap.containsKey(tid)) {
                tableUnsettledOrderMap[tid] = o;
              }
            }
          }
        } catch (_) {}

        return list.map((json) {
          final tableId = json['id']?.toString() ?? '';
          final tableLabel = (json['table_number'] ?? json['label'] ?? json['name'] ?? '').toString();

          final rawStatus = (json['status'] ?? '').toString().toLowerCase();
          TableStatus status = TableStatus.available;
          if (rawStatus == 'occupied') {
            status = TableStatus.occupied;
          } else if (rawStatus == 'reserved') {
            status = TableStatus.reserved;
          } else if (rawStatus == 'vacant' || rawStatus == 'available') {
            status = TableStatus.available;
          }

          // Reconcile: If this table has an active/served unpaid order, keep it OCCUPIED
          final unsettledOrder = tableUnsettledOrderMap[tableId];
          if (unsettledOrder != null && status != TableStatus.occupied) {
            status = TableStatus.occupied;
          }

          final rawBill = unsettledOrder != null
              ? (unsettledOrder['grand_total'] ?? unsettledOrder['total'] ?? 0.0)
              : (json['active_order_grand_total'] ?? json['current_bill_amount'] ?? 0.0);
          final currentBill = (rawBill is num) ? rawBill.toDouble() : (double.tryParse(rawBill.toString()) ?? 0.0);
          final activeOrderCount = unsettledOrder != null
              ? 1
              : (json['active_order_count'] ?? (status == TableStatus.occupied ? 1 : 0));

          String? durationStr;
          DateTime? orderStartTime;
          final orderCreatedAtStr = unsettledOrder != null
              ? (unsettledOrder['created_at'] ?? unsettledOrder['order_time'])
              : (json['active_order_created_at'] ?? json['occupied_since']);
          if (status == TableStatus.occupied && orderCreatedAtStr != null) {
            try {
              final rawStr = orderCreatedAtStr.toString().trim();
              final isoUtc = (rawStr.endsWith('Z') || rawStr.contains('+'))
                  ? rawStr
                  : '${rawStr}Z';
              orderStartTime = DateTime.parse(isoUtc).toLocal();
              final diff = DateTime.now().difference(orderStartTime);
              final hours = diff.inHours.toString().padLeft(2, '0');
              final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
              final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
              durationStr = '$hours:$mins:$secs';
            } catch (_) {
              orderStartTime = DateTime.now();
              durationStr = '00:00:01';
            }
          } else if (status == TableStatus.occupied) {
            orderStartTime = DateTime.now();
            durationStr = '00:00:01';
          }

          return DiningTable(
            id: tableId,
            label: tableLabel,
            capacity: json['capacity'] ?? 4,
            status: status,
            floor: json['floor'] ?? json['section'] ?? 'Floor 1',
            occupiedDuration: durationStr,
            occupiedSince: orderStartTime,
            currentBillAmount: currentBill,
            activeOrderCount: activeOrderCount is int ? activeOrderCount : int.tryParse(activeOrderCount.toString()) ?? (status == TableStatus.occupied ? 1 : 0),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dining tables: $e');
    }
    return [];
  }

  /// 3b. Create Dining Table on Backend
  static Future<DiningTable?> createTable({
    required String label,
    required int capacity,
    required String floor,
    String? outletId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/tables',
        data: {
          'table_number': label,
          'capacity': capacity,
          'floor': floor,
          'status': 'AVAILABLE',
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = res.data is Map ? res.data : {};
        return DiningTable(
          id: json['id']?.toString() ?? 'tbl_${DateTime.now().millisecondsSinceEpoch}',
          label: json['table_number'] ?? label,
          capacity: json['capacity'] ?? capacity,
          status: TableStatus.available,
          floor: json['floor'] ?? floor,
        );
      }
    } catch (e) {
      debugPrint('Error creating dining table on backend: $e');
    }
    return null;
  }

  /// 3c. Update Table Details on Backend (Label, Capacity, Floor)
  static Future<bool> updateTable({
    required String tableId,
    required String label,
    required int capacity,
    required String floor,
  }) async {
    try {
      final res = await _dio.put(
        '/api/restaurant/tables/$tableId',
        data: {
          'table_number': label,
          'capacity': capacity,
          'floor': floor,
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating table details on backend: $e');
      return false;
    }
  }

  /// 3d. Update Table Status on Backend
  static Future<bool> updateTableStatus(String tableId, TableStatus status) async {
    try {
      final statusStr = status == TableStatus.available
          ? 'AVAILABLE'
          : (status == TableStatus.occupied ? 'OCCUPIED' : 'RESERVED');
      final res = await _dio.patch(
        '/api/restaurant/tables/$tableId/status',
        data: {'status': statusStr, 'table_status': statusStr},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating table status on backend: $e');
      // If AVAILABLE failed, retry with VACANT for compatibility
      if (status == TableStatus.available) {
        try {
          final retryRes = await _dio.patch(
            '/api/restaurant/tables/$tableId/status',
            data: {'status': 'VACANT'},
          );
          return retryRes.statusCode == 200 || retryRes.statusCode == 204;
        } catch (_) {}
      }
      return false;
    }
  }

  /// 3e. Delete Table on Backend
  static Future<bool> deleteTable(String tableId) async {
    try {
      final res = await _dio.delete('/api/restaurant/tables/$tableId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting table on backend: $e');
      return false;
    }
  }
}

