import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';
import '../../../../widgets/custom_pagination.dart';
import 'customer_components.dart';

class CustomersTable extends StatelessWidget {
  final List<Map<String, dynamic>> pagedCustomers;
  final Map<String, dynamic>? selectedCustomer;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int startIdx;
  final int endIdx;
  final ValueChanged<Map<String, dynamic>> onSelectCustomer;
  final ValueChanged<String> onDeleteCustomer;
  final ValueChanged<int> onPageChanged;

  const CustomersTable({
    super.key,
    required this.pagedCustomers,
    required this.selectedCustomer,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.startIdx,
    required this.endIdx,
    required this.onSelectCustomer,
    required this.onDeleteCustomer,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 1000,
                  maxWidth: constraints.maxWidth > 1000
                      ? constraints.maxWidth
                      : 1000,
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '#',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Customer Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Phone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'City',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total Purchases',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Last Purchase',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text(
                              'Action',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Body
                    pagedCustomers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No customers found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagedCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = pagedCustomers[index];
                              return _buildCustomerRow(
                                context,
                                customer,
                                index,
                                isDark,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

            // Pagination
            if (totalRecords > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIdx + 1} to $endIdx of $totalRecords customers',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    CustomPagination(
                      currentPage: currentPage,
                      totalPages: totalPages,
                      onPageChanged: onPageChanged,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerRow(
    BuildContext context,
    Map<String, dynamic> customer,
    int index,
    bool isDark,
  ) {
    final isSelected = selectedCustomer?['id'] == customer['id'];

    return InkWell(
      onTap: () => onSelectCustomer(customer),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF166534) : AppColors.primaryLight)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CustomerAvatar(initials: customer['initials'] ?? ''),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: customer['name'] ?? '',
                          child: Text(
                            customer['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          customer['id'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['phone'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['city'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${((customer['totalPurchases'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${customer['bills'] ?? 0} bills',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['lastPurchase'] ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomerStatusChip(status: customer['status'] ?? 'Active'),
              ),
            ),
            SizedBox(
              width: 130,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => onSelectCustomer(customer),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => onDeleteCustomer(customer['full_id'] ?? ''),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Customer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
