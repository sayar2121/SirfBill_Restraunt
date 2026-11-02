import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ItemImagePicker extends StatelessWidget {
  final PlatformFile? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const ItemImagePicker({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Image',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPickImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
              ),
            ),
            child: selectedImage != null && selectedImage!.bytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          selectedImage!.bytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: onRemoveImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).cardColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: isDark
                            ? Colors.grey.shade500
                            : const Color(0xFF94A3B8),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Image',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
