import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/inventory_service.dart';
import '../utils/app_image_cache_manager.dart';

// Import all providers to reset
import '../providers/counter_providers.dart';
import '../providers/menu_management_provider.dart';
import '../providers/restaurant_pos_provider.dart';
import '../providers/restaurant_order_provider.dart';
import '../providers/restaurant_table_provider.dart';
import '../providers/kitchen_display_provider.dart';
import '../providers/restaurant_report_provider.dart';
import '../providers/distributor_provider.dart';
import '../providers/crm_providers.dart';

class AppSessionManager {
  /// Completely resets all in-memory static caches, disk preferences, and Riverpod providers.
  /// Call this on logout or account switch.
  static Future<void> resetSession({WidgetRef? ref, ProviderContainer? container}) async {
    // 1. Clear static memory cache in services
    await InventoryService.clearShopId();
    AppImageCacheManager.instance.clearMemoryCache();

    // 2. Clear authentication and session preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('role_login_name');
    await prefs.remove('selected_shop_id');
    await prefs.remove('assigned_outlet_id');
    await prefs.remove('assigned_outlet_name');

    // 3. Invalidate / Reset all Riverpod Providers if Ref or Container is supplied
    invalidateProviders(ref: ref, container: container);
  }

  /// Invalidates all Riverpod providers across the application to force fresh data fetching
  static void invalidateProviders({WidgetRef? ref, ProviderContainer? container}) {
    if (ref != null) {
      _invalidateProvidersWithRef(ref);
    } else if (container != null) {
      _invalidateProvidersWithContainer(container);
    }
  }

  static void _invalidateProvidersWithRef(WidgetRef ref) {
    // Core Restaurant & POS Providers
    ref.invalidate(restaurantPosProvider);
    ref.invalidate(menuManagementProvider);
    ref.invalidate(restaurantOrderProvider);
    ref.invalidate(restaurantTableProvider);
    ref.invalidate(kitchenDisplayProvider);
    ref.invalidate(restaurantReportProvider);

    // Counter, Shop, & Settings Providers
    ref.invalidate(settingsProvider);
    ref.invalidate(shopProvider);
    ref.invalidate(customerProvider);
    ref.invalidate(selectedShopIdProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(billingInventoryProvider);
    ref.invalidate(purchaseInventoryProvider);
    ref.invalidate(rackProvider);
    ref.invalidate(categoryProvider);

    // Distributor & CRM Providers
    ref.invalidate(distributorsProvider);
    ref.invalidate(purchaseBillsProvider);
    ref.invalidate(crmPatientsProvider);
    ref.invalidate(crmAppointmentsProvider);
    ref.invalidate(crmDoctorsProvider);
    ref.invalidate(crmOrdersProvider);
  }

  static void _invalidateProvidersWithContainer(ProviderContainer container) {
    container.invalidate(restaurantPosProvider);
    container.invalidate(menuManagementProvider);
    container.invalidate(restaurantOrderProvider);
    container.invalidate(restaurantTableProvider);
    container.invalidate(kitchenDisplayProvider);
    container.invalidate(restaurantReportProvider);

    container.invalidate(settingsProvider);
    container.invalidate(shopProvider);
    container.invalidate(customerProvider);
    container.invalidate(selectedShopIdProvider);
    container.invalidate(accountsProvider);
    container.invalidate(historyProvider);
    container.invalidate(inventoryProvider);
    container.invalidate(billingInventoryProvider);
    container.invalidate(purchaseInventoryProvider);
    container.invalidate(rackProvider);
    container.invalidate(categoryProvider);

    container.invalidate(distributorsProvider);
    container.invalidate(purchaseBillsProvider);
    container.invalidate(crmPatientsProvider);
    container.invalidate(crmAppointmentsProvider);
    container.invalidate(crmDoctorsProvider);
    container.invalidate(crmOrdersProvider);
  }
}
