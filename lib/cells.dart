import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'grid.dart';

class Direction {
  Direction(this.x, this.y);
  final int x;
  final int y;

  double get radiansRotated => 0;
}

abstract class Cell {
  Cell(this.setInStone);

  GridCell get paintedCell;
  Direction doMove();
  Direction pushed(Direction direction);
  Cell copy();
  Cell rotatedCW() => copy();
  bool ticked = false;
  final bool setInStone;
}

class EmptyCell extends Cell {
  EmptyCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => EmptyGridCell(setInStone);
  Direction pushed(Direction dir) => throw UnsupportedError("move");
  Direction doMove() => Direction(0, 0);
  Cell copy() => EmptyCell(setInStone);
  String toString() => setInStone ? ' ' : '+';
}

class EmptyGridCell extends GridCell {
  EmptyGridCell(this.haveNoPlus);
  final bool haveNoPlus;
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    if(!haveNoPlus) {
      canvas.drawLine(offset + Offset(size.width/2,size.height/4), offset + Offset(size.width/2,size.height*3/4), Paint()..color = Colors.black);
      canvas.drawLine(offset + Offset(size.width/4,size.height/2), offset + Offset(size.width*3/4,size.height/2), Paint()..color = Colors.black);
    }
  }
}

class MoveCell extends Cell {
  MoveCell(this.moveDir, bool setInStone) : super(setInStone);
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

  String toString() {
    switch (radiansRotated.round()) {
      case 0:
        return '^';
      case 2:
        return '>';
      case 3:
        return 'v';
      case 5:
        return '<';
    }
    throw StateError(radiansRotated.toString());
  }

  Cell copy() => MoveCell(moveDir, setInStone);
  Cell rotatedCW() {
    int newX = 0;
    int newY = 0;
    if (moveDir.x == 0) {
      newX = moveDir.y == 1 ? -1 : 1;
    } else {
      newY = moveDir.x == 1 ? 1 : -1;
    }
    return MoveCell(Direction(newX, newY), setInStone);
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

class GeneratorCell extends Cell {
  GeneratorCell(this.moveDir, bool setInStone) : super(setInStone);
  final Direction moveDir;
  Direction pushed(Direction dir) {
    return dir;
  }

  String toString() {
    switch (radiansRotated.round()) {
      case 0:
        return 'W';
      case 2:
        return 'D';
      case 3:
        return 'S';
      case 5:
        return 'A';
    }
    throw StateError(radiansRotated.toString());
  }

  Direction doMove() => Direction(0, 0);
  GridCell get paintedCell => GeneratorGridCell(radiansRotated);

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

  Cell copy() => GeneratorCell(moveDir, setInStone);
  Cell rotatedCW() {
    int newX = 0;
    int newY = 0;
    if (moveDir.x == 0) {
      newX = moveDir.y == 1 ? -1 : 1;
    } else {
      newY = moveDir.x == 1 ? 1 : -1;
    }
    return GeneratorCell(Direction(newX, newY), setInStone);
  }
}

class GeneratorGridCell extends GridCell {
  GeneratorGridCell(this.radians);
  final double radians;

  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.save();
    canvas.translate(offset.dx + (kCellDim / 2), offset.dy + (kCellDim / 2));
    canvas.rotate(radians);
    canvas.translate(
        -(offset.dx + (kCellDim / 2)), -(offset.dy + (kCellDim / 2)));
    canvas.drawRect(
      offset +
              Offset(
                size.width / 3,
                size.height / 2,
              ) &
          Size(
            size.width / 3,
            size.height / 3,
          ),
      Paint()..color = Colors.green,
    );
    final double unitH = size.width / 8.0;
    final double unitV = size.height / 8.0;
    final Offset arrowHead = offset +
        Offset(
          4 * unitH,
          2 * unitV,
        );
    final Path path = Path()
      ..moveTo(offset.dx + 4 * unitH, offset.dy + 4 * unitV)
      ..lineTo(arrowHead.dx, arrowHead.dy)
      ..moveTo(arrowHead.dx - unitH, arrowHead.dy + unitV)
      ..relativeLineTo(unitH, -unitV)
      ..relativeLineTo(unitH, unitV);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt,
    );
    canvas.restore();
  }
}

