import 'dart:typed_data';
import '../models/restaurant_pos_models.dart';
import 'restaurant/restaurant_menu_service.dart';
import 'restaurant/restaurant_table_service.dart';
import 'restaurant/restaurant_order_service.dart';
import 'restaurant/restaurant_billing_service.dart';

// Re-export modular services for backwards compatibility and direct imports
export 'restaurant/restaurant_menu_service.dart';
export 'restaurant/restaurant_table_service.dart';
export 'restaurant/restaurant_order_service.dart';
export 'restaurant/restaurant_billing_service.dart';

/// Facade service maintaining 100% backwards compatibility with all existing callers
/// while delegating clean separation of concerns to specialized modular sub-services:
/// - [RestaurantMenuService]: Dishes, categories, images, and menu template uploads
/// - [RestaurantTableService]: Table layout, capacity, floors, and occupancy lifecycle
/// - [RestaurantOrderService]: KOT dispatch, order items, status transitions, and live orders
/// - [RestaurantBillingService]: Bill settlement, QR payment generation, and thermal printing
class RestaurantPosService {
  // ── Image Resolution ────────────────────────────────────────────────────────
  static String? resolveImageUrl(dynamic rawUrl) =>
      RestaurantMenuService.resolveImageUrl(rawUrl);

  // ── Menu Management ────────────────────────────────────────────────────────
  static Future<List<PosMenuItem>> fetchMenuItems({String? outletId, bool availableOnly = false}) =>
      RestaurantMenuService.fetchMenuItems(outletId: outletId, availableOnly: availableOnly);

  static Future<PosMenuItem?> createMenuItem({
    required String name,
    String? shortCode,
    required String categoryId,
    required double price,
    String? description,
    String? badge,
    String? imageUrl,
    bool isVeg = true,
    String? outletId,
  }) =>
      RestaurantMenuService.createMenuItem(
        name: name,
        shortCode: shortCode,
        categoryId: categoryId,
        price: price,
        description: description,
        badge: badge,
        imageUrl: imageUrl,
        isVeg: isVeg,
        outletId: outletId,
      );

  static Future<bool> updateMenuItem(PosMenuItem item) =>
      RestaurantMenuService.updateMenuItem(item);

  static Future<bool> toggleMenuItemAvailability(String itemId, bool isAvailable) =>
      RestaurantMenuService.toggleMenuItemAvailability(itemId, isAvailable);

  static Future<bool> deleteMenuItem(String itemId) =>
      RestaurantMenuService.deleteMenuItem(itemId);

  static Future<List<MenuCategory>> fetchCategories({String? outletId}) =>
      RestaurantMenuService.fetchCategories(outletId: outletId);

  static Future<MenuCategory?> createCategory({
    required String name,
    required String iconEmoji,
    String? outletId,
  }) =>
      RestaurantMenuService.createCategory(name: name, iconEmoji: iconEmoji, outletId: outletId);

  static Future<bool> updateCategory({
    required String id,
    required String name,
    required String iconEmoji,
  }) =>
      RestaurantMenuService.updateCategory(id: id, name: name, iconEmoji: iconEmoji);

  static Future<bool> deleteCategory(String categoryId) =>
      RestaurantMenuService.deleteCategory(categoryId);

  static Future<Map<String, dynamic>> bulkUploadMenu({
    required String filename,
    List<int>? bytes,
    String? path,
    String? outletId,
  }) =>
      RestaurantMenuService.bulkUploadMenu(
        filename: filename,
        bytes: bytes,
        path: path,
        outletId: outletId,
      );

  static Future<List<int>> downloadSampleMenuTemplate({
    String? outletId,
    String format = 'xlsx',
  }) =>
      RestaurantMenuService.downloadSampleMenuTemplate(outletId: outletId, format: format);

  // ── Table Management & Occupancy ───────────────────────────────────────────
  static Future<List<DiningTable>> fetchTables({String? outletId}) =>
      RestaurantTableService.fetchTables(outletId: outletId);

  static Future<DiningTable?> createTable({
    required String label,
    required int capacity,
    required String floor,
    String? outletId,
  }) =>
      RestaurantTableService.createTable(
        label: label,
        capacity: capacity,
        floor: floor,
        outletId: outletId,
      );

  static Future<bool> updateTable({
    required String tableId,
    required String label,
    required int capacity,
    required String floor,
  }) =>
      RestaurantTableService.updateTable(
        tableId: tableId,
        label: label,
        capacity: capacity,
        floor: floor,
      );

  static Future<bool> updateTableStatus(String tableId, TableStatus status) =>
      RestaurantTableService.updateTableStatus(tableId, status);

  static Future<bool> deleteTable(String tableId) =>
      RestaurantTableService.deleteTable(tableId);

  // ── Order Dispatch & KOT ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> sendToKitchen({
    required String orderType,
    String? tableId,
    required List<PosCartItem> cartItems,
    String? customerName,
    String? customerPhone,
    String? orderNotes,
    String? outletId,
    String? paymentMethod,
  }) =>
      RestaurantOrderService.sendToKitchen(
        orderType: orderType,
        tableId: tableId,
        cartItems: cartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        orderNotes: orderNotes,
        outletId: outletId,
        paymentMethod: paymentMethod,
      );

  static Future<Map<String, dynamic>?> fetchOrderById(String orderId) =>
      RestaurantOrderService.fetchOrderById(orderId);

  static Future<Map<String, dynamic>?> appendItemsToOrder({
    required String orderId,
    required List<PosCartItem> newItems,
    int? expectedVersion = 1,
  }) =>
      RestaurantOrderService.appendItemsToOrder(
        orderId: orderId,
        newItems: newItems,
        expectedVersion: expectedVersion,
      );

  static Future<Map<String, dynamic>?> fetchActiveOrderByTable(String tableId) =>
      RestaurantOrderService.fetchActiveOrderByTable(tableId);

  static Future<List<RestaurantOrder>> fetchOrders({
    String? outletId,
    String? statusFilter,
    String? customerPhone,
    int limit = 500,
  }) =>
      RestaurantOrderService.fetchOrders(
        outletId: outletId,
        statusFilter: statusFilter,
        customerPhone: customerPhone,
        limit: limit,
      );

  static Future<bool> transitionOrderStatus({
    required String orderId,
    required String targetStatus,
  }) =>
      RestaurantOrderService.transitionOrderStatus(
        orderId: orderId,
        targetStatus: targetStatus,
      );

  // ── Settlement & Thermal Billing ───────────────────────────────────────────
  static Future<bool> settleOrder({
    required String orderId,
    required double grandTotal,
    required String paymentMode,
    double discountAmount = 0.0,
    List<Map<String, dynamic>>? splitTenders,
  }) =>
      RestaurantBillingService.settleOrder(
        orderId: orderId,
        grandTotal: grandTotal,
        paymentMode: paymentMode,
        discountAmount: discountAmount,
        splitTenders: splitTenders,
      );

  static Future<String?> generateUpiQr({
    required String orderId,
    required double amount,
  }) =>
      RestaurantBillingService.generateUpiQr(orderId: orderId, amount: amount);

  static Future<String?> fetchThermalBillHtml(String orderId) =>
      RestaurantBillingService.fetchThermalBillHtml(orderId);

  static Future<Map<String, dynamic>?> printThermalBill(String orderId) =>
      RestaurantBillingService.printThermalBill(orderId);

  static Future<Uint8List?> fetchBackendBillPdfBytes(String orderId, {String? billPdfUrl}) =>
      RestaurantBillingService.fetchBackendBillPdfBytes(orderId, billPdfUrl: billPdfUrl);
}
