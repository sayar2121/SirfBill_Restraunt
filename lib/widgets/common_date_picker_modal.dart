import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'common_filter_pills.dart';

/// Reusable Date Picker Modal with quick presets and calendar pickers
class CommonDatePickerModal extends StatefulWidget {
  final DateTimeRange initialRange;
  final ValueChanged<DateTimeRange> onApply;

  const CommonDatePickerModal({
    super.key,
    required this.initialRange,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTimeRange initialRange,
    required ValueChanged<DateTimeRange> onApply,
    required void Function(DateRangePreset preset) onSelectPreset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CommonDatePickerModal(
            initialRange: initialRange,
            onApply: (range) {
              onApply(range);
              onSelectPreset(DateRangePreset.custom);
            },
          ),
        ),
      ),
    );
  }

  @override
  State<CommonDatePickerModal> createState() => _CommonDatePickerModalState();
}

class _CommonDatePickerModalState extends State<CommonDatePickerModal> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialRange.start;
    _toDate = widget.initialRange.end;
  }

  String _fmt(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardInner = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date Range',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Filter reports & records by custom period',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Presets & Dates
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK PRESETS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickChip('Today', () {
                    setState(() {
                      _fromDate = DateTime(now.year, now.month, now.day);
                      _toDate = now;
                    });
                  }, isDark),
                  _buildQuickChip('Yesterday', () {
                    final y = now.subtract(const Duration(days: 1));
                    setState(() {
                      _fromDate = DateTime(y.year, y.month, y.day);
                      _toDate = DateTime(y.year, y.month, y.day, 23, 59, 59);
                    });
                  }, isDark),
                  _buildQuickChip('Last 7 Days', () {
                    setState(() {
                      _fromDate = now.subtract(const Duration(days: 7));
                      _toDate = now;
                    });
                  }, isDark),
                  _buildQuickChip('Last 30 Days', () {
                    setState(() {
                      _fromDate = now.subtract(const Duration(days: 30));
                      _toDate = now;
                    });
                  }, isDark),
                  _buildQuickChip('This Month', () {
                    setState(() {
                      _fromDate = DateTime(now.year, now.month, 1);
                      _toDate = now;
                    });
                  }, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Date Selectors
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardInner,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fromDate,
                            firstDate: DateTime(2020),
                            lastDate: _toDate,
                          );
                          if (picked != null) {
                            setState(() => _fromDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'START DATE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: textMuted),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _fmt(_fromDate),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF10B981)),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _toDate,
                            firstDate: _fromDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'END DATE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: textMuted),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _fmt(_toDate),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onApply(DateTimeRange(start: _fromDate, end: _toDate));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.filter_alt_rounded, size: 16),
                    label: const Text('Apply Date Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

