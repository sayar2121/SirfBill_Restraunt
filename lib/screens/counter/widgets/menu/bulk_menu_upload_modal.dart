import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../services/inventory_service.dart';

class BulkMenuUploadModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const BulkMenuUploadModal({
    super.key,
    required this.onSuccess,
  });

  @override
  State<BulkMenuUploadModal> createState() => _BulkMenuUploadModalState();
}

class _BulkMenuUploadModalState extends State<BulkMenuUploadModal> {
  bool _isLoading = false;
  bool _isDownloading = false;
  PlatformFile? _selectedFile;
  String _targetOutletName = 'Loading outlet...';
  String? _targetOutletId;
  List<Shop> _availableShops = [];

  @override
  void initState() {
    super.initState();
    _loadOutletInfo();
  }

  Future<void> _loadOutletInfo() async {
    try {
      final shops = await ShopService.getShops();
      final prefs = await SharedPreferences.getInstance();
      final savedShopId = prefs.getString('selected_shop_id') ?? await InventoryService.getShopId();
      final assignedOutletId = prefs.getString('assigned_outlet_id');
      final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();

      final isRestricted = (role.isNotEmpty && role != 'ADMIN' && role != 'OWNER' && role != 'SUPER_ADMIN') ||
          (assignedOutletId != null && assignedOutletId.isNotEmpty);

      Shop? matched;
      final targetId = assignedOutletId ?? savedShopId;
      if (targetId.isNotEmpty) {
        matched = shops.firstWhere((s) => s.id == targetId, orElse: () => shops.first);
      } else if (shops.isNotEmpty) {
        matched = shops.first;
      }

      if (mounted) {
        setState(() {
          _availableShops = isRestricted && matched != null ? [matched] : shops;
          _targetOutletId = matched?.id ?? targetId;
          _targetOutletName = matched?.name ?? 'Main Restaurant Outlet';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _targetOutletName = 'Active Restaurant Outlet';
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Uint8List _generateFallbackMenuExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Menu Template'];
    excel.setDefaultSheet('Menu Template');

    sheet.appendRow([
      TextCellValue('Item Name'),
      TextCellValue('Category'),
      TextCellValue('Price'),
      TextCellValue('Food Type'),
      TextCellValue('Short Code'),
      TextCellValue('Description'),
    ]);

    sheet.appendRow([
      TextCellValue('Chicken Biryani'),
      TextCellValue('Biryani & Rice'),
      DoubleCellValue(350.0),
      TextCellValue('NON_VEG'),
      TextCellValue('CB'),
      TextCellValue('Aromatic basmati rice cooked with chicken pieces and spices'),
    ]);

    sheet.appendRow([
      TextCellValue('Paneer Tikka'),
      TextCellValue('Tandoor & Starters'),
      DoubleCellValue(260.0),
      TextCellValue('VEG'),
      TextCellValue('PT'),
      TextCellValue('Grilled cottage cheese marinated in spiced yogurt'),
    ]);

    sheet.appendRow([
      TextCellValue('Butter Naan'),
      TextCellValue('Breads'),
      DoubleCellValue(45.0),
      TextCellValue('VEG'),
      TextCellValue('BN'),
      TextCellValue('Fresh tandoori bread coated with butter'),
    ]);

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  Uint8List _generateFallbackMenuCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Item Name,Category,Price,Food Type,Short Code,Description');
    buffer.writeln('"Chicken Biryani","Biryani & Rice",350.0,"NON_VEG","CB","Aromatic basmati rice cooked with chicken"');
    buffer.writeln('"Paneer Tikka","Tandoor & Starters",260.0,"VEG","PT","Grilled cottage cheese marinated in spiced yogurt"');
    buffer.writeln('"Butter Naan","Breads",45.0,"VEG","BN","Fresh tandoori bread coated with butter"');
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  Future<void> _downloadTemplate({bool isExcel = true}) async {
    setState(() => _isDownloading = true);
    try {
      final ext = isExcel ? 'xlsx' : 'csv';
      final mime = isExcel ? MimeType.microsoftExcel : MimeType.csv;
      final cleanName = _targetOutletName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
      final filename = 'menu_template_$cleanName';

      List<int> bytes;
      try {
        bytes = await RestaurantPosService.downloadSampleMenuTemplate(
          outletId: _targetOutletId,
          format: ext,
        );
      } catch (e) {
        debugPrint('Backend template download failed ($e). Using instant client-generated template.');
        bytes = isExcel ? _generateFallbackMenuExcel() : _generateFallbackMenuCSV();
      }

      if (bytes.isEmpty) {
        bytes = isExcel ? _generateFallbackMenuExcel() : _generateFallbackMenuCSV();
      }

      final uint8Bytes = Uint8List.fromList(bytes);

      // Attempt 1: FileSaver saveAs (dialog)
      bool saved = false;
      String? savedLocation;
      try {
        final res = await FileSaver.instance.saveAs(
          name: filename,
          bytes: uint8Bytes,
          fileExtension: ext,
          mimeType: mime,
        );
        if (res != null && res.isNotEmpty) {
          saved = true;
          savedLocation = res;
        }
      } catch (e) {
        debugPrint('saveAs threw error on desktop: $e');
      }

      // Attempt 2: Direct file write to Downloads directory on Desktop (Windows / macOS)
      if (!saved && !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        try {
          final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final targetFile = File('${downloadsDir.path}${Platform.pathSeparator}$filename.$ext');
          await targetFile.writeAsBytes(uint8Bytes);
          saved = true;
          savedLocation = targetFile.path;
        } catch (e) {
          debugPrint('Direct desktop file write failed: $e');
        }
      }

      // Attempt 3: FileSaver saveFile (auto save)
      if (!saved) {
        savedLocation = await FileSaver.instance.saveFile(
          name: filename,
          bytes: uint8Bytes,
          fileExtension: ext,
          mimeType: mime,
        );
        saved = true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedLocation != null && savedLocation.isNotEmpty
                  ? 'Template saved to: $savedLocation'
                  : 'Downloaded menu template (.$ext) to your Downloads folder!',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download template: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Excel or CSV file first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Uint8List? fileBytes = _selectedFile!.bytes;
      if (fileBytes == null && !kIsWeb && _selectedFile!.path != null) {
        try {
          final file = File(_selectedFile!.path!);
          if (await file.exists()) {
            fileBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Error reading selected file bytes: $e');
        }
      }

      final res = await RestaurantPosService.bulkUploadMenu(
        filename: _selectedFile!.name,
        bytes: fileBytes,
        path: kIsWeb ? null : _selectedFile!.path,
        outletId: _targetOutletId,
      );

      if (mounted) {
        final total = res['total_processed'] ?? res['created_count'] ?? 0;
        final cats = res['categories_created'] ?? 0;
        final outlet = res['outlet_name'] ?? _targetOutletName;

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uploaded $total items ($cats new categories) for $outlet!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: Color(0xFF10B981),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Upload Menu Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Import food items in bulk using an Excel (.xlsx) or CSV file',
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Target Outlet Information Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Restaurant Outlet',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 1),
                          if (_availableShops.length > 1)
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _targetOutletId,
                                isDense: true,
                                isExpanded: true,
                                items: _availableShops.map((s) {
                                  return DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final picked = _availableShops.firstWhere((s) => s.id == val);
                                    setState(() {
                                      _targetOutletId = picked.id;
                                      _targetOutletName = picked.name;
                                    });
                                  }
                                },
                              ),
                            )
                          else
                            Text(
                              _targetOutletName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feature Highlights Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureTag(Icons.auto_awesome_rounded, 'Auto UUID & Tenant'),
                  _buildFeatureTag(Icons.category_rounded, 'Auto-Create Category'),
                  _buildFeatureTag(Icons.tag_rounded, 'Auto Short Code (e.g. CB)'),
                  _buildFeatureTag(Icons.currency_rupee_rounded, 'Standard Pricing'),
                ],
              ),
              const SizedBox(height: 16),

              // Download Sample Template Row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need a template file?',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                          ),
                          Text(
                            'Download pre-formatted sample with columns for Dish Name, Category, Price, etc.',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isDownloading ? null : () => _downloadTemplate(isExcel: true),
                          icon: const Icon(Icons.file_download_outlined, size: 14),
                          label: const Text('Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isDownloading ? null : () => _downloadTemplate(isExcel: false),
                          icon: const Icon(Icons.file_download_outlined, size: 14),
                          label: const Text('CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // File Selection Box
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _selectedFile != null
                        ? const Color(0xFF10B981).withValues(alpha: 0.06)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: _selectedFile != null ? 1.6 : 1.4,
                    ),
                  ),
                  child: _selectedFile != null
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • Ready to upload',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                              label: const Text('Change', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_rounded,
                                size: 30,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Click to Browse Excel or CSV file',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supported formats: .xlsx, .xls, .csv',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Modal Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_upload_rounded, size: 18),
                    label: Text(
                      _isLoading ? 'Processing Menu...' : 'Upload & Import Dishes',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF10B981)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
