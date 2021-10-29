import 'package:flutter/material.dart';

import 'grid.dart';
import 'cells.dart';

class World extends StatelessWidget {
  World(
    this.cellDim,
    this.cells,
    this.gridWidth,
    this.cursorStack, {
    @required this.onTap,
  });
  final double cellDim;

  final List<Cell> cells;
  final int gridWidth;
  final void Function(Cell cell) onTap;

  final Cell Function() cursorStack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          Offset position = details.localPosition;
          int x = (position.dx / cellDim).floor();
          int y = (position.dy / cellDim).floor();
          int i = x + (y * gridWidth);
          //print("Pressed $i (${cells[i]})");
          onTap(cells[i]);
        },
        child: GridDrawer(
          cells.map((key) => key.paintedCell).toList(),
          gridWidth,
          cellDim,
        ),
      ),
    );
  }
}
