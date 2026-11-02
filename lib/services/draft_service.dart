import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftBill {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAge;
  final String doctorName;
  final String format;
  final List<Map<String, dynamic>> items;
  final double discountValue;
  final bool isDiscountPercentage;
  final DateTime createdAt;

  DraftBill({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAge,
    required this.doctorName,
    required this.format,
    required this.items,
    required this.discountValue,
    required this.isDiscountPercentage,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAge': customerAge,
      'doctorName': doctorName,
      'format': format,
      'items': items,
      'discountValue': discountValue,
      'isDiscountPercentage': isDiscountPercentage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DraftBill.fromJson(Map<String, dynamic> json) {
    return DraftBill(
      id: json['id'],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAge: json['customerAge'] ?? '',
      doctorName: json['doctorName'] ?? '',
      format: json['format'] ?? 'A4',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      isDiscountPercentage: json['isDiscountPercentage'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class DraftService {
  static const String _draftsKey = 'saved_drafts';

  static Future<void> saveDraft(DraftBill draft) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> draftsJson = prefs.getStringList(_draftsKey) ?? [];

    // Check if draft already exists and update, else add new
    int index = draftsJson.indexWhere((d) {
      final map = jsonDecode(d);
      return map['id'] == draft.id;
    });

    if (index != -1) {
      draftsJson[index] = jsonEncode(draft.toJson());
    } else {
      draftsJson.add(jsonEncode(draft.toJson()));
    }

    await prefs.setStringList(_draftsKey, draftsJson);
  }

  static Future<List<DraftBill>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> draftsJson = prefs.getStringList(_draftsKey) ?? [];

    return draftsJson.map((d) => DraftBill.fromJson(jsonDecode(d))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  static Future<void> deleteDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> draftsJson = prefs.getStringList(_draftsKey) ?? [];

    draftsJson.removeWhere((d) {
      final map = jsonDecode(d);
      return map['id'] == id;
    });

    await prefs.setStringList(_draftsKey, draftsJson);
  }
}
