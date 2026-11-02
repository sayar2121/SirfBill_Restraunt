import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_form_fields.dart';

class Step02AddressContactSection extends StatefulWidget {
  final TextEditingController addressLine1Ctrl;
  final TextEditingController addressLine2Ctrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController pinCodeCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController latLngCtrl;
  final Color textColor;

  const Step02AddressContactSection({
    super.key,
    required this.addressLine1Ctrl,
    required this.addressLine2Ctrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.pinCodeCtrl,
    required this.countryCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.latLngCtrl,
    required this.textColor,
  });

  @override
  State<Step02AddressContactSection> createState() => _Step02AddressContactSectionState();
}

class _Step02AddressContactSectionState extends State<Step02AddressContactSection> {
  // Indian States & Union Territories
  static const List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi (NCT)',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
    'Other',
  ];

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    final currentState = widget.stateCtrl.text.trim();
    if (currentState.isNotEmpty && _indianStates.contains(currentState)) {
      _selectedState = currentState;
    } else {
      _selectedState = 'West Bengal';
    }

    // Schedule initial text synchronization safely after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.stateCtrl.text.trim().isEmpty) {
          widget.stateCtrl.text = _selectedState!;
        }
      }
    });
  }

  void _onStateSelected(String? newState) {
    if (newState == null) return;
    setState(() {
      _selectedState = newState;
      widget.stateCtrl.text = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFormFieldWidgets.buildSectionHeader(
            '02. Address & Contact',
            'Physical location, state, city and public contact coordinates',
            Icons.location_on_rounded,
          ),
          const SizedBox(height: 16),
          AdminFormFieldWidgets.buildTextField(
            controller: widget.addressLine1Ctrl,
            label: 'Address Line 1 *',
            hint: 'Shop / Floor / Building name, Street name',
            icon: Icons.home_work_rounded,
            textColor: widget.textColor,
          ),
          const SizedBox(height: 14),
          AdminFormFieldWidgets.buildTextField(
            controller: widget.addressLine2Ctrl,
            label: 'Address Line 2 / Landmark',
            hint: 'Nearby landmark, mall name, floor number',
            icon: Icons.flag_rounded,
            textColor: widget.textColor,
          ),
          const SizedBox(height: 14),

          // City, State Dropdown & PIN Code Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City Text Input
              Expanded(
                flex: 3,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.cityCtrl,
                  label: 'City *',
                  hint: 'e.g. Kolkata / Mumbai',
                  icon: Icons.location_city_rounded,
                  textColor: widget.textColor,
                ),
              ),
              const SizedBox(width: 14),

              // State Dropdown
              Expanded(
                flex: 3,
                child: AdminFormFieldWidgets.buildDropdownField<String>(
                  value: _selectedState ?? 'West Bengal',
                  label: 'State / Union Territory *',
                  items: _indianStates,
                  onChanged: _onStateSelected,
                ),
              ),
              const SizedBox(width: 14),

              // PIN Code
              Expanded(
                flex: 2,
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.pinCodeCtrl,
                  label: 'PIN Code *',
                  hint: '700016',
                  icon: Icons.pin_drop_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textColor: widget.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.countryCtrl,
                  label: 'Country *',
                  hint: 'India',
                  icon: Icons.public_rounded,
                  textColor: widget.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.phoneCtrl,
                  label: 'Outlet Phone *',
                  hint: '9876543210',
                  icon: Icons.phone_rounded,
                  prefixText: '+91 ',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textColor: widget.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.emailCtrl,
                  label: 'Outlet Email (Optional)',
                  hint: 'branch1@restaurant.com',
                  icon: Icons.email_rounded,
                  textColor: widget.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminFormFieldWidgets.buildTextField(
                  controller: widget.latLngCtrl,
                  label: 'Latitude / Longitude (Optional for delivery)',
                  hint: 'e.g. 22.5726, 88.3639',
                  icon: Icons.my_location_rounded,
                  textColor: widget.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
