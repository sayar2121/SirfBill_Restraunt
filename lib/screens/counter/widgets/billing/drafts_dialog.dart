import 'package:flutter/material.dart';
import '../../../../services/draft_service.dart';

class DraftsDialog extends StatefulWidget {
  final List<DraftBill> initialDrafts;
  final ValueChanged<DraftBill> onDraftSelected;

  const DraftsDialog({
    super.key,
    required this.initialDrafts,
    required this.onDraftSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<DraftBill> onDraftSelected,
  }) async {
    final drafts = await DraftService.getDrafts();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => DraftsDialog(
        initialDrafts: drafts,
        onDraftSelected: onDraftSelected,
      ),
    );
  }

  @override
  State<DraftsDialog> createState() => _DraftsDialogState();
}

class _DraftsDialogState extends State<DraftsDialog> {
  late List<DraftBill> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = List.from(widget.initialDrafts);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open, color: Color(0xFF1E293B)),
          SizedBox(width: 8),
          Text(
            'Saved Drafts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _drafts.isEmpty
            ? const Center(
                child: Text(
                  'No drafts found.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            : ListView.builder(
                itemCount: _drafts.length,
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  final timeStr =
                      "${draft.createdAt.day}/${draft.createdAt.month}/${draft.createdAt.year} ${draft.createdAt.hour}:${draft.createdAt.minute.toString().padLeft(2, '0')}";
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        draft.customerName.isEmpty
                            ? 'Walk-in Customer'
                            : draft.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Items: ${draft.items.length} • Format: ${draft.format} • $timeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () async {
                          await DraftService.deleteDraft(draft.id);
                          setState(() {
                            _drafts.removeAt(index);
                          });
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onDraftSelected(draft);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
