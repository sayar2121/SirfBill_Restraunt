import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/distributor_provider.dart';

class EditDistributorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> distributor;
  const EditDistributorDialog({super.key, required this.distributor});

  @override
  ConsumerState<EditDistributorDialog> createState() => _EditDistributorDialogState();
}

class _EditDistributorDialogState extends ConsumerState<EditDistributorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstinController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.distributor['name'] ?? '');
    _contactPersonController = TextEditingController(text: widget.distributor['contact_person'] ?? '');
    _phoneController = TextEditingController(text: widget.distributor['phone'] ?? '');
    _emailController = TextEditingController(text: widget.distributor['email'] ?? '');
    _gstinController = TextEditingController(text: widget.distributor['gstin'] ?? '');
    _addressController = TextEditingController(text: widget.distributor['address'] ?? '');
    _notesController = TextEditingController(text: widget.distributor['notes'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(distributorServiceProvider);
      await service.updateDistributor(widget.distributor['id'], {
        'name': _nameController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gstin': _gstinController.text.trim(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
      });
      
      // Refresh list
      ref.invalidate(distributorsProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Distributor updated successfully!'), backgroundColor: Color(0xFF166534)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Distributor', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Distributor Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(labelText: 'Contact Person (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gstinController,
                  decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address (Optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
