import 'package:flutter/material.dart';

class AccountsTabsCard extends StatelessWidget {
  final int activeTab;
  final List<String> tabs;
  final ValueChanged<int> onTabChanged;
  final Widget child;

  const AccountsTabsCard({
    super.key,
    required this.activeTab,
    required this.tabs,
    required this.onTabChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Tabs Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  tabs.length,
                  (index) => InkWell(
                    onTap: () => onTabChanged(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: activeTab == index
                                ? const Color(0xFF22C55E)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: activeTab == index
                              ? (isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF166534))
                              : (isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF1E293B)),
                          fontWeight: activeTab == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tab Content
          child,
        ],
      ),
    );
  }
}
