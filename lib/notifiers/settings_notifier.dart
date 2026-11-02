import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shop_settings_service.dart';

class SettingsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return ShopSettingsService.getSettings();
  }

  Future<void> reloadSettings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ShopSettingsService.getSettings());
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await ShopSettingsService.updateSettings(data);
    await reloadSettings();
  }
}
