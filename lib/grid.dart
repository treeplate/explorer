import 'package:flutter/material.dart';

const double kCellDim = 40;

class GridDrawer extends StatelessWidget {
  GridDrawer(this.grid, this.width, this.cellDim, [this.x, this.y]);
  final List<GridCell> grid;
  final int width;
  final double cellDim;
  final int x;
  final int y;
  int get height => grid.length ~/ width;
  Widget build(BuildContext context) {
    //print("DRW");
    return CustomPaint(
      size: Size(width * cellDim, height * cellDim),
      painter: GridPainter(
        width,
        height,
        grid,
        cellDim,
        x,
        y,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter(this.width, this.height, this.grid, this.cellDim, this.x, this.y);
  final int width;
  final int height;
  final double cellDim;
  final List<GridCell> grid;
  final int x;
  final int y;
  bool shouldRepaint(CustomPainter _) => true;
  void paint(Canvas canvas, Size size) {
    Size cellSize = Size(cellDim, cellDim);
    for (int y = 0; y < height; y += 1) {
      for (int x = 0; x < width; x += 1) {
        canvas.drawRect(Offset(x * cellDim, y * cellDim) & cellSize,
            (Paint()..style = PaintingStyle.stroke)..color = Colors.black);
        grid[x + (y * width)]
            .paint(canvas, cellSize, Offset(x * cellDim, y * cellDim));
      }
    }
    if (x != null)
      canvas.drawCircle(
        Offset(x * cellDim + cellDim / 2, y * cellDim + cellDim / 2),
        cellDim / 2,
        Paint()..color = Colors.orange,
      );
  }
}

abstract class GridCell {
  void paint(Canvas canvas, Size size, Offset offset);
}
