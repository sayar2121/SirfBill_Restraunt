import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;

  const CustomDateRangePicker({super.key, this.initialRange});

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  String _selectedPreset = 'Custom Range';
  List<DateTime?> _dates = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _dates = [widget.initialRange!.start, widget.initialRange!.end];
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      final now = DateTime.now();
      switch (preset) {
        case 'Today':
          _dates = [now, now];
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _dates = [startOfWeek, now];
          break;
        case 'This Month':
          final startOfMonth = DateTime(now.year, now.month, 1);
          _dates = [startOfMonth, now];
          break;
        case 'This Year':
          final startOfYear = DateTime(now.year, 1, 1);
          _dates = [startOfYear, now];
          break;
        case 'Custom Range':
          break;
      }
    });
  }

  Widget _buildSidebarItem(String label, {bool isMobile = false}) {
    final isSelected = _selectedPreset == label;
    return InkWell(
      onTap: () => _applyPreset(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isMobile ? null : double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 12,
        ),
        margin: EdgeInsets.only(bottom: isMobile ? 0 : 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF166534)
                : const Color(0xFF1E293B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    final sidebar = isDesktop
        ? SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarItem('Today'),
                _buildSidebarItem('This Week'),
                _buildSidebarItem('This Month'),
                _buildSidebarItem('This Year'),
                _buildSidebarItem('Custom Range'),
              ],
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSidebarItem('Today', isMobile: true),
                const SizedBox(width: 8),
                _buildSidebarItem('This Week', isMobile: true),
                const SizedBox(width: 8),
                _buildSidebarItem('This Month', isMobile: true),
                const SizedBox(width: 8),
                _buildSidebarItem('This Year', isMobile: true),
                const SizedBox(width: 8),
                _buildSidebarItem('Custom Range', isMobile: true),
              ],
            ),
          );

    final calendar = CalendarDatePicker2(
      config: CalendarDatePicker2Config(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: const Color(0xFF22C55E),
        weekdayLabelTextStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.bold,
        ),
        controlsTextStyle: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        dayTextStyle: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedRangeHighlightColor: const Color(0xFFDCFCE7),
      ),
      value: _dates,
      onValueChanged: (dates) {
        setState(() {
          _dates = dates;
          _selectedPreset = 'Custom Range';
        });
      },
    );

    final rightPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dates.isNotEmpty && _dates[0] != null
                        ? DateFormat('dd MMM yyyy').format(_dates[0]!)
                        : '--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('to', style: TextStyle(color: Color(0xFF22C55E))),
              ),
              Row(
                children: [
                  const SizedBox(width: 24),
                  Text(
                    _dates.length > 1 && _dates[1] != null
                        ? DateFormat('dd MMM yyyy').format(_dates[1]!)
                        : '--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_dates.isNotEmpty && _dates[0] != null) {
                    final end = _dates.length > 1 && _dates[1] != null
                        ? _dates[1]!
                        : _dates[0]!;
                    Navigator.pop(
                      context,
                      DateTimeRange(start: _dates[0]!, end: end),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: isDesktop ? 850 : MediaQuery.of(context).size.width * 0.95,
        height: isDesktop ? 450 : MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(isDesktop ? 24 : 8),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sidebar,
                  const VerticalDivider(color: Color(0xFFE2E8F0), width: 48),
                  Expanded(child: calendar),
                  const VerticalDivider(color: Color(0xFFE2E8F0), width: 48),
                  SizedBox(width: 200, child: rightPanel),
                ],
              )
            : Column(
                children: [
                  sidebar,
                  const Divider(color: Color(0xFFE2E8F0), height: 32),
                  Expanded(child: SingleChildScrollView(child: calendar)),
                  const Divider(color: Color(0xFFE2E8F0), height: 32),
                  rightPanel,
                ],
              ),
      ),
    );
  }
}
