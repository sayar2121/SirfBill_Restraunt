import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'pos_menu_card.dart';

class PosMenuGrid extends StatefulWidget {
  final List<PosMenuItem> items;
  final ValueChanged<PosMenuItem> onAddItem;

  const PosMenuGrid({
    super.key,
    required this.items,
    required this.onAddItem,
  });

  @override
  State<PosMenuGrid> createState() => _PosMenuGridState();
}

class _PosMenuGridState extends State<PosMenuGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('No food items found', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive columns & aspect ratio calculation
        int crossAxisCount;
        double childAspectRatio;

        if (width < 340) {
          crossAxisCount = 1;
          childAspectRatio = 1.35;
        } else if (width < 540) {
          crossAxisCount = 2;
          childAspectRatio = 0.74;
        } else if (width < 760) {
          crossAxisCount = 2;
          childAspectRatio = 0.82;
        } else if (width < 1000) {
          crossAxisCount = 3;
          childAspectRatio = 0.80;
        } else if (width < 1300) {
          crossAxisCount = 4;
          childAspectRatio = 0.84;
        } else {
          crossAxisCount = 5;
          childAspectRatio = 0.88;
        }

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 8.0,
          radius: const Radius.circular(8),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: widget.items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return PosMenuCard(
                item: item,
                onAdd: () => widget.onAddItem(item),
              );
            },
          ),
        );
      },
    );
  }
}
