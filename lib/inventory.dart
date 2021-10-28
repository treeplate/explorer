import 'package:flutter/material.dart';

import 'grid.dart';
import 'items.dart';

class Inventory extends StatelessWidget {
  Inventory(
    this.cellDim,
    this.items,
    this.gridWidth,
    this.cursorStack, {
    @required this.onTap,
  });
  final double cellDim;

  final List<Item> items;
  final int gridWidth;
  final void Function(Item item) onTap;

  final Item Function() cursorStack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          Offset position = details.localPosition;
          int x = (position.dx / cellDim).floor();
          int y = (position.dy / cellDim).floor();
          int i = x + (y * gridWidth);
          //print("Pressed $i (${items[i]})");
          onTap(items[i]);
        },
        child: GridDrawer(
          items.map((key) => key.paintedCell).toList(),
          gridWidth,
          cellDim,
        ),
      ),
    );
  }
}