import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings_models.dart';
import '../../providers/counter_providers.dart';
import '../../services/shop_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/responsive.dart';
import 'widgets/bill_customization/bill_customization_forms.dart';
import 'widgets/bill_customization/bill_customization_header.dart';
import 'widgets/bill_customization/bill_customization_service.dart';
import 'widgets/bill_customization/bill_preview_panel.dart';

class BillCustomizationScreen extends ConsumerStatefulWidget {
  const BillCustomizationScreen({super.key});

  @override
  ConsumerState<BillCustomizationScreen> createState() =>
      _BillCustomizationScreenState();
}

class _BillCustomizationScreenState
    extends ConsumerState<BillCustomizationScreen> {
  bool _isSaving = false;
  bool _isGenerating = false;

  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _landlineCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _gstCtrl = TextEditingController();
  final TextEditingController _fssaiCtrl = TextEditingController();

  String _outletType = 'Dine-in, Takeaway & Delivery';
  final TextEditingController _openingTimeCtrl = TextEditingController(text: '09:00 AM');
  final TextEditingController _closingTimeCtrl = TextEditingController(text: '11:00 PM');

  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _branchNameCtrl = TextEditingController();
  final TextEditingController _acHolderCtrl = TextEditingController();
  final TextEditingController _acNumberCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();

  final TextEditingController _terms1Ctrl = TextEditingController();
  final TextEditingController _terms2Ctrl = TextEditingController();
  final TextEditingController _terms3Ctrl = TextEditingController();

  String? _logoUrl;
  String? _qrUrl;
  Shop? _activeOutlet;

  String _previewFormat = 'Thermal';
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRestaurantSettings();
    });
  }

  Future<void> _loadRestaurantSettings() async {
    try {
      final settings = await ref.read(settingsProvider.future);
      _populateFields(settings);

      // Cross-sync with active outlet from ShopService if available
      final outletId = await InventoryService.getShopId();
      final shops = await ShopService.getShops();
      if (shops.isNotEmpty) {
        final active = shops.firstWhere(
          (s) => s.id == outletId,
          orElse: () => shops.first,
        );

        if (mounted) {
          setState(() {
            _activeOutlet = active;
            if (active.name.isNotEmpty) {
              _shopNameCtrl.text = active.name;
            }
            if (active.location.isNotEmpty) {
              _addressCtrl.text = active.location;
            }
            if (active.contact.isNotEmpty) {
              _phoneCtrl.text = active.contact.replaceAll('+91 ', '').trim();
            }
            if ((active.gstin ?? '').isNotEmpty) {
              _gstCtrl.text = active.gstin!;
            }
            if ((active.fssai ?? '').isNotEmpty) {
              _fssaiCtrl.text = active.fssai!;
            }
            if ((active.upiId ?? '').isNotEmpty) {
              _upiIdCtrl.text = active.upiId!;
            }
            if ((active.bankName ?? '').isNotEmpty) {
              _bankNameCtrl.text = active.bankName!;
            }
            if ((active.bankBranch ?? '').isNotEmpty) {
              _branchNameCtrl.text = active.bankBranch!;
            }
            if ((active.bankAccount ?? '').isNotEmpty) {
              _acNumberCtrl.text = active.bankAccount!;
            }
            if ((active.bankIfsc ?? '').isNotEmpty) {
              _ifscCtrl.text = active.bankIfsc!;
            }
            if ((active.bankAccountName ?? '').isNotEmpty) {
              _acHolderCtrl.text = active.bankAccountName!;
            }
            if ((active.openingTime ?? '').isNotEmpty) {
              _openingTimeCtrl.text = active.openingTime!;
            }
            if ((active.closingTime ?? '').isNotEmpty) {
              _closingTimeCtrl.text = active.closingTime!;
            }
            if ((active.outletType ?? '').isNotEmpty) {
              _outletType = active.outletType!;
            }
            if (active.logoUrl != null && active.logoUrl!.isNotEmpty) {
              _logoUrl = active.logoUrl;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _landlineCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _fssaiCtrl.dispose();
    _openingTimeCtrl.dispose();
    _closingTimeCtrl.dispose();
    _bankNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _acHolderCtrl.dispose();
    _acNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _upiIdCtrl.dispose();
    _terms1Ctrl.dispose();
    _terms2Ctrl.dispose();
    _terms3Ctrl.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> settings) {
    if (!mounted) return;
    setState(() {
      _shopNameCtrl.text = settings['shop_name'] ?? '';
      _taglineCtrl.text = settings['tagline'] ?? '';
      _addressCtrl.text = settings['address'] ?? '';
      _phoneCtrl.text = settings['phone'] ?? '';
      _landlineCtrl.text = settings['landline'] ?? '';
      _emailCtrl.text = settings['email'] ?? '';
      _gstCtrl.text = settings['gst_number'] ?? '';
      _fssaiCtrl.text = settings['fssai_number'] ?? settings['fssai'] ?? settings['cin_number'] ?? '';

      _outletType = settings['outlet_type'] ?? _outletType;
      _openingTimeCtrl.text = settings['opening_time'] ?? _openingTimeCtrl.text;
      _closingTimeCtrl.text = settings['closing_time'] ?? _closingTimeCtrl.text;

      _bankNameCtrl.text = settings['bank_name'] ?? '';
      _branchNameCtrl.text = settings['branch_name'] ?? '';
      _acHolderCtrl.text = settings['ac_holder_name'] ?? '';
      _acNumberCtrl.text = settings['ac_number'] ?? '';
      _ifscCtrl.text = settings['ifsc_code'] ?? '';
      _upiIdCtrl.text = settings['upi_id'] ?? '';

      _terms1Ctrl.text = settings['terms_1'] ?? '';
      _terms2Ctrl.text = settings['terms_2'] ?? '';
      _terms3Ctrl.text = settings['terms_3'] ?? '';

      _logoUrl = settings['logo_url'];
      _qrUrl = settings['qr_url'];
    });
  }

  Future<void> _saveSettings() async {
    final gst = _gstCtrl.text.trim();
    if (gst.isNotEmpty && !RegExp(r'^[A-Za-z0-9]{15}$').hasMatch(gst)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GST Number must be exactly 15 alphanumeric characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone Number must be exactly 10 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'shop_name': _shopNameCtrl.text.trim(),
        'tagline': _taglineCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'landline': _landlineCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'gst_number': _gstCtrl.text.trim(),
        'fssai_number': _fssaiCtrl.text.trim(),
        'cin_number': _fssaiCtrl.text.trim(),
        'outlet_type': _outletType,
        'opening_time': _openingTimeCtrl.text.trim(),
        'closing_time': _closingTimeCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'branch_name': _branchNameCtrl.text.trim(),
        'ac_holder_name': _acHolderCtrl.text.trim(),
        'ac_number': _acNumberCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim(),
        'upi_id': _upiIdCtrl.text.trim(),
        'terms_1': _terms1Ctrl.text.trim(),
        'terms_2': _terms2Ctrl.text.trim(),
        'terms_3': _terms3Ctrl.text.trim(),
        'logo_url': _logoUrl,
        'qr_url': _qrUrl,
      };

      await ref.read(settingsProvider.notifier).updateSettings(data);

      // Also persist to current active outlet if valid
      if (_activeOutlet != null) {
        try {
          await ShopService.updateShop(
            id: _activeOutlet!.id,
            name: _shopNameCtrl.text.trim(),
            code: _activeOutlet!.code,
            address: _addressCtrl.text.trim(),
            city: _activeOutlet!.city,
            contactNumber: _phoneCtrl.text.trim(),
            status: _activeOutlet!.status,
            isPrimary: _activeOutlet!.isPrimary,
            extraData: {
              'gstin': _gstCtrl.text.trim(),
              'gst_number': _gstCtrl.text.trim(),
              'fssai': _fssaiCtrl.text.trim(),
              'fssai_no': _fssaiCtrl.text.trim(),
              'upi_id': _upiIdCtrl.text.trim(),
              'bank_name': _bankNameCtrl.text.trim(),
              'bank_branch': _branchNameCtrl.text.trim(),
              'bank_account_no': _acNumberCtrl.text.trim(),
              'bank_ifsc': _ifscCtrl.text.trim(),
              'bank_account_name': _acHolderCtrl.text.trim(),
              'outlet_type': _outletType,
              'logo_url': _logoUrl,
              'opening_time': _openingTimeCtrl.text.trim(),
              'closing_time': _closingTimeCtrl.text.trim(),
            },
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant & Outlet settings saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final result = await BillCustomizationService.pickAndUploadImage(
      context: context,
      isLogo: isLogo,
    );
    if (result != null && mounted) {
      setState(() {
        if (isLogo) {
          _logoUrl = result['url'];
        } else {
          _qrUrl = result['url'];
        }
      });
    }
  }

  Future<void> _generatePreviewPdf() async {
    setState(() => _isGenerating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating Preview...'),
          ],
        ),
      ),
    );

    try {
      final settings = ShopSettings(
        shopName: _shopNameCtrl.text,
        tagline: _taglineCtrl.text,
        address: _addressCtrl.text,
        phone: _phoneCtrl.text,
        landline: _landlineCtrl.text,
        email: _emailCtrl.text,
        gstNumber: _gstCtrl.text,
        cinNumber: _fssaiCtrl.text,
        bankName: _bankNameCtrl.text,
        branchName: _branchNameCtrl.text,
        acHolderName: _acHolderCtrl.text,
        acNumber: _acNumberCtrl.text,
        ifscCode: _ifscCtrl.text,
        upiId: _upiIdCtrl.text.trim(),
        terms1: _terms1Ctrl.text,
        terms2: _terms2Ctrl.text,
        terms3: _terms3Ctrl.text,
      );

      final bytes = await BillCustomizationService.generatePreviewPdf(
        logoUrl: _logoUrl,
        qrUrl: _qrUrl,
        previewFormat: _previewFormat,
        settings: settings,
      );

      if (mounted) {
        setState(() => _previewBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    if (settingsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            BillCustomizationHeader(
              isDark: isDark,
              isSaving: _isSaving,
              onSave: _saveSettings,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Builder(
                builder: (context) {
                  final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);

                  final rightPane = BillPreviewPanel(
                    previewFormat: _previewFormat,
                    previewBytes: _previewBytes,
                    isGenerating: _isGenerating,
                    onFormatChanged: (format) {
                      setState(() {
                        _previewFormat = format;
                        _previewBytes = null;
                      });
                    },
                    onGeneratePreview: _generatePreviewPdf,
                  );

                  final leftPane = BillCustomizationForms(
                    isDark: isDark,
                    isDesktop: isDesktop,
                    shopNameCtrl: _shopNameCtrl,
                    taglineCtrl: _taglineCtrl,
                    addressCtrl: _addressCtrl,
                    phoneCtrl: _phoneCtrl,
                    landlineCtrl: _landlineCtrl,
                    emailCtrl: _emailCtrl,
                    gstCtrl: _gstCtrl,
                    fssaiCtrl: _fssaiCtrl,
                    outletType: _outletType,
                    onOutletTypeChanged: (val) {
                      if (val != null) setState(() => _outletType = val);
                    },
                    openingTimeCtrl: _openingTimeCtrl,
                    closingTimeCtrl: _closingTimeCtrl,
                    bankNameCtrl: _bankNameCtrl,
                    branchNameCtrl: _branchNameCtrl,
                    acHolderCtrl: _acHolderCtrl,
                    acNumberCtrl: _acNumberCtrl,
                    ifscCtrl: _ifscCtrl,
                    upiIdCtrl: _upiIdCtrl,
                    terms1Ctrl: _terms1Ctrl,
                    terms2Ctrl: _terms2Ctrl,
                    terms3Ctrl: _terms3Ctrl,
                    logoUrl: _logoUrl,
                    qrUrl: _qrUrl,
                    onPickLogo: () => _pickImage(true),
                    onPickQr: () => _pickImage(false),
                    onClearLogo: () => setState(() => _logoUrl = null),
                    onClearQr: () => setState(() => _qrUrl = null),
                    rightPane: rightPane,
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leftPane),
                        const SizedBox(width: 24),
                        Expanded(child: rightPane),
                      ],
                    );
                  } else {
                    return leftPane;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
