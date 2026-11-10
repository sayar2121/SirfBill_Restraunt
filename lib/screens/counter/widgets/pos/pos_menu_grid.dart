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

        if (width < 320) {
          crossAxisCount = 1;
          childAspectRatio = 1.35;
        } else if (width < 480) {
          crossAxisCount = 2;
          childAspectRatio = 0.88;
        } else if (width < 700) {
          crossAxisCount = 3;
          childAspectRatio = 0.90;
        } else if (width < 960) {
          crossAxisCount = 4;
          childAspectRatio = 0.92;
        } else if (width < 1250) {
          crossAxisCount = 5;
          childAspectRatio = 0.92;
        } else if (width < 1550) {
          crossAxisCount = 6;
          childAspectRatio = 0.94;
        } else {
          crossAxisCount = 7;
          childAspectRatio = 0.95;
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
