import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/restaurant_pos_models.dart';
import '../../../../providers/restaurant_pos_provider.dart';
import '../../../../services/shop_service.dart';
import 'customer_dialog.dart';
import 'discount_dialog.dart';
import 'pos_order_payment_dialog.dart';
import 'pos_settlement_service.dart';

/// Helper utility for presenting modular dialogs in the Restaurant POS Billing Screen.
class PosBillingDialogs {
  PosBillingDialogs._();

  /// Opens the modal dialog to create a new customer and link them to the active cart.
  static void showAddCustomerDialog(
    BuildContext context,
    RestaurantPosNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerDialog(notifier: notifier),
    );
  }

  /// Opens a quick preset discount selector dialog.
  static void showDiscountDialog(
    BuildContext context,
    RestaurantPosNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => DiscountDialog(notifier: notifier),
    );
  }

  /// Opens the interactive payment mode selector dialog.
  /// On cashier confirmation, runs [PosSettlementService.completeSettlement] using the
  /// CALLER's [context] and [ref] — both guaranteed live for the billing screen's lifetime.
  static void showPaymentDialog({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState state,
    required Map<String, dynamic>? shopSettings,
    required Shop? activeOutlet,
    required List<DiningTable> tables,
    required VoidCallback onReloadMenu,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PosOrderPaymentDialog(
        state: state,
        shopSettings: shopSettings,
        activeOutlet: activeOutlet,
        tables: tables,
        onConfirm: (selectedMode) {
          // Settlement runs with the caller's context + ref, not the dialog's.
          // This ensures we never use a disposed widget's context or ref.
          PosSettlementService.completeSettlement(
            context: context,
            ref: ref,
            state: state,
            selectedMode: selectedMode,
            shopSettings: shopSettings,
            activeOutlet: activeOutlet,
            tables: tables,
            onReloadMenu: onReloadMenu,
          );
        },
      ),
    );
  }
}
