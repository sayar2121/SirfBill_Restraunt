import 'package:flutter/material.dart';

/// Filter & search toolbar for shops list.
class ShopFilterBar extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final String selectedStatus;
  final String selectedCity;
  final bool sortAscending;
  final List<String> allCities;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onToggleSort;

  const ShopFilterBar({
    super.key,
    required this.isDark,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedCity,
    required this.sortAscending,
    required this.allCities,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCityChanged,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search shop by name, code, location...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                items: ['All Status', 'Active', 'Inactive'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onStatusChanged(v);
                },
              ),
            ),
          ),
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCity,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                items: allCities.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onCityChanged(v);
                },
              ),
            ),
          ),
          InkWell(
            onTap: onToggleSort,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sort By: NAME',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
