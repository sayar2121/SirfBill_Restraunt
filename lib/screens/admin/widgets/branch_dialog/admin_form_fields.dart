import 'package:flutter/material.dart';

class AdminFormFieldWidgets {
  static Widget buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textColor,
    bool readOnly = false,
    int maxLines = 1,
    String? prefixText,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters != null ? List.castFrom(inputFormatters) : null,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 18),
        prefixText: prefixText,
        prefixStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  static Widget buildDropdownField<T>({
    required T value,
    required String label,
    required List<String> items,
    required ValueChanged<T?> onChanged,
  }) {
    // Ensure the initial value is present among items to prevent Flutter assertion errors
    final effectiveItems = items.contains(value) ? items : [value as String, ...items];
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: effectiveItems
          .map((item) => DropdownMenuItem(
                value: item as T,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  static Widget buildChannelChip(String label, bool isSelected, ValueChanged<bool> onToggle) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onToggle,
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
