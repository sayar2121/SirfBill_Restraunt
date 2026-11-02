import 'package:flutter/material.dart';

class PosCustomerBar extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final String selectedCustomerName;
  final String selectedCustomerPhone;
  final ValueChanged<Map<String, dynamic>> onSelectCustomer;
  final VoidCallback onClearCustomer;
  final VoidCallback onAddNew;

  const PosCustomerBar({
    super.key,
    required this.customers,
    required this.selectedCustomerName,
    required this.selectedCustomerPhone,
    required this.onSelectCustomer,
    required this.onClearCustomer,
    required this.onAddNew,
  });

  @override
  State<PosCustomerBar> createState() => _PosCustomerBarState();
}

class _PosCustomerBarState extends State<PosCustomerBar> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isMenuOpen = false;

  bool get _hasSelectedCustomer =>
      widget.selectedCustomerName.isNotEmpty &&
      widget.selectedCustomerName != 'Walk-in Guest';

  @override
  void didUpdateWidget(covariant PosCustomerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCustomerName != widget.selectedCustomerName && widget.selectedCustomerName.isEmpty) {
      _searchCtrl.clear();
      _isMenuOpen = false;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredCustomers() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.customers.take(6).toList();
    }
    return widget.customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final id = (c['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || id.contains(q);
    }).take(8).toList();
  }

  void _selectCustomer(Map<String, dynamic> cust) {
    setState(() {
      _isMenuOpen = false;
      _searchCtrl.clear();
    });
    _focusNode.unfocus();
    widget.onSelectCustomer(cust);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Bar
        Row(
          children: [
            // If customer is selected: display linked badge
            if (_hasSelectedCustomer) ...[
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.selectedCustomerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Linked',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.selectedCustomerPhone.isNotEmpty)
                              Text(
                                widget.selectedCustomerPhone,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                        splashRadius: 18,
                        tooltip: 'Detach customer',
                        onPressed: () {
                          setState(() {
                            _isMenuOpen = false;
                            _searchCtrl.clear();
                          });
                          widget.onClearCustomer();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Default search state
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.person_pin_rounded, size: 24, color: Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isMenuOpen ? const Color(0xFF10B981) : borderColor,
                      width: _isMenuOpen ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          onTap: () {
                            setState(() => _isMenuOpen = true);
                          },
                          onChanged: (val) {
                            setState(() {
                              _isMenuOpen = true;
                            });
                          },
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search customer by name or phone...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchCtrl.clear();
                              _isMenuOpen = false;
                            });
                          },
                          child: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isMenuOpen = false);
                  widget.onAddNew();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        // Inline Suggestion List (Rock solid - guaranteed responsive and clickable)
        if (_isMenuOpen && !_hasSelectedCustomer) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                final filtered = _getFilteredCustomers();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person_off_outlined, size: 18, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'No customer found',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _isMenuOpen = false);
                            widget.onAddNew();
                          },
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text('Add Now', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, idx) {
                    final cust = filtered[idx];
                    final name = cust['name']?.toString() ?? 'Customer';
                    final phone = cust['phone']?.toString() ?? '';
                    final totalPurchases = (cust['totalPurchases'] as num?)?.toDouble() ?? 0.0;
                    final billsCount = cust['bills'] ?? 0;

                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                        child: Text(
                          (cust['initials']?.toString().isNotEmpty == true)
                              ? cust['initials'].toString()
                              : (name.isNotEmpty ? name[0].toUpperCase() : 'C'),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: phone.isNotEmpty
                          ? Text(
                              phone,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            )
                          : null,
                      trailing: billsCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹${totalPurchases.toStringAsFixed(0)} ($billsCount bills)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      onTap: () => _selectCustomer(cust),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
