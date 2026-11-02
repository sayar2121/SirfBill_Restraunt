import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/distributor_service.dart';
import '../services/purchase_service.dart';

final distributorServiceProvider = Provider((ref) => DistributorService());
final purchaseServiceProvider = Provider((ref) => PurchaseService());

// A provider to fetch and cache the list of distributors
final distributorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(distributorServiceProvider);
  return service.getDistributors();
});

// A provider family to fetch analytics for a specific distributor ID
final distributorAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final service = ref.read(distributorServiceProvider);
  return service.getDistributorAnalytics(id);
});

// A provider to fetch all purchase bills
final purchaseBillsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(purchaseServiceProvider);
  return service.getPurchaseBills();
});
