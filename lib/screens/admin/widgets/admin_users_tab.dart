import 'package:flutter/material.dart';
import '../../../services/admin_staff_service.dart';
import 'admin_metric_card.dart';

class AdminUsersTab extends StatelessWidget {
  final List<RestaurantStaffUser> staffUsers;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddUser;
  final Function(RestaurantStaffUser)? onEditUser;
  final Function(RestaurantStaffUser)? onDeleteUser;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminUsersTab({
    super.key,
    required this.staffUsers,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddUser,
    this.onEditUser,
    this.onDeleteUser,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final filteredUsers = staffUsers.where((u) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff & Roles (${staffUsers.length})',
                      style: TextStyle(fontSize: isMobile ? 15 : 15, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      'Manage staff accounts & permissions',
                      style: TextStyle(fontSize: isMobile ? 10.5 : 11, color: subtitleColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddUser,
                icon: const Icon(Icons.person_add_rounded, size: 15),
                label: Text(isMobile ? 'Add User' : 'Add Staff User', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search staff by name, email, or role...',
                hintStyle: TextStyle(fontSize: 12, color: subtitleColor),
                icon: Icon(Icons.search_rounded, size: 18, color: subtitleColor),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (filteredUsers.isEmpty)
            const AdminEmptyState(text: 'No staff users match your search.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final u = filteredUsers[idx];
                Color roleColor;
                switch (u.role) {
                  case 'admin':
                    roleColor = const Color(0xFF6366F1);
                    break;
                  case 'manager':
                    roleColor = const Color(0xFF8B5CF6);
                    break;
                  case 'chef':
                    roleColor = const Color(0xFFF97316);
                    break;
                  case 'inventory':
                    roleColor = const Color(0xFF3B82F6);
                    break;
                  case 'waiter':
                    roleColor = const Color(0xFFEC4899);
                    break;
                  default:
                    roleColor = const Color(0xFF10B981);
                    break;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: roleColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    u.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMobile && u.phone != null && u.phone!.isNotEmpty
                                  ? '${u.username} • ${u.phone} • ${u.branchName ?? 'All'}'
                                  : '${u.username} • Outlet: ${u.branchName ?? 'All Branches'}',
                              style: TextStyle(fontSize: 11, color: subtitleColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (u.phone != null && u.phone!.isNotEmpty && !isMobile) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 11, color: subtitleColor),
                              const SizedBox(width: 3),
                              Text(
                                u.phone!,
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Action buttons: Edit & Delete
                      if (onEditUser != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          color: const Color(0xFF6366F1),
                          tooltip: 'Edit Staff Account',
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => onEditUser!(u),
                        ),
                      if (onDeleteUser != null && u.role.toLowerCase() != 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 17),
                          color: const Color(0xFFEF4444),
                          tooltip: 'Delete User Account',
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => onDeleteUser!(u),
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
}
