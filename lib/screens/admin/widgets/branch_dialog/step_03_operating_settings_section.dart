import 'package:flutter/material.dart';
import 'admin_form_fields.dart';

class Step03OperatingSettingsSection extends StatelessWidget {
  final String timeZone;
  final ValueChanged<String?> onTimeZoneChanged;
  final String currency;
  final ValueChanged<String?> onCurrencyChanged;
  final TextEditingController openingTimeCtrl;
  final TextEditingController closingTimeCtrl;
  final String weeklyClosing;
  final ValueChanged<String?> onWeeklyClosingChanged;
  final bool enableDineIn;
  final ValueChanged<bool> onEnableDineInChanged;
  final bool enableTakeaway;
  final ValueChanged<bool> onEnableTakeawayChanged;
  final bool enableDelivery;
  final ValueChanged<bool> onEnableDeliveryChanged;
  final bool isPrimary;
  final ValueChanged<bool?> onIsPrimaryChanged;
  final Color textColor;
  final Color subtitleColor;

  const Step03OperatingSettingsSection({
    super.key,
    required this.timeZone,
    required this.onTimeZoneChanged,
    required this.currency,
    required this.onCurrencyChanged,
    required this.openingTimeCtrl,
    required this.closingTimeCtrl,
    required this.weeklyClosing,
    required this.onWeeklyClosingChanged,
    required this.enableDineIn,
    required this.onEnableDineInChanged,
    required this.enableTakeaway,
    required this.onEnableTakeawayChanged,
    required this.enableDelivery,
    required this.onEnableDeliveryChanged,
    required this.isPrimary,
    required this.onIsPrimaryChanged,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFormFieldWidgets.buildSectionHeader(
            '03. Operating Settings',
            'Business hours, local currency & ordering channels',
            Icons.schedule_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: timeZone,
                  label: 'Time Zone',
                  items: const [
                    'Asia/Kolkata (IST +5:30)',
                    'Asia/Dubai (GST +4:00)',
                    'UTC (GMT +0:00)',
                  ],
                  onChanged: onTimeZoneChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: currency,
                  label: 'Operating Currency',
                  items: const ['INR (₹)', 'USD (\$)', 'AED (د.إ)', 'EUR (€)'],
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: openingTimeCtrl,
                  label: 'Opening Time',
                  hint: '09:00 AM',
                  icon: Icons.wb_sunny_rounded,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: closingTimeCtrl,
                  label: 'Closing Time',
                  hint: '11:00 PM',
                  icon: Icons.nightlight_round,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: weeklyClosing,
                  label: 'Weekly Off / Closing Day',
                  items: const [
                    'None (Open 7 Days)',
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ],
                  onChanged: onWeeklyClosingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Default Order Types Enabled',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              AdminFormFieldWidgets.buildChannelChip('Dine-In', enableDineIn, onEnableDineInChanged),
              AdminFormFieldWidgets.buildChannelChip('Takeaway', enableTakeaway, onEnableTakeawayChanged),
              AdminFormFieldWidgets.buildChannelChip('Delivery', enableDelivery, onEnableDeliveryChanged),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isPrimary,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: onIsPrimaryChanged,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set as Primary HQ Outlet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                      Text(
                        'When checked, this branch will be selected as default in reports and newly generated registers.',
                        style: TextStyle(fontSize: 11, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
