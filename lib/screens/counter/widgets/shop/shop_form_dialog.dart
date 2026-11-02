import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';

/// Modal dialog for adding or editing a shop / outlet.
class ShopFormDialog extends StatefulWidget {
  final Shop? initialShop;
  final VoidCallback onSaved;

  const ShopFormDialog({
    super.key,
    this.initialShop,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Shop? shop,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ShopFormDialog(
        initialShop: shop,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<ShopFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _acHolderCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _bankAccountCtrl;
  late final TextEditingController _bankIfscCtrl;
  late String _status;
  late bool _isPrimary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialShop;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _locationCtrl = TextEditingController(text: s?.location ?? '');
    _cityCtrl = TextEditingController(text: s?.city ?? '');
    _contactCtrl = TextEditingController(text: s?.contact ?? '');
    _acHolderCtrl = TextEditingController(text: s?.bankAccountName ?? '');
    _bankNameCtrl = TextEditingController(text: s?.bankName ?? '');
    _bankAccountCtrl = TextEditingController(text: s?.bankAccount ?? '');
    _bankIfscCtrl = TextEditingController(text: s?.bankIfsc ?? '');
    _status = (s?.status.toLowerCase() == 'active') ? 'Active' : (s?.status ?? 'Active');
    _isPrimary = s?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    _contactCtrl.dispose();
    _acHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankIfscCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final extraData = Map<String, dynamic>.from(widget.initialShop?.rawJson?['extra_data'] ?? {});
      extraData['bank_account_name'] = _acHolderCtrl.text.trim();
      extraData['bank_name'] = _bankNameCtrl.text.trim();
      extraData['bank_account_no'] = _bankAccountCtrl.text.trim();
      extraData['bank_ifsc'] = _bankIfscCtrl.text.trim().toUpperCase();

      if (widget.initialShop == null) {
        await ShopService.createShop(
          name: name,
          code: _codeCtrl.text.trim(),
          address: _locationCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          contactNumber: _contactCtrl.text.trim(),
          status: _status,
          isPrimary: _isPrimary,
          extraData: extraData,
        );
      } else {
        await ShopService.updateShop(
          id: widget.initialShop!.id,
          name: name,
          code: _codeCtrl.text.trim(),
          address: _locationCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          contactNumber: _contactCtrl.text.trim(),
          status: _status,
          isPrimary: _isPrimary,
          extraData: extraData,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialShop == null
                ? 'Shop added successfully'
                : 'Shop updated successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialShop != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Shop' : 'Add New Shop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Shop Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtrl,
              decoration: const InputDecoration(labelText: 'Contact Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _acHolderCtrl,
              decoration: const InputDecoration(labelText: 'Account Holder Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankAccountCtrl,
              decoration: const InputDecoration(labelText: 'Bank Account Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankIfscCtrl,
              decoration: const InputDecoration(labelText: 'Bank IFSC Code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'Active'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Is Primary Shop?'),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
