import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../providers/distributor_provider.dart';
import '../edit_distributor_dialog.dart';

class DistributorListView extends ConsumerWidget {
  final List<dynamic> distributors;
  
  const DistributorListView({super.key, required this.distributors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Text('All Distributors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: distributors.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
            itemBuilder: (context, index) {
              final dist = distributors[index];
              return InkWell(
                onTap: () {
                  context.push('/counter/distributors/details', extra: dist);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.business, color: Color(0xFF166534)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dist['name'] ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${dist['phone'] ?? 'N/A'} | Email: ${dist['email'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF3B82F6), size: 20),
                            tooltip: 'Add Purchase Bill',
                            onPressed: () {
                              context.push('/counter/distributors/purchase', extra: dist);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), size: 20),
                            tooltip: 'Edit',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditDistributorDialog(distributor: dist),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Delete',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Distributor'),
                                  content: Text('Are you sure you want to delete ${dist['name']}? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context); // close dialog
                                        try {
                                          await ref.read(distributorServiceProvider).deleteDistributor(dist['id']);
                                          ref.invalidate(distributorsProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Distributor deleted successfully'), backgroundColor: Colors.green),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text('Delete', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
