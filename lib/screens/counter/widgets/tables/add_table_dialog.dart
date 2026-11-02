import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class AddTableDialog extends StatefulWidget {
  final List<String>? existingFloors;
  final DiningTable? initialTable;
  final ValueChanged<({String label, int capacity, String floor})> onSave;

  const AddTableDialog({
    super.key,
    this.existingFloors,
    this.initialTable,
    required this.onSave,
  });

  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _customFloorController;
  late int _capacity;
  late String _selectedFloor;
  bool _isCustomFloor = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialTable?.label ?? '');
    _capacity = widget.initialTable?.capacity ?? 4;
    _customFloorController = TextEditingController();

    final floors = (widget.existingFloors ?? [])
        .where((f) => f != 'All Floors' && f.trim().isNotEmpty)
        .toList();

    final targetFloor = widget.initialTable?.floor ?? '';

    if (targetFloor.isNotEmpty) {
      if (floors.contains(targetFloor)) {
        _selectedFloor = targetFloor;
        _isCustomFloor = false;
      } else {
        _selectedFloor = '';
        _isCustomFloor = true;
        _customFloorController.text = targetFloor;
      }
    } else if (floors.isNotEmpty) {
      _selectedFloor = floors.first;
      _isCustomFloor = false;
    } else {
      _selectedFloor = '';
      _isCustomFloor = true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _customFloorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isEdit = widget.initialTable != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(
            isEdit ? 'Update Dining Table' : 'Add New Dining Table',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Table Label
              const Text('Table Name / Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _labelController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name (e.g. T11, Rooftop 3)' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. T13, VIP-1, Window 2',
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                ),
              ),
              const SizedBox(height: 14),

              // Floor Section
              const Text('Floor / Dining Area', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final uniqueFloors = (widget.existingFloors ?? [])
                      .where((f) => f != 'All Floors' && f.trim().isNotEmpty)
                      .toSet();

                  if (uniqueFloors.isEmpty) {
                    return TextFormField(
                      controller: _customFloorController,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter floor name (e.g. Ground Floor, AC Hall)'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Ground Floor, 1st Floor, AC Hall',
                        hintStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        prefixIcon: const Icon(Icons.layers_outlined, size: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      ),
                    );
                  }

                  if (!uniqueFloors.contains(_selectedFloor)) {
                    _selectedFloor = uniqueFloors.first;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _isCustomFloor ? '__custom__' : _selectedFloor,
                        items: [
                          ...uniqueFloors.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                          const DropdownMenuItem(
                            value: '__custom__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text('+ Add New Floor / Area', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__custom__') {
                            setState(() => _isCustomFloor = true);
                          } else if (val != null) {
                            setState(() {
                              _isCustomFloor = false;
                              _selectedFloor = val;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                      if (_isCustomFloor) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customFloorController,
                          validator: (val) => _isCustomFloor && (val == null || val.trim().isEmpty)
                              ? 'Please enter floor name (e.g. Ground Floor, AC Hall)'
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Enter new floor name (e.g. Ground Floor, Rooftop)',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            prefixIcon: const Icon(Icons.layers_outlined, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Seating Capacity
              const Text('Seating Capacity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [2, 4, 6, 8, 10, 12].map((cap) {
                  final isSelected = _capacity == cap;
                  return ChoiceChip(
                    label: Text('$cap Seater', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    onSelected: (_) => setState(() => _capacity = cap),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final hasExisting = (widget.existingFloors ?? [])
                  .any((f) => f != 'All Floors' && f.trim().isNotEmpty);
              final finalFloor = (!hasExisting || _isCustomFloor)
                  ? _customFloorController.text.trim()
                  : _selectedFloor;

              widget.onSave((
                label: _labelController.text.trim(),
                capacity: _capacity,
                floor: finalFloor,
              ));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(isEdit ? 'Update Table' : 'Add Table'),
        ),
      ],
    );
  }
}
