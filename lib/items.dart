import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'grid.dart';

//Items:
//Furnace: used for smelting; placable: true; minable: true; infinite: false; smeltable: false; fuel: false; smelted: null; millisecondsToMine: 1000
//Iron-ore: can be smelted for iron-plate; placable: false; minable: true; infinite: true; smeltable: true; fuel: false; smelted: iron-plate; millisecondsToMine: 5000
//Stone: can be crafted into furnace; placable: false; minable: true; infinite: true; smeltable: false; fuel: false; smelted: null; millisecondsToMine: 5000
//Iron-plate: useless, bug: you can mine furnace while iron-plate in there and the iron-plate dissapears; placable: false; minable: true; infinite: true; smeltable: false; fuel: false; smelted: null; millisecondsToMine: 5000
//Coal: fuel for smelting; placable: false; minable: true; infinite: true; smeltable: false; fuel: true; smelted: null; millisecondsToMine: 5000
//Empty: specially treated item; used to represent nothing; placable: false; minable: false; infinite: true; smeltable: false; fuel: false; smelted: null; millisecondsToMine: 5000

abstract class Item {
  GridCell get paintedCell;
  bool get placable => false;
  bool get minable => true;
  bool get infinite => !placable;
  bool get smeltable => false;
  bool get fuel => false;
  Item get smelted => null;
  int get millisecondsToMine => 5000;
  Item copy();
  Widget ui(void Function(Item) setCS, Item cs,
          void Function(void Function()) setState, void Function(int l) newLevelIfL) =>
      Text(runtimeType.toString() + "selected");
}

class FurnaceItem extends Item {
  FurnaceItem();

  String toString() => "furnace[$holding & $fuelcell => $produced]";

  GridCell get paintedCell => FurnaceGridCell();

  bool get placable => true;

  Item holding = EmptyItem();
  Item fuelcell = EmptyItem();
  double value = 0;
  Item produced = EmptyItem();
  Timer timer;

  int get millisecondsToMine => 1000;

  Widget ui(void Function(Item) setCursorStack, Item cursorStack,
          void Function(void Function()) setState, void Function(int l) newLevelIfL) =>
      Container(
        color: Colors.grey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              child: GridDrawer([holding.paintedCell], 1, kCellDim),
              onTap: () {
                setState(() {
                  if (holding is EmptyItem && cursorStack.smeltable) {
                    holding = cursorStack;
                    setCursorStack(null);
                    timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
                      setState(() {
                        if (fuelcell is! EmptyItem) value += .02;
                      });
                      print(value);
                      if (value >= 1) {
                        timer.cancel();
                        timer = null;
                        setState(() {
                          print("HII");
                          produced = holding.smelted;
                          holding = EmptyItem();
                          fuelcell = EmptyItem();
                          value = 0;
                          newLevelIfL(14);
                        });
                      }
                    });
                  }
                });
              },
            ),
            GestureDetector(
              child: GridDrawer([fuelcell.paintedCell], 1, kCellDim),
              onTap: () {
                setState(() {
                  if (fuelcell is EmptyItem && cursorStack.fuel) {
                    fuelcell = cursorStack;
                    setCursorStack(null);
                  }
                });
              },
            ),
            Container(
              width: 100,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.yellow),
                value: value,
              ),
            ),
            GestureDetector(
              child: GridDrawer([produced.paintedCell], 1, kCellDim),
              onTap: () {
                if (cursorStack == null && produced is! EmptyItem) {
                  setState(() {
                    setCursorStack(produced);
                    produced = EmptyItem();
                    newLevelIfL(15);
                  });
                }
              },
            ),
          ],
        ),
      );

  Item copy() => FurnaceItem();
}

class FurnaceGridCell extends GridCell {
  void paint(Canvas canvas, Size size, Offset offset) {
    Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.moveTo(offset.dx + size.width, offset.dy + size.height);
    path.lineTo(offset.dx, offset.dy + size.height);
    path.lineTo(offset.dx + size.width / 2, offset.dy);
    Paint paint = Paint()..color = Colors.orange;
    canvas.drawPath(path, paint);
    canvas.drawCircle((offset & size).center - Offset(5, 0), 2, Paint()..color = Colors.black);
    canvas.drawCircle((offset & size).center + Offset(5, 0), 2, Paint()..color = Colors.black);
    canvas.drawLine((offset & size).center + Offset(5, 10), (offset & size).center + Offset(0, 15), Paint()..color = Colors.black);
    canvas.drawLine((offset & size).center + Offset(-5, 10), (offset & size).center + Offset(0, 15), Paint()..color = Colors.black);
     canvas.drawLine((offset & size).center + Offset(5, 10), (offset & size).center + Offset(5, 15), (Paint()..color = Colors.red)..strokeWidth = 2);
  }
}

class IronOreItem extends Item {
  GridCell get paintedCell => IronOreGridCell();

  String toString() => "iron";

  bool get smeltable => true;
  Item get smelted => IronPlateItem();

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

  String toString() => "stone";

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

class IronPlateItem extends Item {
  GridCell get paintedCell => IronPlateGridCell();

  String toString() => "iron-plate";

  Item copy() => IronPlateItem();
}

class IronPlateGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(
      offset & size,
      Paint()..color = Colors.blue,
    );
    if (debugPaintSizeEnabled) {
      canvas.drawCircle(offset, 5, Paint()..color = Colors.green);
    }
  }
}

class CoalItem extends Item {
  GridCell get paintedCell => CoalGridCell();

  String toString() => "coal";

  CoalItem copy() => CoalItem();

  bool get fuel => true;
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

class EmptyItem extends Item {
  GridCell get paintedCell => EmptyGridCell();
  String toString() => "<empty>";
  bool get minable => false;

  Item copy() => EmptyItem();
}

class EmptyGridCell extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {}
}
