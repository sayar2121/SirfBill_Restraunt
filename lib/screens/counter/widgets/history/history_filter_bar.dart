import 'package:flutter/material.dart';
import '../../../../widgets/custom_date_range_picker.dart';

class HistoryFilterBar extends StatelessWidget {
  final String activeDateRange;
  final String selectedType;
  final String selectedPaymentMode;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onPaymentModeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReset;

  const HistoryFilterBar({
    super.key,
    required this.activeDateRange,
    required this.selectedType,
    required this.selectedPaymentMode,
    required this.customDateRange,
    required this.onDateRangeChanged,
    required this.onCustomDateRangeChanged,
    required this.onTypeChanged,
    required this.onPaymentModeChanged,
    required this.onSearchChanged,
    required this.onReset,
  });

  Widget _buildDateRangeBtn(BuildContext context, String title, bool isCustom) {
    final isActive = activeDateRange == title;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        if (isCustom) {
          final DateTimeRange? picked = await showDialog<DateTimeRange>(
            context: context,
            builder: (context) => const CustomDateRangePicker(),
          );
          if (picked != null) {
            onCustomDateRangeChanged(picked);
            onDateRangeChanged(title);
          }
        } else {
          onDateRangeChanged(title);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF22C55E) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (isCustom) ...[
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : const Color(0xFF1E293B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : const Color(0xFF1E293B)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
    BuildContext context,
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                size: 18,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13,
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 1000;

        Widget dateRangePickerSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  _buildDateRangeBtn(context, 'Today', false),
                  _buildDateRangeBtn(context, 'This Week', false),
                  _buildDateRangeBtn(context, 'This Month', false),
                  _buildDateRangeBtn(context, 'This Year', false),
                  VerticalDivider(
                    width: 16,
                    color: Theme.of(context).dividerColor,
                  ),
                  _buildDateRangeBtn(context, 'Custom Range', true),
                ],
              ),
            ),
          ],
        );

        Widget searchField = Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Search by bill no, customer name, phone...',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

        Widget resetButton = OutlinedButton.icon(
          onPressed: onReset,
          icon: Icon(
            Icons.clear,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 16,
          ),
          label: Text(
            'Reset Filters',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              dateRangePickerSection,
              const SizedBox(width: 16),
              _buildDropdownFilter(
                context,
                'Transaction Type',
                ['All', 'Sale', 'Return', 'Adjustment', 'Purchase'],
                selectedType,
                (v) => onTypeChanged(v!),
              ),
              const SizedBox(width: 16),
              _buildDropdownFilter(
                context,
                'Payment Mode',
                ['All', 'Cash', 'UPI', 'Card', 'Bank Transfer'],
                selectedPaymentMode,
                (v) => onPaymentModeChanged(v!),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    searchField,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  resetButton,
                ],
              ),
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              dateRangePickerSection,
              const SizedBox(width: 16),
              _buildDropdownFilter(
                context,
                'Transaction Type',
                ['All', 'Sale', 'Return', 'Adjustment', 'Purchase'],
                selectedType,
                (v) => onTypeChanged(v!),
              ),
              const SizedBox(width: 16),
              _buildDropdownFilter(
                context,
                'Payment Mode',
                ['All', 'Cash', 'UPI', 'Card', 'Bank Transfer'],
                selectedPaymentMode,
                (v) => onPaymentModeChanged(v!),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    searchField,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  resetButton,
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
