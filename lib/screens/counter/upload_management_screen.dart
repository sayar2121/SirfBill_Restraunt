import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/inventory_service.dart';
import '../../services/export_service.dart';
import '../../providers/counter_providers.dart';
import '../../providers/distributor_provider.dart';
import 'widgets/upload/upload_header.dart';
import 'widgets/upload/basic_info_card.dart';
import 'widgets/upload/pricing_stock_card.dart';
import 'widgets/upload/additional_info_card.dart';
import 'widgets/upload/upload_bottom_bar.dart';

class UploadManagementScreen extends ConsumerStatefulWidget {
  const UploadManagementScreen({super.key});

  @override
  ConsumerState<UploadManagementScreen> createState() =>
      _UploadManagementScreenState();
}

class _UploadManagementScreenState
    extends ConsumerState<UploadManagementScreen> {
  bool _isUploading = false;
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _packSizeCtrl = TextEditingController(text: '1');
  final _looseStockCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(); // MRP/Selling Price
  final _buyingPriceCtrl = TextEditingController(); // Buying Price
  final _hsnCtrl = TextEditingController();
  final _gstCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  String? _selectedDistributorId;
  String? _selectedRackId;
  String? _selectedCategoryId;
  PlatformFile? _selectedImage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _expiryCtrl.dispose();
    _manufacturerCtrl.dispose();
    _stockCtrl.dispose();
    _packSizeCtrl.dispose();
    _looseStockCtrl.dispose();
    _priceCtrl.dispose();
    _buyingPriceCtrl.dispose();
    _hsnCtrl.dispose();
    _gstCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedImage = result.files.first;
      });
    }
  }

  Future<void> _uploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        final bool hasBytes = platformFile.bytes != null;
        final bool hasPath = !kIsWeb && platformFile.path != null;

        if (hasBytes || hasPath) {
          setState(() {
            _isUploading = true;
          });

          final message = await InventoryService.uploadInventory(
            filename: platformFile.name,
            bytes: platformFile.bytes,
            path: kIsWeb ? null : platformFile.path,
          );

          if (mounted) {
            ref.invalidate(inventoryProvider);
            ref.invalidate(categoryProvider);
            ref.invalidate(rackProvider);
            ref.invalidate(distributorsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).cardColor),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed: $e',
              style: TextStyle(color: Theme.of(context).cardColor),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _downloadTemplate() async {
    final templateHeaders = [
      'Name',
      'SKU',
      'Batch',
      'Stock',
      'Loose Stock',
      'Pack Size',
      'Buying Price (₹)',
      'Unit Price (₹)',
      'GST (%)',
      'Discount (%)',
      'Manufacturer',
      'Expiry',
      'Rack',
      'Category',
      'Distributor',
      'HSN Code',
    ];
    await ExportService.exportHeadersToCSV(
      templateHeaders,
      'inventory_upload_template',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blank template downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveItem() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields.',
            style: TextStyle(color: Theme.of(context).cardColor),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      setState(() => _isUploading = true);

      String? uploadedImageUrl;
      if (_selectedImage != null && _selectedImage!.bytes != null) {
        try {
          uploadedImageUrl = await InventoryService.uploadItemImage(
            _selectedImage!.bytes!,
            _selectedImage!.name,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload image: $e',
                  style: TextStyle(color: Theme.of(context).cardColor),
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isUploading = false);
          }
          return;
        }
      }

      final distList = ref.read(distributorsProvider).value ?? [];
      final distMatch = distList.firstWhere(
        (d) => d['id']?.toString() == _selectedDistributorId?.toString(),
        orElse: () => null,
      );
      final distName = distMatch?['name']?.toString();

      await InventoryService.addItem({
        'name': _nameCtrl.text,
        'sku': _skuCtrl.text.isNotEmpty
            ? _skuCtrl.text
            : DateTime.now().millisecondsSinceEpoch.toString(),
        'manufacturer': _manufacturerCtrl.text,
        'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
        'pack_size': int.tryParse(_packSizeCtrl.text) ?? 1,
        'loose_stock': int.tryParse(_looseStockCtrl.text) ?? 0,
        'hsn_code': _hsnCtrl.text.isNotEmpty ? _hsnCtrl.text : '3004',
        'expiry_date': _expiryCtrl.text,
        'buying_price': double.tryParse(_buyingPriceCtrl.text) ?? 0.0,
        'unit_price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'gst': double.tryParse(_gstCtrl.text) ?? 0.0,
        'discount': double.tryParse(_discountCtrl.text) ?? 0.0,
        'rack_id': _selectedRackId,
        'category_id': _selectedCategoryId,
        'distributor_id': _selectedDistributorId,
        if (distName != null && distName.isNotEmpty) ...{
          'distributor': distName,
          'distributor_name': distName,
        },
        'image_url': uploadedImageUrl,
      });

      if (mounted) {
        ref.invalidate(inventoryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item added successfully!',
              style: TextStyle(color: Theme.of(context).cardColor),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: TextStyle(color: Theme.of(context).cardColor),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header
          UploadHeader(
            isUploading: _isUploading,
            onBack: () => Navigator.pop(context),
            onDownloadTemplate: _downloadTemplate,
            onUploadExcel: _uploadExcel,
            onRefresh: () {
              ref.invalidate(categoryProvider);
              ref.invalidate(rackProvider);
            },
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  BasicInfoCard(
                    nameCtrl: _nameCtrl,
                    manufacturerCtrl: _manufacturerCtrl,
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    selectedDistributorId: _selectedDistributorId,
                    onDistributorChanged: (value) {
                      setState(() => _selectedDistributorId = value);
                    },
                    selectedImage: _selectedImage,
                    onPickImage: _pickImage,
                    onRemoveImage: () {
                      setState(() => _selectedImage = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  PricingStockCard(
                    buyingPriceCtrl: _buyingPriceCtrl,
                    priceCtrl: _priceCtrl,
                    stockCtrl: _stockCtrl,
                    packSizeCtrl: _packSizeCtrl,
                    looseStockCtrl: _looseStockCtrl,
                    gstCtrl: _gstCtrl,
                    discountCtrl: _discountCtrl,
                    selectedRackId: _selectedRackId,
                    onRackChanged: (value) {
                      setState(() => _selectedRackId = value);
                    },
                    expiryCtrl: _expiryCtrl,
                    hsnCtrl: _hsnCtrl,
                  ),
                  const SizedBox(height: 24),
                  AdditionalInfoCard(
                    skuCtrl: _skuCtrl,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          UploadBottomBar(
            isSaving: _isUploading,
            onCancel: () => Navigator.pop(context),
            onSave: _saveItem,
          ),
        ],
      ),
    );
  }
}
