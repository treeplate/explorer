import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'grid.dart';

class Direction {
  Direction(this.x, this.y);
  final int x;
  final int y;

  double get radiansRotated => 0;
}

abstract class Item {
  GridCell get paintedCell;
  Direction doMove();
  Direction pushed(Direction direction);
  Item copy();
  Item rotatedCW() => copy();
  bool ticked = false;
}

class EmptyItem extends Item {
  GridCell get paintedCell => EmptyGridCell();
  Direction pushed(Direction dir) => throw UnsupportedError("move");
  Direction doMove() => Direction(0, 0);
  Item copy() => EmptyItem();
}

class EmptyGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {}
}

class MoveItem extends Item {
  MoveItem(this.moveDir);
  final Direction moveDir;
  Direction pushed(Direction dir) {
    if (dir == moveDir) ticked = true;
    return dir;
  }

  Direction doMove() => moveDir;
  GridCell get paintedCell => MoveGridCell(radiansRotated);

  double get radiansRotated {
    double radians = 0;
    if (moveDir.y == 1) {
      radians += pi;
    }
    if (moveDir.x == 1) {
      radians += pi / 2;
    } else if (moveDir.x == -1) {
      radians += pi * 3 / 2;
    }
    return radians;
  }

  Item copy() => MoveItem(moveDir);
  Item rotatedCW() {
    int newX = 0;
    int newY = 0;
    if (moveDir.x == 0) {
      newX = moveDir.y == 1 ? -1 : 1;
    } else {
      newY = moveDir.x == 1 ? 1 : -1;
    }
    return MoveItem(Direction(newX, newY));
  }
}

class MoveGridCell extends GridCell {
  MoveGridCell(this.radians);
  final double radians;

  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.save();
    canvas.translate(offset.dx + (kCellDim / 2), offset.dy + (kCellDim / 2));
    canvas.rotate(radians);
    canvas.translate(
        -(offset.dx + (kCellDim / 2)), -(offset.dy + (kCellDim / 2)));
    Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.moveTo(offset.dx + size.width, offset.dy + size.height);
    path.lineTo(offset.dx, offset.dy + size.height);
    path.lineTo(offset.dx + size.width / 2, offset.dy);
    Paint paint = Paint()..color = Colors.orange;
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      (offset & size).center - Offset(5, 0),
      2,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      (offset & size).center + Offset(5, 0),
      2,
      Paint()..color = Colors.black,
    );
    canvas.drawLine(
      (offset & size).center + Offset(5, 10),
      (offset & size).center + Offset(0, 15),
      Paint()..color = Colors.black,
    );
    canvas.drawLine(
      (offset & size).center + Offset(-5, 10),
      (offset & size).center + Offset(0, 15),
      Paint()..color = Colors.black,
    );
    canvas.drawLine(
      (offset & size).center + Offset(5, 10),
      (offset & size).center + Offset(5, 15),
      (Paint()..color = Colors.red)..strokeWidth = 2,
    );
    canvas.restore();
  }
}

class MoveableItem extends Item {
  GridCell get paintedCell => MoveableGridCell();
  Direction pushed(Direction dir) => dir;
  Direction doMove() => Direction(0, 0);
  Item copy() => MoveableItem();
}

class MoveableGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.yellow,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class RotateCWItem extends Item {
  GridCell get paintedCell => RotateCWGridCell();
  Direction pushed(Direction dir) => dir;
  Direction doMove() => Direction(0, 0);
  Item copy() => RotateCWItem();
}

class RotateCWGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.orange,
    );
    //TODO better graphics for rotateCW
    canvas.drawCircle(
      offset + Offset(size.width / 2, size.height / 2),
      (size.width/4)+2,
      ((Paint()..color=Colors.white)..style = PaintingStyle.stroke)..strokeWidth = 2,
    );
    canvas.drawLine(
      offset + Offset(size.width / 2, size.height - 10),
      offset + Offset(size.width / 2 + 10, size.height - 20),
      (Paint()..color = Colors.white)..strokeWidth = 2,
    );
    canvas.drawLine(
      offset + Offset(size.width / 2, size.height - 10),
      offset + Offset(size.width / 2 + 10, size.height),
      (Paint()..color = Colors.white)..strokeWidth = 2,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class SlideItem extends Item {
  final bool horizontal;

  SlideItem(this.horizontal);

  @override
  Item copy() => SlideItem(horizontal);
  Item rotatedCW() => SlideItem(!horizontal);

  @override
  Direction doMove() => Direction(0, 0);

  @override
  GridCell get paintedCell => SlideGridCell(!horizontal);

  @override
  Direction pushed(Direction direction) {
    if (horizontal ? direction.y == 0 : direction.x == 0) {
      return direction;
    } else {
      return Direction(0, 0);
    }
  }
}

class SlideGridCell extends GridCell {
  final bool horizontal;

  SlideGridCell(this.horizontal);
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.yellow,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
    canvas.drawLine(
      offset +
          (horizontal ? Offset(size.width / 3, 0) : Offset(0, size.height / 3)),
      offset +
          (horizontal
              ? Offset(size.width / 3, size.height)
              : Offset(size.width, size.height / 3)),
      (Paint()..color = Colors.white)..strokeWidth = 5,
    );
    canvas.drawLine(
      offset +
          (horizontal
              ? Offset(size.width * 2 / 3, 0)
              : Offset(0, size.height * 2 / 3)),
      offset +
          (horizontal
              ? Offset(size.width * 2 / 3, size.height)
              : Offset(size.width, size.height * 2 / 3)),
      (Paint()..color = Colors.white)..strokeWidth = 5,
    );
  }
}

class ImmoveableItem extends Item {
  GridCell get paintedCell => ImmoveableGridCell();
  Direction pushed(Direction dir) => Direction(0, 0);
  Direction doMove() => Direction(0, 0);
  Item copy() => ImmoveableItem();
}

class ImmoveableGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.black,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}
/*
class IronOreItem extends Item {
  GridCell get paintedCell => IronOreGridCell();

  IronOreItem copy() => IronOreItem();
}

class IronOreGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size / 3,
      Paint()..color = Colors.blue,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, 0) & size / 3,
      Paint()..color = Colors.blue,
    );
    canvas.drawRect(
      offset + Offset(0, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.blue,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.blue,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class StoneItem extends Item {
  GridCell get paintedCell => StoneGridCell();

  StoneItem copy() => StoneItem();
}

class StoneGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size / 3,
      Paint()..color = Colors.brown,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, 0) & size / 3,
      Paint()..color = Colors.brown,
    );
    canvas.drawRect(
      offset + Offset(0, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.brown,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.brown,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class CoalItem extends Item {
  GridCell get paintedCell => CoalGridCell();
  CoalItem copy() => CoalItem();
}

class CoalGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size / 3,
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, 0) & size / 3,
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      offset + Offset(0, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      offset + Offset(size.width * 2 / 3, size.height * 2 / 3) & size / 3,
      Paint()..color = Colors.black,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class CheckmarkItem extends Item {
  GridCell get paintedCell => CheckmarkGridCell();
  Item copy() => CheckmarkItem();
}

class CheckmarkGridCell extends GridCell {
  void paint(Canvas canvas, Size size, Offset offset) {
    Path path = Path();
    path.moveTo(offset.dx, offset.dy + (size.height / 2));
    path.lineTo(offset.dx + (size.width / 2), offset.dy + size.height);
    path.lineTo(offset.dx + size.width, offset.dy);
    canvas.drawPath(path, ((Paint()..color=Colors.green)..style=PaintingStyle.stroke)..strokeWidth=3);
  }
}
*/