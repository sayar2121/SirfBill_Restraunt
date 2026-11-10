import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_constants.dart';
import '../../../../services/shop_service.dart';
import '../../../../services/admin_staff_service.dart';

class OutletDetailsModal extends StatefulWidget {
  final Shop outlet;
  final VoidCallback onCredentialsUpdated;

  const OutletDetailsModal({
    super.key,
    required this.outlet,
    required this.onCredentialsUpdated,
  });

  static void show(BuildContext context, Shop outlet, {required VoidCallback onUpdated}) {
    showDialog(
      context: context,
      builder: (ctx) => OutletDetailsModal(
        outlet: outlet,
        onCredentialsUpdated: onUpdated,
      ),
    );
  }

  @override
  State<OutletDetailsModal> createState() => _OutletDetailsModalState();
}

class _OutletDetailsModalState extends State<OutletDetailsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<RestaurantStaffUser> _outletUsers = [];
  Map<String, String> _customPasswords = {};
  Map<String, String> _customUsernames = {};

  // Controllers for editing a credential
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _editingRole = '';
  String _editingKey = '';
  bool _isSavingCredentials = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOutletCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _cleanCode(String code) {
    return code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> _loadOutletCredentials() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final outletPrefix = 'outlet_cred_${widget.outlet.id}_';
      
      final keys = ['pos', 'kitchen', 'inventory', 'crm'];
      final savedPasswords = <String, String>{};
      final savedUsernames = <String, String>{};
      for (final k in keys) {
        final p = prefs.getString('$outletPrefix${k}_pass');
        if (p != null && p.isNotEmpty) savedPasswords[k] = p;
        final u = prefs.getString('$outletPrefix${k}_user');
        if (u != null && u.isNotEmpty) savedUsernames[k] = u;
      }
      _customPasswords = savedPasswords;
      _customUsernames = savedUsernames;

      final allStaff = await AdminStaffService.getStaffUsers();
      final branchCode = _cleanCode(widget.outlet.code);
      final outletName = widget.outlet.name.trim().toLowerCase();
      final outletId = widget.outlet.id.trim().toLowerCase();
      
      // Filter users provisioned for this branch
      final matched = allStaff.where((u) {
        final un = u.username.toLowerCase();
        final uBranch = (u.branchId ?? '').toLowerCase();
        final uBranchName = (u.branchName ?? '').toLowerCase();
        return (outletId.isNotEmpty && uBranch == outletId) ||
            (outletName.isNotEmpty && uBranchName == outletName) ||
            (branchCode.isNotEmpty && un.contains(branchCode));
      }).toList();

      _outletUsers = matched;
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditCredentialSheet(String moduleTitle, String moduleKey, String defaultUsername, String defaultPassword, String role) {
    _usernameCtrl.text = _customUsernames[moduleKey] ?? defaultUsername;
    _passwordCtrl.text = _customPasswords[moduleKey] ?? defaultPassword;
    _editingRole = role;
    _editingKey = moduleKey;

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscurePassword = true;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.key_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text('Update $moduleTitle Login', style: const TextStyle(fontSize: 15)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change the username or login password for this outlet station:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Login User ID / Email *',
                    prefixIcon: Icon(Icons.person_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password *',
                    prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isSavingCredentials = true);
                  final newUsername = _usernameCtrl.text.trim();
                  final newPassword = _passwordCtrl.text.trim();
                  try {
                    // Save locally in SharedPreferences immediately
                    final prefs = await SharedPreferences.getInstance();
                    final outletPrefix = 'outlet_cred_${widget.outlet.id}_';
                    if (_editingKey.isNotEmpty) {
                      await prefs.setString('$outletPrefix${_editingKey}_pass', newPassword);
                      await prefs.setString('$outletPrefix${_editingKey}_user', newUsername);
                      _customPasswords[_editingKey] = newPassword;
                      _customUsernames[_editingKey] = newUsername;
                    }

                    // Sync with backend API
                    await AdminStaffService.createStaffUser(
                      username: newUsername,
                      password: newPassword,
                      name: '${widget.outlet.name} $moduleTitle',
                      role: _editingRole,
                      branchId: widget.outlet.id,
                    );

                    await _loadOutletCredentials();
                    widget.onCredentialsUpdated();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$moduleTitle login credentials updated successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update credentials: $e'),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSavingCredentials = false);
                  }
                },
                child: const Text('Save & Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final cleanCode = _cleanCode(widget.outlet.code);

    final modules = [
      {
        'key': 'pos',
        'title': 'Restaurant POS',
        'subtitle': 'Billing Counter, KOTs, Dine-in & Payments',
        'icon': Icons.restaurant_menu_rounded,
        'color': const Color(0xFF10B981),
        'userId': _customUsernames['pos'] ?? 'pos_$cleanCode@sirfbill.com',
        'pass': _customPasswords['pos'] ?? '123456',
        'role': 'cashier',
      },
      {
        'key': 'kitchen',
        'title': 'Kitchen Display',
        'subtitle': 'Live Chef Station & Order Routing',
        'icon': Icons.soup_kitchen_rounded,
        'color': const Color(0xFFF97316),
        'userId': _customUsernames['kitchen'] ?? 'kitchen_$cleanCode@sirfbill.com',
        'pass': _customPasswords['kitchen'] ?? '123456',
        'role': 'chef',
      },
      {
        'key': 'inventory',
        'title': 'Inventory & Purchase',
        'subtitle': 'Branch Stock, Recipes, Ingredients & POs',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF3B82F6),
        'userId': _customUsernames['inventory'] ?? 'inventory_$cleanCode@sirfbill.com',
        'pass': _customPasswords['inventory'] ?? '123456',
        'role': 'manager',
      },
      {
        'key': 'crm',
        'title': 'CRM & Reports',
        'subtitle': 'Customer Loyalty, Daily Revenue & Branch Audits',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF8B5CF6),
        'userId': _customUsernames['crm'] ?? 'crm_$cleanCode@sirfbill.com',
        'pass': _customPasswords['crm'] ?? '123456',
        'role': 'manager',
      },
      {
        'key': 'waiter',
        'title': 'Waiter / Captain',
        'subtitle': 'Table Order Taking & Automated KOT Dispatch',
        'icon': Icons.room_service_rounded,
        'color': const Color(0xFFF59E0B),
        'userId': _customUsernames['waiter'] ?? 'waiter_$cleanCode@sirfbill.com',
        'pass': _customPasswords['waiter'] ?? '123456',
        'role': 'waiter',
      },
    ];

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        width: 780,
        height: 640,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: (widget.outlet.logoUrl != null && widget.outlet.logoUrl!.trim().isNotEmpty)
                          ? Image.network(
                              widget.outlet.logoUrl!.startsWith('http://') || widget.outlet.logoUrl!.startsWith('https://')
                                  ? widget.outlet.logoUrl!
                                  : '${ApiConstants.baseUrl}${widget.outlet.logoUrl!.startsWith('/') ? '' : '/'}${widget.outlet.logoUrl}',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.store_mall_directory_rounded,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            )
                          : const Icon(Icons.store_mall_directory_rounded, color: Color(0xFF6366F1), size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.outlet.name,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.outlet.code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.outlet.location}, ${widget.outlet.city} • Outlet ID: ${widget.outlet.id}',
                          style: TextStyle(fontSize: 11.5, color: subtitleColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: subtitleColor),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: subtitleColor,
                indicatorColor: const Color(0xFF6366F1),
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.key_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Station Logins & Passwords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Branch Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: MODULE PASSWORDS & LOGINS
                  (_isLoading || _isSavingCredentials)
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: modules.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final m = modules[idx];
                            final color = m['color'] as Color;
                            final defaultId = m['userId'] as String;
                            final role = m['role'] as String;

                            final moduleKey = m['key'] as String;

                            // Match dynamic user specifically for this module
                            final matchingStaff = _outletUsers.firstWhere(
                              (u) {
                                final un = u.username.toLowerCase();
                                if (moduleKey == 'pos') {
                                  return un.contains('pos') || un.contains('cashier');
                                } else if (moduleKey == 'kitchen') {
                                  return un.contains('kds') || un.contains('kitchen') || un.contains('chef');
                                } else if (moduleKey == 'inventory') {
                                  return un.contains('inv') || un.contains('stock') || un.contains('inventory');
                                } else if (moduleKey == 'crm') {
                                  return un.contains('crm') || un.contains('report') || un.contains('loyalty');
                                }
                                return false;
                              },
                              orElse: () => RestaurantStaffUser(
                                id: '',
                                username: defaultId,
                                name: '',
                                role: role,
                              ),
                            );

                            final activeUser = (matchingStaff.username.isNotEmpty && matchingStaff.id.isNotEmpty)
                                ? matchingStaff.username
                                : defaultId;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(m['icon'] as IconData, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['title'] as String,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        Text(
                                          m['subtitle'] as String,
                                          style: TextStyle(fontSize: 11, color: subtitleColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // User ID Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: borderColor),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('User ID: ', style: TextStyle(fontSize: 11, color: subtitleColor)),
                                                  Text(activeUser, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                                                  const SizedBox(width: 4),
                                                  InkWell(
                                                    onTap: () => _copyToClipboard(activeUser, 'User ID'),
                                                    child: Icon(Icons.copy_rounded, size: 12, color: subtitleColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Password Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: borderColor),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Password: ', style: TextStyle(fontSize: 11, color: subtitleColor)),
                                                  Text(m['pass'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                                                  const SizedBox(width: 4),
                                                  InkWell(
                                                    onTap: () => _copyToClipboard(m['pass'] as String, 'Password'),
                                                    child: Icon(Icons.copy_rounded, size: 12, color: subtitleColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Changeable Button
                                  OutlinedButton.icon(
                                    onPressed: () => _openEditCredentialSheet(
                                      m['title'] as String,
                                      m['key'] as String,
                                      activeUser,
                                      m['pass'] as String,
                                      role,
                                    ),
                                    icon: const Icon(Icons.edit_rounded, size: 14),
                                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                      side: const BorderSide(color: Color(0xFF6366F1)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // TAB 2: BRANCH PROFILE OVERVIEW
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailTile('Branch Name', widget.outlet.name, textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('Branch Code', widget.outlet.code, textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('Physical Address', widget.outlet.location, textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('City & Region', widget.outlet.city, textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('Contact Phone', widget.outlet.contact, textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('Operational Status', widget.outlet.status.toUpperCase(), textColor, subtitleColor, borderColor, cardBg),
                        _buildDetailTile('Primary Branch Flag', widget.outlet.isPrimary ? 'YES (HQ Outlet)' : 'NO', textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.bankAccountName != null && widget.outlet.bankAccountName!.isNotEmpty)
                          _buildDetailTile('Account Holder Name', widget.outlet.bankAccountName!, textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.bankName != null && widget.outlet.bankName!.isNotEmpty)
                          _buildDetailTile('Bank Name', widget.outlet.bankName!, textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.bankAccount != null && widget.outlet.bankAccount!.isNotEmpty)
                          _buildDetailTile('Bank Account Number', widget.outlet.bankAccount!, textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.bankIfsc != null && widget.outlet.bankIfsc!.isNotEmpty)
                          _buildDetailTile('Bank IFSC Code', widget.outlet.bankIfsc!, textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.bankBranch != null && widget.outlet.bankBranch!.isNotEmpty)
                          _buildDetailTile('Bank Branch', widget.outlet.bankBranch!, textColor, subtitleColor, borderColor, cardBg),
                        if (widget.outlet.upiId != null && widget.outlet.upiId!.isNotEmpty)
                          _buildDetailTile('UPI ID / VPA', widget.outlet.upiId!, textColor, subtitleColor, borderColor, cardBg),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Text(
                    'Staff can use these credentials to log in to POS, Kitchen, and Inventory.',
                    style: TextStyle(fontSize: 11.5, color: subtitleColor),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, Color textColor, Color subtitleColor, Color borderColor, Color cardBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
