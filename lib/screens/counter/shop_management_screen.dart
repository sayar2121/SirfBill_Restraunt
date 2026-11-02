import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/shop_service.dart';
import 'widgets/shop/multi_branch_teaser_card.dart';
import 'widgets/shop/shop_filter_bar.dart';
import 'widgets/shop/shop_form_dialog.dart';
import 'widgets/shop/shop_header.dart';
import 'widgets/shop/shop_summary_cards.dart';
import 'widgets/shop/shop_table.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  List<Shop> _shops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  bool _sortAscending = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadShops();
    // Poll for realtime updates every 3 seconds silently
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadShops(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadShops({bool silent = false}) async {
    try {
      final shops = await ShopService.getShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shops: $e')),
        );
      }
    }
  }

  void _showAddShopDialog() {
    ShopFormDialog.show(
      context,
      onSaved: _loadShops,
    );
  }

  void _showEditShopDialog(Shop shop) {
    ShopFormDialog.show(
      context,
      shop: shop,
      onSaved: _loadShops,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredShops = _shops.where((s) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = s.name.toLowerCase().contains(query) ||
          s.code.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == 'All Status' ||
          s.status.toLowerCase() == _selectedStatus.toLowerCase();
      final matchesCity = _selectedCity == 'All Cities' ||
          s.city.toLowerCase() == _selectedCity.toLowerCase();
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();

    filteredShops.sort((a, b) =>
        _sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final activeCount = _shops.where((s) => s.status.toLowerCase() == 'active').length;
    final inactiveCount = _shops.length - activeCount;

    final allCities = [
      'All Cities',
      ..._shops.map((s) => s.city).toSet(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Export and Add Actions
            ShopHeader(
              isDark: isDark,
              shops: _shops,
              onRefresh: () {
                setState(() => _isLoading = true);
                _loadShops();
              },
              onAddShop: _showAddShopDialog,
            ),
            const SizedBox(height: 32),

            // Summary Cards Component
            ShopSummaryCards(
              totalShops: _shops.length,
              activeShops: activeCount,
              inactiveShops: inactiveCount,
              totalLocations: _shops.map((s) => s.city).toSet().length,
            ),
            const SizedBox(height: 32),

            // Main Content Area
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  // Filter Toolbar
                  ShopFilterBar(
                    isDark: isDark,
                    searchQuery: _searchQuery,
                    selectedStatus: _selectedStatus,
                    selectedCity: _selectedCity,
                    sortAscending: _sortAscending,
                    allCities: allCities,
                    onSearchChanged: (val) => setState(() => _searchQuery = val),
                    onStatusChanged: (val) => setState(() => _selectedStatus = val),
                    onCityChanged: (val) => setState(() => _selectedCity = val),
                    onToggleSort: () => setState(() => _sortAscending = !_sortAscending),
                  ),

                  // Table Component
                  ShopTable(
                    shops: filteredShops,
                    isLoading: _isLoading,
                    onEdit: _showEditShopDialog,
                  ),

                  const SizedBox(height: 48),

                  // Multi-Branch Management Teaser
                  MultiBranchTeaserCard(isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
