import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../services/customer_service.dart';

import 'widgets/customers/customers_header.dart';
import 'widgets/customers/customers_summary_cards.dart';
import 'widgets/customers/customers_filter_bar.dart';
import 'widgets/customers/customers_table.dart';
import 'widgets/customers/customer_details_pane.dart';
import 'widgets/customers/customer_dialogs.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  Map<String, dynamic>? _selectedCustomer;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteCustomer(String customerId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: const Text(
            'Are you sure you want to delete this customer? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await CustomerService.deleteCustomer(customerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully')),
          );
          if (_selectedCustomer?['full_id'] == customerId) {
            setState(() {
              _selectedCustomer = null;
            });
          }
          ref.read(customerProvider.notifier).loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider);

    return customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allCustomers) {
        if (_selectedCustomer != null) {
          final updatedCust = allCustomers
              .where((c) => c['full_id'] == _selectedCustomer!['full_id'])
              .firstOrNull;
          if (updatedCust != null && updatedCust != _selectedCustomer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCustomer = updatedCust);
            });
          }
        }

        final filteredCustomers = allCustomers.where((c) {
          final matchesSearch =
              c['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c['phone'].toString().contains(_searchQuery) ||
              c['id'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          final matchesStatus =
              _selectedStatus == 'All Status' || c['status'] == _selectedStatus;
          final matchesCity =
              _selectedCity == 'All Cities' || c['city'] == _selectedCity;
          return matchesSearch && matchesStatus && matchesCity;
        }).toList();

        final totalRecords = filteredCustomers.length;
        final totalPages = (totalRecords / _itemsPerPage).ceil() == 0
            ? 1
            : (totalRecords / _itemsPerPage).ceil();
        final startIdx = (_currentPage - 1) * _itemsPerPage;
        final endIdx = (startIdx + _itemsPerPage > totalRecords)
            ? totalRecords
            : startIdx + _itemsPerPage;
        final pagedCustomers = filteredCustomers.isNotEmpty
            ? filteredCustomers.sublist(startIdx, endIdx)
            : <Map<String, dynamic>>[];

        final statuses = [
          'All Status',
          ...allCustomers.map((e) => e['status'].toString()).toSet(),
        ];
        final cities = [
          'All Cities',
          ...allCustomers.map((e) => e['city'].toString()).toSet(),
        ];

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;
              return ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Header
                  CustomersHeader(
                    filteredCustomers: filteredCustomers,
                    onRefresh: () =>
                        ref.read(customerProvider.notifier).loadCustomers(),
                    onAddCustomer: () => showAddCustomerDialog(
                      context,
                      () => ref.read(customerProvider.notifier).loadCustomers(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  CustomersSummaryCards(allCustomers: allCustomers),
                  const SizedBox(height: 24),

                  // Main Content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Table Area
                      if (isDesktop || _selectedCustomer == null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CustomersFilterBar(
                                  searchCtrl: _searchCtrl,
                                  selectedStatus: _selectedStatus,
                                  selectedCity: _selectedCity,
                                  statuses: statuses,
                                  cities: cities,
                                  onSearchChanged: (val) => setState(() {
                                    _searchQuery = val;
                                    _currentPage = 1;
                                  }),
                                  onStatusChanged: (val) => setState(() {
                                    _selectedStatus = val!;
                                    _currentPage = 1;
                                  }),
                                  onCityChanged: (val) => setState(() {
                                    _selectedCity = val!;
                                    _currentPage = 1;
                                  }),
                                  onReset: () => setState(() {
                                    _searchCtrl.clear();
                                    _searchQuery = '';
                                    _selectedStatus = 'All Status';
                                    _selectedCity = 'All Cities';
                                    _currentPage = 1;
                                  }),
                                ),
                                CustomersTable(
                                  pagedCustomers: pagedCustomers,
                                  selectedCustomer: _selectedCustomer,
                                  currentPage: _currentPage,
                                  totalPages: totalPages,
                                  totalRecords: totalRecords,
                                  startIdx: startIdx,
                                  endIdx: endIdx,
                                  onSelectCustomer: (customer) {
                                    setState(() {
                                      _selectedCustomer = customer;
                                    });
                                  },
                                  onDeleteCustomer: _deleteCustomer,
                                  onPageChanged: (page) =>
                                      setState(() => _currentPage = page),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Right Details Panel
                      if (_selectedCustomer != null) ...[
                        if (isDesktop) const SizedBox(width: 24),
                        isDesktop
                            ? SizedBox(
                                width: 320,
                                child: CustomerDetailsPane(
                                  customer: _selectedCustomer!,
                                  onClose: () =>
                                      setState(() => _selectedCustomer = null),
                                  onCustomerUpdated: () => ref
                                      .read(customerProvider.notifier)
                                      .loadCustomers(),
                                ),
                              )
                            : Expanded(
                                child: CustomerDetailsPane(
                                  customer: _selectedCustomer!,
                                  onClose: () =>
                                      setState(() => _selectedCustomer = null),
                                  onCustomerUpdated: () => ref
                                      .read(customerProvider.notifier)
                                      .loadCustomers(),
                                ),
                              ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
