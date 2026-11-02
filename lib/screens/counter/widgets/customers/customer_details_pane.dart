import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../themes/app_colors.dart';
import '../../../../services/export_service.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_settings_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/pdf_thermal_generator.dart';
import '../pos/pos_bill_receipt_modal.dart';
import 'customer_components.dart';
import 'customer_dialogs.dart';

class CustomerDetailsPane extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onClose;
  final VoidCallback onCustomerUpdated;

  const CustomerDetailsPane({
    super.key,
    required this.customer,
    required this.onClose,
    required this.onCustomerUpdated,
  });

  @override
  ConsumerState<CustomerDetailsPane> createState() => _CustomerDetailsPaneState();
}

class _CustomerDetailsPaneState extends ConsumerState<CustomerDetailsPane> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: 'Export Customer Data',
                      icon: const Icon(
                        Icons.download_outlined,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                      onSelected: (String result) {
                        _exportCustomerData(customer, result);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'All',
                          child: Text('All Data'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'This Year',
                          child: Text('This Year'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'This Month',
                          child: Text('This Month'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Today',
                          child: Text('Today'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => showEditCustomerDialog(
                        context,
                        customer,
                        widget.onCustomerUpdated,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: widget.onClose,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          // Profile Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomerAvatar(
                      initials: customer['initials'] ?? '',
                      radius: 24,
                      fontSize: 18,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            customer['id'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomerStatusChip(status: customer['status'] ?? 'Active'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildContactRow(context, Icons.phone, customer['phone'] ?? ''),
                const SizedBox(height: 12),
                _buildContactRow(context, Icons.email, customer['email'] ?? ''),
                const SizedBox(height: 12),
                _buildContactRow(context, Icons.location_on, customer['city'] ?? ''),
                const SizedBox(height: 12),
                _buildContactRow(
                  context,
                  Icons.calendar_today,
                  'Member since ${customer['memberSince'] ?? 'N/A'}',
                ),

                const SizedBox(height: 24),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 24),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(context, '${customer['bills'] ?? 0}', 'Total Bills'),
                    _buildMiniStat(
                      context,
                      '₹ ${((customer['totalPurchases'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                      'Total Purchase',
                    ),
                    _buildMiniStat(
                      context,
                      customer['lastPurchase'] ?? 'N/A',
                      'Last Purchase',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/counter/billing');
                        },
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('New Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Message sent to ${customer['phone']}',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                        label: const Text(
                          'Send Message',
                          style: TextStyle(color: AppColors.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryDark),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 0
                                ? AppColors.primaryDark
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Purchase History',
                          style: TextStyle(
                            color: _activeTab == 0
                                ? AppColors.primaryDark
                                : (isDark ? Colors.grey[400] : AppColors.textSecondary),
                            fontWeight: _activeTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 1
                                ? AppColors.primaryDark
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Notes',
                          style: TextStyle(
                            color: _activeTab == 1
                                ? AppColors.primaryDark
                                : (isDark ? Colors.grey[400] : AppColors.textSecondary),
                            fontWeight: _activeTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          _activeTab == 0
              ? _buildPurchaseHistory(context, customer)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No notes available for this customer.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory(BuildContext context, Map<String, dynamic> customer) {
    final history = (customer['history'] as List?) ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 500,
              maxWidth: constraints.maxWidth > 500
                  ? constraints.maxWidth
                  : 500,
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Bill No',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                if ((customer['bills'] ?? 0) > 0 && history.isNotEmpty)
                  ...history.map((h) {
                    String dateStrRaw = h['date'].toString();
                    if (!dateStrRaw.endsWith('Z')) {
                      dateStrRaw += 'Z';
                    }
                    final date = DateTime.tryParse(dateStrRaw)?.toLocal();
                    final dateStr = date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : h['date'].toString();
                    final amt = (h['amount'] as num?)?.toDouble() ?? 0.0;

                    return InkWell(
                      onTap: () => _openBillDialog(context, h, date),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                dateStr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                h['bill_no']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '₹ ${amt.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: isDark ? Colors.grey[500] : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No purchases found',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBillDialog(BuildContext context, dynamic h, DateTime? date) async {
    final orderId = h['id']?.toString() ?? '';
    final billNo = h['bill_no']?.toString() ?? '#ORD';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching thermal bill for $billNo...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // 1. Fetch real thermal bill PDF from backend
    Uint8List? thermalPdfBytes;
    if (orderId.isNotEmpty) {
      try {
        thermalPdfBytes = await RestaurantPosService.fetchBackendBillPdfBytes(orderId);
      } catch (e) {
        debugPrint('Error fetching backend thermal bill: $e');
      }
    }

    // 2. Fall back to local thermal generator if backend PDF could not be fetched
    if (thermalPdfBytes == null) {
      Map<String, dynamic>? shopSettings;
      try {
        shopSettings = await ShopSettingsService.getSettings();
      } catch (_) {}

      final authName = await AuthService.getUserName();
      final shopName = (shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
          ? shopSettings!['shop_name'].toString()
          : ((authName != null && authName.trim().isNotEmpty) ? authName : 'SirfBill Restaurant');

      final address = shopSettings?['address']?.toString() ??
          shopSettings?['shop_address']?.toString() ??
          'Restaurant Counter';
      final phone = shopSettings?['phone']?.toString() ??
          shopSettings?['mobile']?.toString() ??
          '';
      final shopGstNo = shopSettings?['gst_number']?.toString() ??
          shopSettings?['shop_gst_no']?.toString() ??
          shopSettings?['gstin']?.toString() ??
          '';
      final upiId = shopSettings?['upi_id']?.toString() ?? '';
      final cinNumber = shopSettings?['cin_number']?.toString() ??
          shopSettings?['drug_licence']?.toString() ??
          '';

      final rawLines = ((h['items_detail'] ?? h['lines'] ?? h['items']) as List?)
              ?.map((i) => Map<String, dynamic>.from(i))
              .toList() ??
          [];

      final List<Map<String, dynamic>> itemsList = rawLines.map((i) {
        final rawQty = i['qty'] ?? i['quantity'] ?? 1;
        final qty = rawQty is num ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 1);
        final rawPrice = i['price'] ?? i['unit_price'] ?? 0.0;
        final price = rawPrice is num ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
        final total = qty * price;
        return {
          'name': i['name'] ?? i['item_name'] ?? 'Item',
          'quantity': qty,
          'price': price,
          'total': total,
          'gst': 5.0,
          'discount': 0.0,
        };
      }).toList();

      double calculatedSubtotal = 0.0;
      for (var i in itemsList) {
        calculatedSubtotal += (i['total'] as num).toDouble();
      }
      double grandTotalVal = (h['amount'] as num?)?.toDouble() ?? 0.0;
      double calculatedDiscount =
          calculatedSubtotal > grandTotalVal ? calculatedSubtotal - grandTotalVal : 0.0;

      try {
        thermalPdfBytes = await PdfThermalGenerator.generateThermalBill(
          items: itemsList,
          subtotal: calculatedSubtotal > 0 ? calculatedSubtotal : grandTotalVal,
          discount: calculatedDiscount,
          tax: 0.0,
          grandTotal: grandTotalVal,
          roundedTotal: grandTotalVal.roundToDouble(),
          invoiceNumber: billNo,
          customerName: h['customer_name']?.toString() ?? 'Walk-in',
          customerPhone: h['customer_phone']?.toString() ?? '',
          shopName: shopName,
          address: address,
          phone: phone,
          shopGstNo: shopGstNo,
          upiId: upiId,
          cinNumber: cinNumber,
        );
      } catch (genErr) {
        debugPrint('Thermal generator error: $genErr');
      }
    }

    if (context.mounted && thermalPdfBytes != null) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: billNo,
        title: 'Tax Invoice Receipt',
        pdfBytes: thermalPdfBytes,
      );
    }
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _exportCustomerData(
    Map<String, dynamic> customer,
    String filterType,
  ) async {
    final history = (customer['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final now = DateTime.now();

    List<Map<String, dynamic>> filtered = history.where((h) {
      String dateStrRaw = h['date'].toString();
      if (!dateStrRaw.endsWith('Z')) {
        dateStrRaw += 'Z';
      }
      final date = DateTime.tryParse(dateStrRaw)?.toLocal();
      if (date == null) return false;

      if (filterType == 'This Year') {
        return date.year == now.year;
      } else if (filterType == 'This Month') {
        return date.year == now.year && date.month == now.month;
      } else if (filterType == 'Today') {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No records found for the selected period.'),
          ),
        );
      }
      return;
    }

    final exportData = filtered.map((h) {
      String dateStrRaw = h['date'].toString();
      if (!dateStrRaw.endsWith('Z')) dateStrRaw += 'Z';
      final date = DateTime.tryParse(dateStrRaw)?.toLocal();
      final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : h['date'].toString();
      final timeStr = date != null ? DateFormat('hh:mm a').format(date) : '';

      return {
        'Customer Name': customer['name'],
        'Phone': customer['phone'],
        'Date': dateStr,
        'Time': timeStr,
        'Bill No': h['bill_no'],
        'Amount': h['amount'],
      };
    }).toList();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Format'),
          content: const Text('Choose the format to export the data.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.exportToCSV(exportData, '${customer['name']}_export');
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.exportToExcel(exportData, '${customer['name']}_export');
              },
              child: const Text('Excel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.exportToPDF(exportData, '${customer['name']}_export');
              },
              child: const Text('PDF'),
            ),
          ],
        ),
      );
    }
  }
}
