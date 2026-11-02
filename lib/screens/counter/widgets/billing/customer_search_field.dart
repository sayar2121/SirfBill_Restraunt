import 'package:flutter/material.dart';
import '../../../../models/counter_models.dart';

class CustomerSearchField extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<Customer> allCustomers;
  final Function(Customer) onCustomerSelected;

  const CustomerSearchField({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.allCustomers,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Customer',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: RawAutocomplete<Customer>(
            textEditingController: searchController,
            focusNode: searchFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Customer>.empty();
              }
              final matches = allCustomers.where((Customer customer) {
                return customer.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ) ||
                    customer.phone.contains(textEditingValue.text);
              });

              if (matches.isEmpty) {
                return [
                  Customer(
                    id: 'NO_DATA',
                    name: 'No data found',
                    phone: '',
                    location: '',
                    createdAt: DateTime.now().toIso8601String(),
                  ),
                ];
              }

              return matches;
            },
            displayStringForOption: (Customer option) => option.id == 'NO_DATA'
                ? searchController.text
                : option.name,
            onSelected: onCustomerSelected,
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  isDense: true,
                  hintText: 'Type name or phone number...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);

                        if (option.id == 'NO_DATA') {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No data found',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            // Hide options after selection
                            FocusScope.of(context).unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  option.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  option.phone,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
