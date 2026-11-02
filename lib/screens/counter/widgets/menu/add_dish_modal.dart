import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/inventory_service.dart';

class AddDishModal extends StatefulWidget {
  final List<MenuCategory> categories;
  final PosMenuItem? initialDish;
  final ValueChanged<PosMenuItem> onSave;
  final VoidCallback? onAddNewCategory;

  const AddDishModal({
    super.key,
    required this.categories,
    this.initialDish,
    required this.onSave,
    this.onAddNewCategory,
  });

  @override
  State<AddDishModal> createState() => _AddDishModalState();
}

class _AddDishModalState extends State<AddDishModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortCodeController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;
  late String _selectedCatId;
  String? _selectedBadge;
  bool _isAvailable = true;
  bool _isVeg = true;
  bool _isCustomShortCode = false;

  // Image source mode: 0 = Upload File, 1 = Image Link / URL
  int _imageMode = 0;
  Uint8List? _uploadedImageBytes;
  String? _uploadedFileName;
  bool _isUploadingImage = false;

  String _deriveShortCode(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 4 ? 4 : words[0].length).toUpperCase();
    }
    return words.take(4).map((w) => w[0]).join().toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    final d = widget.initialDish;
    _nameController = TextEditingController(text: d?.name ?? '');
    _shortCodeController = TextEditingController(text: d?.shortCode ?? '');
    if (d?.shortCode != null && d!.shortCode!.isNotEmpty) {
      _isCustomShortCode = true;
    }
    _priceController = TextEditingController(text: d != null ? d.price.toStringAsFixed(0) : '');
    _descController = TextEditingController(text: d?.description ?? '');
    _imageUrlController = TextEditingController(text: d?.imageUrl ?? '');

    _nameController.addListener(() {
      if (!_isCustomShortCode) {
        final generated = _deriveShortCode(_nameController.text);
        if (_shortCodeController.text != generated) {
          _shortCodeController.text = generated;
        }
      }
    });

    final availableCats = widget.categories.where((c) => c.id != 'all').toList();
    if (d != null && d.categoryId.isNotEmpty && d.categoryId != 'all') {
      _selectedCatId = d.categoryId;
    } else if (availableCats.isNotEmpty) {
      _selectedCatId = availableCats.first.id;
    } else if (widget.categories.isNotEmpty) {
      _selectedCatId = widget.categories.first.id;
    } else {
      _selectedCatId = '';
    }

    _selectedBadge = d?.badge;
    _isAvailable = d?.isAvailable ?? true;
    _isVeg = d?.isVeg ?? true;

    // If initial dish has an image URL, default to Image Link mode
    if (d?.imageUrl != null && d!.imageUrl!.isNotEmpty) {
      _imageMode = 1;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        Uint8List? fileBytes = platformFile.bytes;

        if (fileBytes == null || fileBytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not read image file data.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        setState(() {
          _uploadedImageBytes = fileBytes;
          _uploadedFileName = platformFile.name;
          _isUploadingImage = true;
        });

        final uploadedUrl = await InventoryService.uploadItemImage(fileBytes, platformFile.name);

        if (mounted) {
          setState(() {
            _imageUrlController.text = uploadedUrl;
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Color(0xFF10B981)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final rawSelectable = widget.categories.where((c) => c.id != 'all').toList();
    final selectableCats = rawSelectable.isNotEmpty ? rawSelectable : widget.categories;
    final currentCatVal = selectableCats.any((c) => c.id == _selectedCatId)
        ? _selectedCatId
        : (selectableCats.isNotEmpty ? selectableCats.first.id : null);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.initialDish != null ? Icons.edit_note_rounded : Icons.restaurant_menu_rounded,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.initialDish != null ? 'Edit Food Item' : 'Add New Food Item',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Item Name & Short Code Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dish / Beverage Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter dish name' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. Paneer Butter Masala',
                                hintStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Short Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(
                                  _isCustomShortCode ? 'Manual' : 'Auto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isCustomShortCode ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _shortCodeController,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (v) {
                                setState(() {
                                  _isCustomShortCode = v.trim().isNotEmpty;
                                });
                              },
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                              decoration: InputDecoration(
                                hintText: 'e.g. PBM',
                                hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category & Price
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                if (widget.onAddNewCategory != null)
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onAddNewCategory!();
                                    },
                                    child: const Text(
                                      '+ New',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: currentCatVal,
                              items: selectableCats.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text('${c.iconEmoji} ${c.name}'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCatId = val);
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter price';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. 250',
                                hintStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description / Notes
                  const Text('Description (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ingredients, spice level, or serving portion...',
                      hintStyle: const TextStyle(fontSize: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Food Type: Veg / Non-Veg
                  const Text('Food Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _isVeg = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isVeg ? const Color(0xFF10B981).withValues(alpha: 0.15) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isVeg ? const Color(0xFF10B981) : borderColor,
                                width: _isVeg ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Center(
                                    child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pure Veg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _isVeg ? FontWeight.bold : FontWeight.w500,
                                    color: _isVeg ? const Color(0xFF10B981) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _isVeg = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isVeg ? const Color(0xFFEF4444).withValues(alpha: 0.15) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !_isVeg ? const Color(0xFFEF4444) : borderColor,
                                width: !_isVeg ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Center(
                                    child: CircleAvatar(radius: 3, backgroundColor: Color(0xFFEF4444)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Non-Veg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !_isVeg ? FontWeight.bold : FontWeight.w500,
                                    color: !_isVeg ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dish Image (Option 1: Upload File, Option 2: Image Link)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dish Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (_imageUrlController.text.trim().isNotEmpty || _uploadedImageBytes != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _imageUrlController.clear();
                              _uploadedImageBytes = null;
                              _uploadedFileName = null;
                            });
                          },
                          child: const Text('Remove Image', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Option Selector: [Upload File] | [Image Link]
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _imageMode = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _imageMode == 0 ? const Color(0xFF10B981) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file_rounded, size: 14, color: _imageMode == 0 ? Colors.white : const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Upload File',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _imageMode == 0 ? FontWeight.bold : FontWeight.w500,
                                      color: _imageMode == 0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _imageMode = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _imageMode == 1 ? const Color(0xFF10B981) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link_rounded, size: 14, color: _imageMode == 1 ? Colors.white : const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Image Link',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _imageMode == 1 ? FontWeight.bold : FontWeight.w500,
                                      color: _imageMode == 1 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Option 1: Upload File Box
                  if (_imageMode == 0) ...[
                    InkWell(
                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _uploadedImageBytes != null || _imageUrlController.text.isNotEmpty ? const Color(0xFF10B981) : borderColor,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))),
                                      SizedBox(height: 6),
                                      Text('Uploading image...', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                                    ],
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _uploadedImageBytes != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(_uploadedImageBytes!, fit: BoxFit.cover),
                                          )
                                        : (_imageUrlController.text.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _imageUrlController.text,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Color(0xFF10B981)),
                                                ),
                                              )
                                            : const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF10B981), size: 26)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _uploadedFileName ?? (_imageUrlController.text.isNotEmpty ? 'Image uploaded' : 'Click to choose image file'),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _uploadedImageBytes != null
                                              ? 'Tap to change photo'
                                              : 'JPG, PNG, WebP supported from computer',
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.folder_open_rounded, size: 20, color: Color(0xFF10B981)),
                                ],
                              ),
                      ),
                    ),
                  ],

                  // Option 2: Image Link Input Box
                  if (_imageMode == 1) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thumbnail preview
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: _imageUrlController.text.trim().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imageUrlController.text.trim(),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_rounded, size: 20, color: Color(0xFFEF4444)),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.image_outlined, size: 22, color: Color(0xFF94A3B8)),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'https://images.unsplash.com/... or paste image link',
                              hintStyle: const TextStyle(fontSize: 11),
                              isDense: true,
                              prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF94A3B8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Promotional Badge (None, Popular, Bestseller)
                  const Text('Badge / Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [null, 'Popular', 'Bestseller', 'Chef Special'].map((b) {
                      final isSelected = _selectedBadge == b;
                      return ChoiceChip(
                        label: Text(b ?? 'None', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF10B981),
                        onSelected: (_) => setState(() => _selectedBadge = b),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Availability Switch
                  SwitchListTile(
                    title: const Text('Available for Ordering', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _isAvailable ? 'Customers can order this dish' : 'Marked as Out of Stock',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                    value: _isAvailable,
                    activeThumbColor: const Color(0xFF10B981),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                  const SizedBox(height: 16),

                  // Save Action
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final imgUrl = _imageUrlController.text.trim();
                          final catId = (_selectedCatId.isNotEmpty && _selectedCatId != 'all')
                              ? _selectedCatId
                              : (currentCatVal ?? widget.initialDish?.categoryId ?? '');
                          final rawCode = _shortCodeController.text.trim();
                          final shortCode = rawCode.isNotEmpty ? rawCode.toUpperCase() : null;
                          final dish = PosMenuItem(
                            id: widget.initialDish?.id ?? '${DateTime.now().millisecondsSinceEpoch}',
                            name: _nameController.text.trim(),
                            shortCode: shortCode,
                            categoryId: catId,
                            price: double.parse(_priceController.text.trim()),
                            description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
                            imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
                            badge: _selectedBadge,
                            isAvailable: _isAvailable,
                            isVeg: _isVeg,
                          );
                          widget.onSave(dish);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.initialDish != null ? 'Update Food Item' : 'Add to Menu',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
