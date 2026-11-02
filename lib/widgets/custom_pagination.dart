import 'package:flutter/material.dart';

class CustomPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const CustomPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    // Previous Button
    pageButtons.add(
      _buildPaginationBtn(context, 
        icon: Icons.chevron_left,
        isActive: false,
        onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
      ),
    );

    // Page Numbers logic
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pageButtons.add(
          _buildPaginationBtn(context, 
            text: '$i',
            isActive: currentPage == i,
            onTap: () => onPageChanged(i),
          ),
        );
      }
    } else {
      if (currentPage <= 4) {
        for (int i = 1; i <= 5; i++) {
          pageButtons.add(
            _buildPaginationBtn(context, 
              text: '$i',
              isActive: currentPage == i,
              onTap: () => onPageChanged(i),
            ),
          );
        }
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        pageButtons.add(
          _buildPaginationBtn(context, 
            text: '$totalPages',
            isActive: currentPage == totalPages,
            onTap: () => onPageChanged(totalPages),
          ),
        );
      } else if (currentPage >= totalPages - 3) {
        pageButtons.add(
          _buildPaginationBtn(context, 
            text: '1',
            isActive: currentPage == 1,
            onTap: () => onPageChanged(1),
          ),
        );
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pageButtons.add(
            _buildPaginationBtn(context, 
              text: '$i',
              isActive: currentPage == i,
              onTap: () => onPageChanged(i),
            ),
          );
        }
      } else {
        pageButtons.add(
          _buildPaginationBtn(context, 
            text: '1',
            isActive: currentPage == 1,
            onTap: () => onPageChanged(1),
          ),
        );
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageButtons.add(
            _buildPaginationBtn(context, 
              text: '$i',
              isActive: currentPage == i,
              onTap: () => onPageChanged(i),
            ),
          );
        }
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        pageButtons.add(
          _buildPaginationBtn(context, 
            text: '$totalPages',
            isActive: currentPage == totalPages,
            onTap: () => onPageChanged(totalPages),
          ),
        );
      }
    }

    // Next Button
    pageButtons.add(
      _buildPaginationBtn(context, 
        icon: Icons.chevron_right,
        isActive: false,
        onTap: currentPage < totalPages
            ? () => onPageChanged(currentPage + 1)
            : null,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageButtons,
    );
  }

  Widget _buildPaginationBtn(BuildContext context, {
    IconData? icon,
    String? text,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF22C55E) : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF22C55E)
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: onTap == null
                        ? const Color(0xFFCBD5E1)
                        : (isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300]! : const Color(0xFF1E293B))),
                  )
                : Text(
                    text!,
                    style: TextStyle(
                      color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300]! : const Color(0xFF1E293B)),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
