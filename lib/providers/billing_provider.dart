import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/billing_notifier.dart';

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(() {
  return BillingNotifier();
});
