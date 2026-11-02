import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<Map<String, dynamic>> currentBill;
  final double discountValue;
  final bool isDiscountPercentage;
  final double receivedAmount;
  final String paymentMethod;
  final String? savedCustomerId;
  final String customerName;
  final String customerPhone;
  final String customerLocation;
  final String searchQuery;
  final int selectedCategoryIndex;
  final String selectedFormat;
  final bool isGstEnabled;
  final String gstNumber;

  BillingState({
    this.currentBill = const [],
    this.isGstEnabled = false,
    this.gstNumber = '',
    this.discountValue = 0.0,
    this.isDiscountPercentage = true,
    this.receivedAmount = 0.0,
    this.paymentMethod = 'CASH',
    this.savedCustomerId,
    this.customerName = '',
    this.customerPhone = '',
    this.customerLocation = '',
    this.searchQuery = '',
    this.selectedCategoryIndex = 0,
    this.selectedFormat = 'A4',
  });

  BillingState copyWith({
    List<Map<String, dynamic>>? currentBill,
    double? discountValue,
    bool? isDiscountPercentage,
    double? receivedAmount,
    String? paymentMethod,
    String? savedCustomerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? searchQuery,
    int? selectedCategoryIndex,
    String? selectedFormat,
    bool? isGstEnabled,
    String? gstNumber,
  }) {
    return BillingState(
      currentBill: currentBill ?? this.currentBill,
      discountValue: discountValue ?? this.discountValue,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      savedCustomerId: savedCustomerId ?? this.savedCustomerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      isGstEnabled: isGstEnabled ?? this.isGstEnabled,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }

  double get subtotal => currentBill.fold(
    0.0,
    (sum, item) => sum + ((item['total'] ?? 0.0) as num).toDouble(),
  );
  double get discountAmount =>
      isDiscountPercentage ? (subtotal * (discountValue / 100)) : discountValue;
  double get totalAfterDiscount => subtotal - discountAmount;

  double get itemGstAmount {
    return currentBill.fold(0.0, (sum, item) {
      double cgst = (item['cgst'] as num?)?.toDouble() ?? 0.0;
      double sgst = (item['sgst'] as num?)?.toDouble() ?? 0.0;
      double total = (item['total'] as num?)?.toDouble() ?? 0.0;
      // Subtract proportional item discount from the item total
      double proportionalDiscount = subtotal > 0
          ? (total / subtotal) * discountAmount
          : 0.0;
      double itemTotalAfterDiscount = total - proportionalDiscount;
      return sum + (itemTotalAfterDiscount * (cgst + sgst) / 100);
    });
  }

  double get gstAmount => isGstEnabled ? itemGstAmount : 0.0;
  double get grandTotal => totalAfterDiscount + gstAmount;
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() {
    return BillingState();
  }

  bool addItem(Map<String, dynamic> item) {
    // Check if it already exists by name
    final index = state.currentBill.indexWhere(
      (element) => element['name'] == item['name'],
    );
    if (index != -1) {
      return false; // Item already exists, don't add duplicate
    } else {
      state = state.copyWith(currentBill: [...state.currentBill, item]);
      return true; // Item added successfully
    }
  }

  void updateItemQuantity(int index, int newQty) {
    if (newQty < 1) return;
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    double price = (updatedBill[index]['price'] as num).toDouble();
    double discount = (updatedBill[index]['discount'] as num?)?.toDouble() ?? 0.0;
    double itemTotal = newQty * price;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));
    
    updatedBill[index] = {
      ...updatedBill[index],
      'qty': newQty,
      'total': itemTotalAfterDiscount,
    };
    state = state.copyWith(currentBill: updatedBill);
  }



  void updateItemDiscount(int index, double discount) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    double price = (updatedBill[index]['price'] as num).toDouble();
    int qty = (updatedBill[index]['qty'] as num).toInt();
    
    double itemTotal = qty * price;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));
    
    updatedBill[index] = {
      ...updatedBill[index],
      'discount': discount,
      'total': itemTotalAfterDiscount,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void updateItemPrice(int index, double newPrice) {
    if (newPrice < 0) return;
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    int qty = (updatedBill[index]['qty'] as num).toInt();
    double discount = (updatedBill[index]['discount'] as num?)?.toDouble() ?? 0.0;
    
    double itemTotal = qty * newPrice;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));
    
    updatedBill[index] = {
      ...updatedBill[index],
      'price': newPrice,
      'unit_price': newPrice,
      'total': itemTotalAfterDiscount,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void updateItemGst(int index, double totalGst) {
    if (totalGst < 0) return;
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    final halfGst = totalGst / 2.0;
    
    updatedBill[index] = {
      ...updatedBill[index],
      'gst': totalGst,
      'cgst': halfGst,
      'sgst': halfGst,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void removeItem(int index) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    updatedBill.removeAt(index);
    state = state.copyWith(currentBill: updatedBill);
  }

  void setBill(List<Map<String, dynamic>> items) {
    state = state.copyWith(currentBill: items);
  }

  void updateDiscount(double value, bool isPercentage) {
    state = state.copyWith(
      discountValue: value,
      isDiscountPercentage: isPercentage,
    );
  }

  void updateReceivedAmount(double amount) {
    state = state.copyWith(receivedAmount: amount);
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }



  void updateCustomerInfo(
    String name,
    String phone,
    String location, {
    String? id,
  }) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      customerLocation: location,
      savedCustomerId: id ?? state.savedCustomerId,
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateCategory(int index) {
    state = state.copyWith(selectedCategoryIndex: index);
  }

  void updateSelectedFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  void clearBill() {
    state = BillingState();
  }

  void toggleGst(bool? value) {
    if (value != null) {
      state = state.copyWith(isGstEnabled: value);
    }
  }

  void updateGstNumber(String number) {
    state = state.copyWith(gstNumber: number);
  }
}
