import 'package:flutter/material.dart';
import '../../../config/api_constants.dart';
import '../../../services/shop_service.dart';
import 'branch_dialog/outlet_details_modal.dart';

class AdminOutletsTab extends StatefulWidget {
  final List<Shop> branches;
  final VoidCallback onAddBranch;
  final Function(Shop) onEditBranch;
  final Function(Shop) onDeleteBranch;
  final Function(Shop) onSelectActiveBranch;
  final String? activeShopId;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminOutletsTab({
    super.key,
    required this.branches,
    required this.onAddBranch,
    required this.onEditBranch,
    required this.onDeleteBranch,
    required this.onSelectActiveBranch,
    this.activeShopId,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  State<AdminOutletsTab> createState() => _AdminOutletsTabState();
}

class _AdminOutletsTabState extends State<AdminOutletsTab> {
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.branches.where((b) {
      if (_searchFilter.trim().isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.code.toLowerCase().contains(q) ||
          b.city.toLowerCase().contains(q) ||
          b.location.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Outlets (${widget.branches.length})',
                      style: TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.w800, color: widget.textColor),
                    ),
                    Text(
                      'Manage branches & active terminals',
                      style: TextStyle(fontSize: isMobile ? 10.5 : 11.5, color: widget.subtitleColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onAddBranch,
                icon: const Icon(Icons.add_business_rounded, size: 15),
                label: Text(isMobile ? 'Add Outlet' : 'Add New Outlet', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: widget.subtitleColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchFilter = val),
                    style: TextStyle(fontSize: 13, color: widget.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by outlet name, branch code, city or address...',
                      hintStyle: TextStyle(fontSize: 12.5, color: widget.subtitleColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchFilter.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear_rounded, size: 16, color: widget.subtitleColor),
                    onPressed: () => setState(() => _searchFilter = ''),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Outlet Cards Grid or Empty State
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: widget.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined, size: 48, color: widget.subtitleColor),
                  const SizedBox(height: 12),
                  Text(
                    widget.branches.isEmpty ? 'No restaurant outlets registered yet.' : 'No outlets matching "$_searchFilter"',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.branches.isEmpty
                        ? 'Click "+ Add New Outlet" above to configure your first restaurant branch.'
                        : 'Try searching with a different term.',
                    style: TextStyle(fontSize: 12, color: widget.subtitleColor),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 950 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 180,
                  ),
                  itemBuilder: (context, idx) {
                    final b = filtered[idx];
                    final isActiveSelection = widget.activeShopId == b.id;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActiveSelection ? const Color(0xFF6366F1) : widget.borderColor,
                          width: isActiveSelection ? 2 : 1,
                        ),
                        boxShadow: isActiveSelection
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top info row
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isActiveSelection ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isActiveSelection ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: (b.logoUrl != null && b.logoUrl!.trim().isNotEmpty)
                                      ? Image.network(
                                          b.logoUrl!.startsWith('http://') || b.logoUrl!.startsWith('https://')
                                              ? b.logoUrl!
                                              : '${ApiConstants.baseUrl}${b.logoUrl!.startsWith('/') ? '' : '/'}${b.logoUrl}',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.storefront_rounded,
                                            color: isActiveSelection ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                                            size: 22,
                                          ),
                                        )
                                      : Icon(
                                          Icons.storefront_rounded,
                                          color: isActiveSelection ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                                          size: 22,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            b.name,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: widget.textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (b.isPrimary) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'PRIMARY',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF6366F1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Code: ${b.code}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.subtitleColor),
                                    ),
                                  ],
                                ),
                              ),
                              // Details & Station Credentials Action Button
                              IconButton(
                                icon: const Icon(Icons.key_rounded, size: 18),
                                color: const Color(0xFF10B981),
                                tooltip: 'Station Logins & Passwords (POS, Kitchen, Inventory, CRM)',
                                splashRadius: 18,
                                onPressed: () {
                                  OutletDetailsModal.show(context, b, onUpdated: () {
                                    setState(() {});
                                  });
                                },
                              ),
                              // Edit & Delete Action Buttons
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: const Color(0xFF6366F1),
                                tooltip: 'Edit Outlet',
                                splashRadius: 18,
                                onPressed: () => widget.onEditBranch(b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                color: const Color(0xFFEF4444),
                                tooltip: 'Delete Outlet',
                                splashRadius: 18,
                                onPressed: () => widget.onDeleteBranch(b),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Location and Contact
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: widget.subtitleColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${b.location}, ${b.city}',
                                  style: TextStyle(fontSize: 11.5, color: widget.subtitleColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.contact.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.phone_outlined, size: 14, color: widget.subtitleColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    b.contact,
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.subtitleColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Active Status & Selection Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      b.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      OutletDetailsModal.show(context, b, onUpdated: () {
                                        setState(() {});
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF6366F1)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Details & Logins',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isActiveSelection)
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF6366F1)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active Workspace',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                InkWell(
                                  onTap: () => widget.onSelectActiveBranch(b),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: widget.borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.radio_button_unchecked, size: 14, color: widget.subtitleColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Set as Active Outlet',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: widget.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
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
            ),
        ],
      ),
    );
  }
}
