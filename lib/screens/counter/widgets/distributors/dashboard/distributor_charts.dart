import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/distributor_provider.dart';

class DistributorCharts extends ConsumerWidget {
  final List<dynamic> distributors;
  const DistributorCharts({super.key, required this.distributors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(purchaseBillsProvider);
    final bills = billsAsync.value ?? [];
    
    // 1. Calculate monthly trend for the last 6 months
    final now = DateTime.now();
    final List<double> monthlyTotals = List.filled(6, 0.0);
    final List<String> monthLabels = List.filled(6, '');
    
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      monthLabels[5 - i] = monthNames[monthDate.month - 1];
    }
    
    for (var bill in bills) {
      final dateStr = bill['bill_date'];
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      
      final diffMonths = (now.year - date.year) * 12 + now.month - date.month;
      if (diffMonths >= 0 && diffMonths < 6) {
        final amount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
        monthlyTotals[5 - diffMonths] += amount;
      }
    }
    
    double maxYLine = 10000;
    for (var m in monthlyTotals) {
      if (m > maxYLine) maxYLine = m * 1.2;
    }

    // 2. Calculate top distributors
    final Map<String, double> distTotals = {};
    for (var bill in bills) {
      final did = bill['distributor_id'] as String?;
      if (did == null) continue;
      final amount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
      distTotals[did] = (distTotals[did] ?? 0.0) + amount;
    }
    
    final sortedDist = distTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final topDistIds = sortedDist.take(4).map((e) => e.key).toList();
    final topDistVals = sortedDist.take(4).map((e) => e.value).toList();
    
    // Fallback if less than 4
    while (topDistIds.length < 4) {
      topDistIds.add('');
      topDistVals.add(0.0);
    }
    
    double maxYBar = 10000;
    for (var v in topDistVals) {
      if (v > maxYBar) maxYBar = v * 1.2;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          return Flex(
            direction: isSmall ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) * 0.6,
                height: 350,
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Trend (Last 6 Months)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true, 
                            drawVerticalLine: false,
                            horizontalInterval: 20000,
                            getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  '${(value / 1000).toInt()}k',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < 6) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(monthLabels[value.toInt()], style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12)),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, monthlyTotals[0]),
                                FlSpot(1, monthlyTotals[1]),
                                FlSpot(2, monthlyTotals[2]),
                                FlSpot(3, monthlyTotals[3]),
                                FlSpot(4, monthlyTotals[4]),
                                FlSpot(5, monthlyTotals[5]),
                              ],
                              isCurved: true,
                              color: const Color(0xFF3B82F6),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmall) const SizedBox(width: 24),
              if (isSmall) const SizedBox(height: 24),
              Container(
                width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) * 0.4,
                height: 350,
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Distributors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                    const SizedBox(height: 24),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxYBar,
                          barTouchData: const BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final distId = topDistIds[value.toInt()];
                                  String name = 'N/A';
                                  if (distId.isNotEmpty) {
                                    final d = distributors.firstWhere((x) => x['id'] == distId, orElse: () => null);
                                    if (d != null) {
                                      name = d['name'] ?? 'Unknown';
                                      if (name.length > 8) name = name.substring(0, 8);
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      name,
                                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _buildBarGroup(context, 0, topDistVals[0], const Color(0xFF22C55E)),
                            _buildBarGroup(context, 1, topDistVals[1], const Color(0xFFF59E0B)),
                            _buildBarGroup(context, 2, topDistVals[2], const Color(0xFF8B5CF6)),
                            _buildBarGroup(context, 3, topDistVals[3], const Color(0xFFEC4899)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  BarChartGroupData _buildBarGroup(BuildContext context, int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
