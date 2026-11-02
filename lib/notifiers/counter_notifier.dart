import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shop_service.dart';

class ShopNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final shops = await ShopService.getShops();
    return shops.map((s) => s.toMap()).toList();
  }

  Future<void> loadShops() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final shops = await ShopService.getShops();
      return shops.map((s) => s.toMap()).toList();
    });
  }

  Future<void> addShop({
    required String name,
    required String code,
    required String address,
    required String city,
    required String contactNumber,
    required String status,
    required bool isPrimary,
  }) async {
    await ShopService.createShop(
      name: name,
      code: code,
      address: address,
      city: city,
      contactNumber: contactNumber,
      status: status,
      isPrimary: isPrimary,
    );
    await loadShops();
  }

  Future<void> updateShop({
    required String id,
    required String name,
    required String code,
    required String address,
    required String city,
    required String contactNumber,
    required String status,
    required bool isPrimary,
  }) async {
    await ShopService.updateShop(
      id: id,
      name: name,
      code: code,
      address: address,
      city: city,
      contactNumber: contactNumber,
      status: status,
      isPrimary: isPrimary,
    );
    await loadShops();
  }

  Future<void> deleteShop(String id) async {
    await ShopService.deleteShop(id);
    await loadShops();
  }
}
