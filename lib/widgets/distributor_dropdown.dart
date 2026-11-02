import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/distributor_provider.dart';

class DistributorDropdown extends ConsumerWidget {
  final String? selectedDistributorId;
  final ValueChanged<String?> onChanged;

  const DistributorDropdown({
    super.key,
    required this.selectedDistributorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributorsAsync = ref.watch(distributorsProvider);

    return distributorsAsync.when(
      data: (distributors) {
        final sortedDistributors = List.from(distributors)
          ..sort((a, b) => (a['name'].toString()).toLowerCase().compareTo((b['name'].toString()).toLowerCase()));

        return DropdownMenu<String?>(
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          enableSearch: true,
          hintText: 'Select a Distributor',
          initialSelection: selectedDistributorId,
          onSelected: onChanged,
          dropdownMenuEntries: [
            const DropdownMenuEntry<String?>(
              value: null,
              label: 'Select a Distributor',
            ),
            ...sortedDistributors.map((d) {
              return DropdownMenuEntry<String?>(
                value: d['id'].toString(),
                label: d['name'].toString(),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator())),
      error: (err, stack) => Text('Error loading distributors: $err'),
    );
  }
}
