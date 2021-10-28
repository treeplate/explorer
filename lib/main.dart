import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'items.dart';
import 'inventory.dart';
import 'grid.dart';

const int kInventoryGridWidth = 10;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //inventory
  List<Item> inventoryItems;

  //cursor stack
  Item cursorStack;
  Offset cursorPosition;

  //random inventory
  final Random r = Random();
  final List<Item Function()> possibleItems = [
    () => EmptyItem(),
  ];

  final List<Item> hotbar = [
    MoveItem(Direction(1, 0)),
    MoveItem(Direction(0, 1)),
    MoveItem(Direction(-1, 0)),
    MoveItem(Direction(0, -1)),
    MoveableItem(),
    ImmoveableItem(),
    SlideItem(true),
    SlideItem(false),
    RotateCWItem(),
  ];

  Item dialog;

  void initState() {
    super.initState();
    //print("neWI");
    inventoryItems = List.generate(
      kInventoryGridWidth * 10,
      (index) => possibleItems[r.nextInt(possibleItems.length)](),
    );
  }

  void tick() {
    setState(() {
      for (Item item in inventoryItems) {
        item.ticked = false;
      }
      for (int y = 0; y < 10; y++) {
        for (int x = 0; x < kInventoryGridWidth; x++) {
          moveCellAt(x, y);
        }
      }
    });
  }

  bool moveCellAt(int x, int y, {Direction moveTo}) {
    Item current = inventoryItems[x + y * kInventoryGridWidth];
    Direction dir;
    if (moveTo != null) {
      dir = current.pushed(moveTo);
    } else {
      if (current.ticked) {
        //print("$x,$y has already ticked!");
        return false;
      }
      current.ticked = true;
      dir = current.doMove();
      if (current is RotateCWItem) {
        rotateCellAt(x, y-1);
        rotateCellAt(x+1, y);
        rotateCellAt(x, y+1);
        rotateCellAt(x-1, y);
      }
    }
    if (dir.x == 0 && dir.y == 0) {
      return moveTo == null;
    }
    //print("Moving ${dir.x}, ${dir.y} ");
    int newX = x + dir.x;
    int newY = y + dir.y;
    if (newX < 0 || newX >= kInventoryGridWidth || newY < 0 || newY >= 10) {
      //print("Out of bounds!");
      return false;
    }
    if (inventoryItems[newX + newY * kInventoryGridWidth] is! EmptyItem) {
      if (!moveCellAt(newX, newY, moveTo: dir)) {
        //print("($x,$y)'s front can't move!");
        return false;
      }
    }
    inventoryItems[x + y * kInventoryGridWidth] = EmptyItem();
    inventoryItems[newX + newY * kInventoryGridWidth] = current;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.brown[400],
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                MouseRegion(
              onHover: (PointerHoverEvent event) {
                setState(() {
                  cursorPosition = event.position;
                });
              },
              child: FocusScope(
                autofocus: true,
                child: Focus(
                  child: Builder(builder: (BuildContext context) {
                    FocusNode node = Focus.of(context);
                    try {
                      return node.hasFocus
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      Inventory(
                                        kCellDim,
                                        inventoryItems,
                                        kInventoryGridWidth,
                                        () => cursorStack,
                                        onTap: (Item x) {
                                          setState(() {
                                            if (cursorStack == null &&
                                                x is! EmptyItem) {
                                              cursorStack = x;
                                              inventoryItems[inventoryItems
                                                  .indexOf(x)] = EmptyItem();
                                            } else if (x is EmptyItem &&
                                                cursorStack != null) {
                                              inventoryItems[inventoryItems
                                                  .indexOf(x)] = cursorStack;
                                              cursorStack = null;
                                            }
                                          });
                                        },
                                      ),
                                      Inventory(
                                        kCellDim,
                                        hotbar,
                                        hotbar.length,
                                        () => cursorStack,
                                        onTap: (Item x) {
                                          setState(() {
                                            if (cursorStack == null) {
                                              cursorStack = x.copy();
                                            } else {
                                              cursorStack = null;
                                            }
                                          });
                                        },
                                      ),
                                      FloatingActionButton(onPressed: tick),
                                      FloatingActionButton(
                                        onPressed: () {
                                          inventoryItems = List.generate(
                                            kInventoryGridWidth * 10,
                                            (index) => EmptyItem(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                IgnorePointer(
                                  child: cursorStack == null ||
                                          cursorPosition == null
                                      ? Container()
                                      : CustomPaint(
                                          size: Size(
                                            constraints.maxWidth,
                                            constraints.maxHeight,
                                          ),
                                          painter: CursorStack(
                                            cursorPosition,
                                            cursorStack,
                                          ),
                                        ),
                                ),
                              ],
                            )
                          : TextButton(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Press to start"),
                                ],
                              ),
                              onPressed: node.requestFocus);
                    } catch (e, st) {
                      print("ERROR: $e, $st");
                      return Center(
                        child: Text("The end"),
                      );
                    }
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void rotateCellAt(int x, int y) {
    if (x < 0 || x >= kInventoryGridWidth || y < 0 || y >= 10) {
      return;
    }
    inventoryItems[x + y * kInventoryGridWidth] = inventoryItems[x + y * kInventoryGridWidth].rotatedCW()..ticked = inventoryItems[x + y * kInventoryGridWidth].ticked;
  }
}

class CursorStack extends CustomPainter {
  CursorStack(this.position, this.item);
  final Offset position;
  final Item item;

  bool shouldRepaint(CursorStack old) =>
      position != old.position || item != old.item;

  void paint(Canvas canvas, Size size) {
    //print(size);
    item.paintedCell.paint(
      canvas,
      Size(kCellDim, kCellDim),
      position - Offset(kCellDim / 2, kCellDim / 2),
    );
  }
}