class MoveableCell extends Cell {
  MoveableCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => MoveableGridCell();
  Direction pushed(Direction dir) => dir;
  Direction doMove() => Direction(0, 0);
  Cell copy() => MoveableCell(setInStone);
  String toString() => "#";
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

class EnemyCell extends Cell {
  EnemyCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => EnemyGridCell();
  Direction pushed(Direction dir) => Direction(0, 0);
  Direction doMove() => Direction(0, 0);
  Cell copy() => EnemyCell(setInStone);
  String toString() => 'E';
}

class EnemyGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.red,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class TrashCell extends Cell {
  TrashCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => TrashGridCell();
  Direction pushed(Direction dir) => Direction(0, 0);
  Direction doMove() => Direction(0, 0);
  Cell copy() => TrashCell(setInStone);
  String toString() => 'T';
}

class TrashGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.purple,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class RotateCWCell extends Cell {
  RotateCWCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => RotateCWGridCell();
  Direction pushed(Direction dir) => dir;
  Direction doMove() => Direction(0, 0);
  Cell copy() => RotateCWCell(setInStone);
  String toString() => 'R';
}

class RotateCWGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.orange,
    );
    final double unitH = size.width / 8.0;
    final double unitV = size.height / 8.0;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: unitH * 1.5,
      vertical: unitV * 1.5,
    );
    final Rect arcBox = padding.deflateRect(offset & size);
    final Offset arrowHead = Offset(
      arcBox.right,
      arcBox.center.dy + unitV / 2.0,
    );
    final double arcSweep = -pi * 7.0 / 4.0;
    final Path path = Path()
      ..addArc(arcBox, arcSweep, -arcSweep)
      ..lineTo(arrowHead.dx, arrowHead.dy)
      ..moveTo(arrowHead.dx - unitH, arrowHead.dy - unitV)
      ..relativeLineTo(unitH, unitV)
      ..relativeLineTo(unitH, -unitV);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class RotateCCWCell extends Cell {
  RotateCCWCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => RotateCCWGridCell();
  Direction pushed(Direction dir) => dir;
  Direction doMove() => Direction(0, 0);
  Cell copy() => RotateCCWCell(setInStone);
  String toString() => 'i';
}

class RotateCCWGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.tealAccent,
    );
    final double unitH = size.width / 8.0;
    final double unitV = size.height / 8.0;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: unitH * 1.5,
      vertical: unitV * 1.5,
    );
    final Rect arcBox = padding.deflateRect(offset & size);
    final Offset arrowHead = Offset(
      arcBox.left,
      arcBox.center.dy + unitV / 2.0,
    );
    final double arcSweep = pi * 7.0 / 4.0;
    final double arcStart = pi * 3 / 4;
    final Path path = Path()
      ..addArc(arcBox, arcStart, -arcSweep)
      ..lineTo(arrowHead.dx, arrowHead.dy)
      ..moveTo(arrowHead.dx - unitH, arrowHead.dy - unitV)
      ..relativeLineTo(unitH, unitV)
      ..relativeLineTo(unitH, -unitV);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class SlideCell extends Cell {
  final bool horizontal;

  String toString() => horizontal ? '=' : '|';

  SlideCell(this.horizontal, bool setInStone) : super(setInStone);

  @override
  Cell copy() => SlideCell(horizontal, setInStone);
  Cell rotatedCW() => SlideCell(!horizontal, setInStone);

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

class ImmoveableCell extends Cell {
  ImmoveableCell(bool setInStone) : super(setInStone);

  GridCell get paintedCell => ImmoveableGridCell();
  Direction pushed(Direction dir) => Direction(0, 0);
  Direction doMove() => Direction(0, 0);
  Cell copy() => ImmoveableCell(setInStone);
  String toString() => "X";
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

Cell parse(String char, bool setInStone) {
  switch (char) {
    case ' ':
      return EmptyCell(setInStone);
    case '+':
      return EmptyCell(false);
    case '#':
      return MoveableCell(setInStone);
    case '>':
      return MoveCell(Direction(1, 0), setInStone);
    case 'v':
      return MoveCell(Direction(0, 1), setInStone);
    case '<':
      return MoveCell(Direction(-1, 0), setInStone);
    case '^':
      return MoveCell(Direction(0, -1), setInStone);
    case 'D':
      return GeneratorCell(Direction(1, 0), setInStone);
    case 'S':
      return GeneratorCell(Direction(0, 1), setInStone);
    case 'A':
      return GeneratorCell(Direction(-1, 0), setInStone);
    case 'W':
      return GeneratorCell(Direction(0, -1), setInStone);
    case 'X':
      return ImmoveableCell(setInStone);
    case '=':
      return SlideCell(true, setInStone);
    case '|':
      return SlideCell(false, setInStone);
    case 'E':
      return EnemyCell(setInStone);
    case 'T':
      return TrashCell(setInStone);
    case 'R':
      return RotateCWCell(setInStone);
    case 'i':
      return RotateCCWCell(setInStone);
  }
  throw StateError("ERRER$char");
}
/*
class IronOreCell extends Cell {
  GridCell get paintedCell => IronOreGridCell();

  IronOreCell copy() => IronOreCell();
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

class StoneCell extends Cell {
  GridCell get paintedCell => StoneGridCell();

  StoneCell copy() => StoneCell();
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

class CoalCell extends Cell {
  GridCell get paintedCell => CoalGridCell();
  CoalCell copy() => CoalCell();
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

class CheckmarkCell extends Cell {
  GridCell get paintedCell => CheckmarkGridCell();
  Cell copy() => CheckmarkCell();
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