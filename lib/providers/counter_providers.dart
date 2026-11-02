import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/counter_notifier.dart';
import '../notifiers/customer_notifier.dart';
import '../notifiers/inventory_notifier.dart';
import '../services/inventory_service.dart';
import '../notifiers/doctor_notifier.dart';
import '../services/doctor_service.dart';
import '../notifiers/accounts_notifier.dart';
import '../notifiers/history_notifier.dart';
import '../notifiers/settings_notifier.dart';
import '../notifiers/rack_notifier.dart';
import '../notifiers/category_notifier.dart';
import '../services/rack_service.dart';
import '../services/category_service.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, Map<String, dynamic>>(() {
      return SettingsNotifier();
    });

final historyProvider = AsyncNotifierProvider<HistoryNotifier, HistoryState>(
  () {
    return HistoryNotifier();
  },
);

final shopProvider =
    AsyncNotifierProvider<ShopNotifier, List<Map<String, dynamic>>>(() {
      return ShopNotifier();
    });

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Map<String, dynamic>>>(() {
      return CustomerNotifier();
    });

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
      return InventoryNotifier();
    });

class BillingInventoryNotifier extends InventoryNotifier {}

final billingInventoryProvider =
    AsyncNotifierProvider<BillingInventoryNotifier, List<InventoryItem>>(() {
      return BillingInventoryNotifier();
    });

class PurchaseInventoryNotifier extends InventoryNotifier {}

final purchaseInventoryProvider =
    AsyncNotifierProvider<PurchaseInventoryNotifier, List<InventoryItem>>(() {
      return PurchaseInventoryNotifier();
    });

final doctorProvider = AsyncNotifierProvider<DoctorNotifier, List<Doctor>>(() {
  return DoctorNotifier();
});

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, AccountsState>(
  () {
    return AccountsNotifier();
  },
);

final rackProvider = AsyncNotifierProvider<RackNotifier, List<Rack>>(() {
  return RackNotifier();
});

final categoryProvider = AsyncNotifierProvider<CategoryNotifier, List<Category>>(() {
  return CategoryNotifier();
});

class SelectedShopIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void updateShopId(String? shopId) {
    state = shopId;
  }
}

final selectedShopIdProvider = NotifierProvider<SelectedShopIdNotifier, String?>(SelectedShopIdNotifier.new);
