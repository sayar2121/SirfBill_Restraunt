import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';

class UploadHeader extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onBack;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onUploadExcel;
  final VoidCallback onRefresh;

  const UploadHeader({
    super.key,
    required this.isUploading,
    required this.onBack,
    required this.onDownloadTemplate,
    required this.onUploadExcel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: !Responsive.isDesktop(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: onBack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Item',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Add a new item to your inventory (Master DB)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isUploading)
                  const CircularProgressIndicator(color: Color(0xFF22C55E))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onDownloadTemplate,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9),
                          foregroundColor:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                          elevation: 0,
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onUploadExcel,
                        icon: Icon(
                          Icons.upload_file,
                          size: 18,
                          color: isDark ? Colors.black : Theme.of(context).cardColor,
                        ),
                        label: const Text('Bulk Upload (Excel)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                          foregroundColor:
                              isDark ? Colors.black : Theme.of(context).cardColor,
                          elevation: 0,
                        ),
                      ),
                      Tooltip(
                        message: 'Refresh Categories and Racks',
                        child: IconButton(
                          onPressed: onRefresh,
                          icon: Icon(
                            Icons.refresh,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: onBack,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Item',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Add a new item to your inventory (Master DB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    if (isUploading)
                      const CircularProgressIndicator(color: Color(0xFF22C55E))
                    else
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: onDownloadTemplate,
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Download Template'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : const Color(0xFFF1F5F9),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              elevation: 0,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: onUploadExcel,
                            icon: Icon(
                              Icons.upload_file,
                              size: 18,
                              color: isDark
                                  ? Colors.black
                                  : Theme.of(context).cardColor,
                            ),
                            label: const Text('Bulk Upload (Excel)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Theme.of(context).cardColor,
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Refresh Categories and Racks',
                            child: IconButton(
                              onPressed: onRefresh,
                              icon: Icon(
                                Icons.refresh,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
