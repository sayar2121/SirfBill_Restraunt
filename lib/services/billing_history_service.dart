import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter_models.dart';
export '../models/counter_models.dart';

class BillingHistoryService {
  static const String _key = 'billing_history';

  // Notifier to let the UI know when history is updated
  static final ValueNotifier<int> historyUpdated = ValueNotifier(0);

  static Future<void> saveBill(SavedBill bill) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = prefs.getStringList(_key) ?? [];

    currentHistory.add(jsonEncode(bill.toJson()));
    await prefs.setStringList(_key, currentHistory);

    // Notify listeners that history changed
    historyUpdated.value++;
  }

  static Future<List<SavedBill>> getBillingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = prefs.getStringList(_key) ?? [];

    final bills = currentHistory.map((draftStr) {
      final Map<String, dynamic> json = jsonDecode(draftStr);
      return SavedBill.fromJson(json);
    }).toList();

    // Sort by latest first
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
