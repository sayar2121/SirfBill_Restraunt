import 'package:flutter/material.dart';
import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';

class ItemWiseSalesTab extends StatefulWidget {
  final List<TopSellingDish> topDishes;
  final SalesReportSummary? summary;
  final List<RestaurantOrder> orders;

  const ItemWiseSalesTab({
    super.key,
    required this.topDishes,
    this.summary,
    this.orders = const [],
  });

  @override
  State<ItemWiseSalesTab> createState() => _ItemWiseSalesTabState();
}

class _ItemWiseSalesTabState extends State<ItemWiseSalesTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'revenue'; // 'revenue', 'quantity', 'price'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _resolveCategory(String name, String rawCat) {
    if (rawCat.isNotEmpty &&
        rawCat != 'all' &&
        rawCat != 'Dishes' &&
        !rawCat.contains('-')) {
      return rawCat;
    }
    final n = name.toLowerCase();
    if (n.contains('tikka') ||
        n.contains('kebab') ||
        n.contains('starter') ||
        n.contains('paneer tikka') ||
        n.contains('chicken tikka') ||
        n.contains('tandoor')) {
      return 'Tandoor & Starters';
    }
    if (n.contains('biryani') ||
        n.contains('biriyani') ||
        n.contains('rice') ||
        n.contains('pulao')) {
      return 'Biryani & Rice';
    }
    if (n.contains('pizza') ||
        n.contains('burger') ||
        n.contains('sandwich') ||
        n.contains('pasta') ||
        n.contains('roll') ||
        n.contains('fries')) {
      return 'Fast Food & Snacks';
    }
    if (n.contains('dal') ||
        n.contains('curry') ||
        n.contains('butter') ||
        n.contains('korma') ||
        n.contains('paneer') ||
        n.contains('masala') ||
        n.contains('mutton') ||
        n.contains('gravy') ||
        n.contains('tadka')) {
      return 'Main Course';
    }
    if (n.contains('naan') ||
        n.contains('roti') ||
        n.contains('paratha') ||
        n.contains('kulcha') ||
        n.contains('bread')) {
      return 'Breads';
    }
    if (n.contains('tea') ||
        n.contains('coffee') ||
        n.contains('shake') ||
        n.contains('lassi') ||
        n.contains('drink') ||
        n.contains('water') ||
        n.contains('beverage') ||
        n.contains('juice') ||
        n.contains('soda')) {
      return 'Beverages';
    }
    if (n.contains('ice cream') ||
        n.contains('sweet') ||
        n.contains('gulab') ||
        n.contains('halwa') ||
        n.contains('dessert') ||
        n.contains('kheer')) {
      return 'Desserts';
    }
    return 'Specialties';
  }

  bool _isVeg(String name) {
    final n = name.toLowerCase();
    if (n.contains('chicken') ||
        n.contains('mutton') ||
        n.contains('fish') ||
        n.contains('egg') ||
        n.contains('prawn') ||
        n.contains('meat') ||
        n.contains('beef') ||
        n.contains('pork') ||
        n.contains('lamb')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final allDishes = widget.topDishes;
    final totalSoldQuantity = allDishes.fold<int>(0, (sum, d) => sum + d.quantitySold);
    final totalDishesRevenue = allDishes.fold<double>(0, (sum, d) => sum + d.revenue);
    final avgPricePerItem = totalSoldQuantity > 0 ? (totalDishesRevenue / totalSoldQuantity) : 0.0;
    final starDish = allDishes.isNotEmpty ? allDishes.first : null;

    // Filter dishes by search and category
    List<TopSellingDish> filtered = allDishes.where((d) {
      final matchesSearch = d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.category.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Veg') return _isVeg(d.name);
      if (_selectedCategory == 'Non-Veg') return !_isVeg(d.name);
      return _resolveCategory(d.name, d.category) == _selectedCategory;
    }).toList();

    // Sort dishes
    if (_sortBy == 'quantity') {
      filtered.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    } else if (_sortBy == 'price') {
      filtered.sort((a, b) {
        final priceA = a.quantitySold > 0 ? (a.revenue / a.quantitySold) : 0.0;
        final priceB = b.quantitySold > 0 ? (b.revenue / b.quantitySold) : 0.0;
        return priceB.compareTo(priceA);
      });
    } else {
      filtered.sort((a, b) => b.revenue.compareTo(a.revenue));
    }

    // Category aggregation
    final Map<String, (int qty, double rev)> categoryAgg = {};
    for (final d in allDishes) {
      final cat = _resolveCategory(d.name, d.category);
      if (categoryAgg.containsKey(cat)) {
        final cur = categoryAgg[cat]!;
        categoryAgg[cat] = (cur.$1 + d.quantitySold, cur.$2 + d.revenue);
      } else {
        categoryAgg[cat] = (d.quantitySold, d.revenue);
      }
    }
    final sortedCategories = categoryAgg.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    // Available categories for filter pills
    final availableCategories = ['All', 'Veg', 'Non-Veg', ...sortedCategories.map((e) => e.key)];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Executive Metrics Strip (4 Stat Cards)
          _buildMetricsStrip(
            isDark: isDark,
            totalQuantity: totalSoldQuantity,
            totalRevenue: totalDishesRevenue,
            starDish: starDish,
            avgPrice: avgPricePerItem,
          ),
          const SizedBox(height: 20),

          // 2. Interactive Search & Filter Controls
          _buildFilterBar(
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            availableCategories: availableCategories,
          ),
          const SizedBox(height: 20),

          // 3. Responsive Dual-Card Layout: Leaderboard & Insights
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 980;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Leaderboard Table (Flex 3)
                    Expanded(
                      flex: 3,
                      child: _buildLeaderboardCard(
                        context,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        dishes: filtered,
                        totalRevenue: totalDishesRevenue,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Insights Column (Flex 2)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildCategoryBreakdownCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            categories: sortedCategories,
                            totalRevenue: totalDishesRevenue,
                          ),
                          const SizedBox(height: 20),
                          _buildKitchenIntelligenceCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            dishes: allDishes,
                            totalRevenue: totalDishesRevenue,
                            totalQuantity: totalSoldQuantity,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Tablet / Mobile: Stacked Layout
              return Column(
                children: [
                  _buildLeaderboardCard(
                    context,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    dishes: filtered,
                    totalRevenue: totalDishesRevenue,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryBreakdownCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    categories: sortedCategories,
                    totalRevenue: totalDishesRevenue,
                  ),
                  const SizedBox(height: 20),
                  _buildKitchenIntelligenceCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    dishes: allDishes,
                    totalRevenue: totalDishesRevenue,
                    totalQuantity: totalSoldQuantity,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. TOP METRICS STRIP
  // =========================================================================
  Widget _buildMetricsStrip({
    required bool isDark,
    required int totalQuantity,
    required double totalRevenue,
    required TopSellingDish? starDish,
    required double avgPrice,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w < 600 ? 1 : (w < 1100 ? 2 : 4);
        final aspect = w < 600 ? 2.6 : (w < 1100 ? 2.3 : 1.95);

        final items = [
          _MetricCardData(
            title: 'Culinary Menu Revenue',
            value: '₹${totalRevenue.toStringAsFixed(0)}',
            subtitle: 'Gross revenue from dish sales',
            badge: 'Menu Sales',
            icon: Icons.currency_rupee_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            accentColor: const Color(0xFF10B981),
          ),
          _MetricCardData(
            title: 'Total Portions Sold',
            value: '$totalQuantity plates',
            subtitle: 'Culinary order volume',
            badge: 'Total Volume',
            icon: Icons.restaurant_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            accentColor: const Color(0xFF6366F1),
          ),
          _MetricCardData(
            title: 'Star Menu Performer',
            value: starDish != null ? starDish.name : 'N/A',
            subtitle: starDish != null
                ? '₹${starDish.revenue.toStringAsFixed(0)} (${totalRevenue > 0 ? ((starDish.revenue / totalRevenue) * 100).toStringAsFixed(1) : 0}%)'
                : 'No sales yet',
            badge: '#1 Leader',
            icon: Icons.emoji_events_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            accentColor: const Color(0xFFF59E0B),
          ),
          _MetricCardData(
            title: 'Average Unit Realization',
            value: '₹${avgPrice.toStringAsFixed(1)}',
            subtitle: 'Realized price per portion',
            badge: 'Per Plate ASP',
            icon: Icons.receipt_long_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            accentColor: const Color(0xFF0EA5E9),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final card = items[idx];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: card.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: card.accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(card.icon, color: Colors.white, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: card.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          card.badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: card.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 2. INTERACTIVE FILTER BAR
  // =========================================================================
  Widget _buildFilterBar({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required List<String> availableCategories,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search dishes by name (e.g. Biryani, Tikka)...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Sort Option Dropdown
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF10B981)),
                    items: const [
                      DropdownMenuItem(value: 'revenue', child: Text('Sort: Gross Revenue')),
                      DropdownMenuItem(value: 'quantity', child: Text('Sort: Quantity Sold')),
                      DropdownMenuItem(value: 'price', child: Text('Sort: Unit Price (ASP)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Quick-Pills Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : borderColor,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. MAIN LEADERBOARD CARD
  // =========================================================================
  Widget _buildLeaderboardCard(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required List<TopSellingDish> dishes,
    required double totalRevenue,
  }) {
    final maxRevenue = dishes.fold<double>(0, (prev, e) => e.revenue > prev ? e.revenue : prev);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.leaderboard_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Performer Menu Leaderboard',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        'Ranked by ${_sortBy == "quantity" ? "kitchen orders sold" : (_sortBy == "price" ? "average price realization" : "gross sales revenue")}',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${dishes.length} Items Listed',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    '#',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DISH & CATEGORY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'SHARE OF REVENUE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'QTY SOLD',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 90,
                  child: Text(
                    'GROSS SALES',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Empty state
          if (dishes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: subtextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'No menu items matched your filter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subtextColor),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dishes.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                final dish = dishes[index];
                final revRatio = maxRevenue > 0 ? (dish.revenue / maxRevenue).clamp(0.0, 1.0) : 0.0;
                final revPercent = totalRevenue > 0 ? ((dish.revenue / totalRevenue) * 100) : 0.0;
                final resolvedCat = _resolveCategory(dish.name, dish.category);
                final isDishVeg = _isVeg(dish.name);
                final unitPrice = dish.quantitySold > 0 ? (dish.revenue / dish.quantitySold) : 0.0;

                // Rank badge styling
                Color badgeBg;
                Color badgeText;
                Widget? trophyIcon;
                if (index == 0) {
                  badgeBg = const Color(0xFFFEF3C7);
                  badgeText = const Color(0xFFD97706);
                  trophyIcon = const Icon(Icons.emoji_events_rounded, size: 15, color: Color(0xFFD97706));
                } else if (index == 1) {
                  badgeBg = const Color(0xFFF1F5F9);
                  badgeText = const Color(0xFF475569);
                  trophyIcon = const Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFF64748B));
                } else if (index == 2) {
                  badgeBg = const Color(0xFFFFEDD5);
                  badgeText = const Color(0xFFC2410C);
                  trophyIcon = const Icon(Icons.military_tech_rounded, size: 15, color: Color(0xFFC2410C));
                } else {
                  badgeBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
                  badgeText = const Color(0xFF94A3B8);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      // Rank Icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: badgeBg),
                        child: Center(
                          child: trophyIcon ??
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: badgeText,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Dish Details
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            // Veg / Non-Veg Icon
                            _buildFoodSymbol(isDishVeg),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dish.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          resolvedCat,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '₹${unitPrice.toStringAsFixed(0)} / unit',
                                        style: TextStyle(fontSize: 10, color: subtextColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Revenue Share Progress Bar
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: revRatio,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    index == 0
                                        ? const Color(0xFF10B981)
                                        : (index == 1
                                            ? const Color(0xFF0EA5E9)
                                            : (index == 2 ? const Color(0xFFF59E0B) : const Color(0xFF64748B))),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${revPercent.toStringAsFixed(1)}% of total sales',
                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Qty Sold
                      SizedBox(
                        width: 70,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${dish.quantitySold}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const Text(
                              'plates',
                              style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Gross Revenue
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${dish.revenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const Text(
                              'revenue',
                              style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. CATEGORY BREAKDOWN CARD
  // =========================================================================
  Widget _buildCategoryBreakdownCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required List<MapEntry<String, (int qty, double rev)>> categories,
    required double totalRevenue,
  }) {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF0EA5E9),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Sales Mix',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      'Volume & revenue contribution by menu category',
                      style: TextStyle(fontSize: 10.5, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Categories List
          if (categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No category data available', style: TextStyle(color: subtextColor, fontSize: 12)),
              ),
            )
          else
            ...categories.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final color = colors[idx % colors.length];
              final share = totalRevenue > 0 ? ((cat.value.$2 / totalRevenue) * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat.key,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${cat.value.$2.toStringAsFixed(0)} (${share.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (share / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. KITCHEN & CULINARY INTELLIGENCE CARD
  // =========================================================================
  Widget _buildKitchenIntelligenceCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required List<TopSellingDish> dishes,
    required double totalRevenue,
    required int totalQuantity,
  }) {
    final top3Rev = dishes.take(3).fold<double>(0, (sum, d) => sum + d.revenue);
    final top3Percent = totalRevenue > 0 ? ((top3Rev / totalRevenue) * 100) : 0.0;
    final star = dishes.isNotEmpty ? dishes.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitchen Velocity & Insights',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      'Executive culinary engineering highlights',
                      style: TextStyle(fontSize: 10.5, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Insight 1: Revenue Concentration
          _buildInsightRow(
            icon: Icons.stacked_line_chart_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Revenue Concentration',
            description: top3Percent > 0
                ? 'Top 3 dishes generate ${top3Percent.toStringAsFixed(1)}% of total kitchen revenue.'
                : 'Balanced menu distribution across active items.',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 12),

          // Insight 2: Star Volume Driver
          if (star != null)
            _buildInsightRow(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Primary Star Performer',
              description:
                  '${star.name} is your highest grossing dish with ${star.quantitySold} portions sold totaling ₹${star.revenue.toStringAsFixed(0)}.',
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
          const SizedBox(height: 12),

          // Insight 3: Kitchen Recommendation
          _buildInsightRow(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Kitchen Prep Recommendation',
            description:
                'Ensure prep stations for ${star?.name ?? "high-demand items"} are stocked before peak lunch & dinner rush hours.',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: subtextColor, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Veg / Non-Veg badge symbol
  Widget _buildFoodSymbol(bool isVeg) {
    final symbolColor = isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: symbolColor, width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: symbolColor,
            shape: isVeg ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}
