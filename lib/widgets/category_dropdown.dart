import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/counter_providers.dart';

class CategoryDropdown extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  ConsumerState<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends ConsumerState<CategoryDropdown> {
  @override
  void initState() {
    super.initState();
    // Riverpod handles fetching automatically upon watching
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final newCategory = await ref.read(categoryProvider.notifier).createCategory(
                  nameCtrl.text,
                  descriptionCtrl.text.isEmpty ? null : descriptionCtrl.text,
                );
                if (mounted) {
                  widget.onChanged(newCategory?.id);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add category: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryProvider);

    return categoryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const Text('Error loading categories'),
      data: (categories) {
        final sortedCategories = List.from(categories)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        
        final isValidValue = widget.selectedCategoryId == null || sortedCategories.any((c) => c.id == widget.selectedCategoryId);
        final safeValue = isValidValue ? widget.selectedCategoryId : null;

        return DropdownMenu<String?>(
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          enableSearch: true,
          hintText: 'Select Category',
          initialSelection: safeValue,
          onSelected: (value) {
            if (value == 'add_new') {
              _showAddCategoryDialog();
            } else {
              widget.onChanged(value);
            }
          },
          dropdownMenuEntries: [
            ...sortedCategories.map((cat) {
              final displayText = cat.description != null && cat.description!.isNotEmpty
                  ? '${cat.name} (${cat.description})'
                  : cat.name;
              return DropdownMenuEntry<String?>(
                value: cat.id,
                label: displayText,
                trailingIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Category'),
                        content: Text('Are you sure you want to delete "$displayText"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(categoryProvider.notifier).deleteCategory(cat.id);
                                if (widget.selectedCategoryId == cat.id) {
                                  widget.onChanged(null);
                                }
                                // ignore: use_build_context_synchronously
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete category: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
            const DropdownMenuEntry<String?>(
              value: 'add_new',
              label: 'Add New Category',
              leadingIcon: Icon(Icons.add, color: Color(0xFF22C55E)),
            ),
          ],
        );
      }, // close data:
    ); // close categoryAsync.when
  }
}
