import 'package:flutter/material.dart';

class CustomersFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String selectedStatus;
  final String selectedCity;
  final List<String> statuses;
  final List<String> cities;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCityChanged;
  final VoidCallback onReset;

  const CustomersFilterBar({
    super.key,
    required this.searchCtrl,
    required this.selectedStatus,
    required this.selectedCity,
    required this.statuses,
    required this.cities,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCityChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isDesktop
                    ? (constraints.maxWidth * 0.4)
                    : constraints.maxWidth,
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, customer ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: isDesktop
                    ? (constraints.maxWidth * 0.25 - 12)
                    : (constraints.maxWidth - 20) / 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                  initialValue: selectedStatus,
                  items: statuses
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: isDesktop
                    ? (constraints.maxWidth * 0.25 - 12)
                    : (constraints.maxWidth - 20) / 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                  initialValue: selectedCity,
                  items: cities
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                  onChanged: onCityChanged,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
