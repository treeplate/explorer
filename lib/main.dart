import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cells.dart';
import 'world_render.dart';
import 'grid.dart';

const int kGridWidth = 21;
const int kGridHeight = 12;

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
  List<Cell> grid;

  //cursor stack

  TextEditingController textFieldA = TextEditingController(text: 'temp');
  TextEditingController textFieldB = TextEditingController(text: '0');
  Cell cursorStack;
  Offset cursorPosition;

  final List<Cell> hotbar = [
    MoveCell(Direction(1, 0), false),
    MoveCell(Direction(0, 1), false),
    MoveCell(Direction(-1, 0), false),
    MoveCell(Direction(0, -1), false),
    MoveableCell(false),
    ImmoveableCell(false),
    SlideCell(true, false),
    SlideCell(false, false),
    RotateCWCell(false),
    RotateCCWCell(false),
    EnemyCell(false),
    GeneratorCell(Direction(1, 0), false),
    GeneratorCell(Direction(0, 1), false),
    GeneratorCell(Direction(-1, 0), false),
    GeneratorCell(Direction(0, -1), false),
    TrashCell(false),
  ];

  String get levelText => texts[int.parse(textFieldB.value.text)];

  List<String> texts = [
    "Press 'Load Level' to load the level specified\nClick on a cell in the hotbar to pick it up\nClick on the grid to drop it\nPress 'Pause/Play' to start the simulation\nThe goal is to destroy all red\nReds, when something touches it, disappear along with the thing that touched it\nTry placing a turkey to start!",
    "Yellows can be pushed by turkeys",
    "Black is impassable",
    "Sliders (the yellows with lines) can only be pushed in that direction",
    "Rotators rotate things next to them",
    "Generators (greens) generate more of what comes at the bottom, at the top",
    "Purple is like red, but indestructible"
  ];

  void initState() {
    super.initState();
    //print("neWI");
    grid = List.generate(
      kGridWidth * kGridHeight,
      (index) => EmptyCell(false),
    );
  }

  Timer timer;
  void tick([_]) {
    setState(() {
      for (Cell cell in grid) {
        cell.ticked = false;
      }
      for (int y = 0; y < kGridHeight; y++) {
        for (int x = 0; x < kGridWidth; x++) {
          if (grid[x + y * kGridWidth] is MoveCell) {
            moveCellAt(x, y);
          }
        }
      }
      for (int y = 0; y < kGridHeight; y++) {
        for (int x = 0; x < kGridWidth; x++) {
          if (grid[x + y * kGridWidth] is GeneratorCell) {
            moveCellAt(x, y);
          }
        }
      }
      for (int y = 0; y < kGridHeight; y++) {
        for (int x = 0; x < kGridWidth; x++) {
          if (grid[x + y * kGridWidth] is RotateCWCell ||
              grid[x + y * kGridWidth] is RotateCCWCell) {
            moveCellAt(x, y);
          }
        }
      }
    });
  }

  bool moveCellAt(int x, int y, {Direction moveTo}) {
    Cell current = grid[x + y * kGridWidth];
    Direction dir;
    if (moveTo != null) {
      dir = current.pushed(moveTo);
      if (current is EnemyCell) {
        grid[x + y * kGridWidth] = EmptyCell(current.setInStone);
      }
      if (current is TrashCell || current is EnemyCell) {
        grid[(x - moveTo.x) + (y - moveTo.y) * kGridWidth] =
            EmptyCell(current.setInStone);
      }
    } else {
      if (current.ticked) {
        //print("$x,$y has already ticked!");
        return false;
      }
      current.ticked = true;
      dir = current.doMove();
      if (current is RotateCWCell) {
        rotateCellAt(x, y - 1);
        rotateCellAt(x + 1, y);
        rotateCellAt(x, y + 1);
        rotateCellAt(x - 1, y);
      }
      if (current is RotateCCWCell) {
        rotateCellAt(x, y - 1);
        rotateCellAt(x, y - 1);
        rotateCellAt(x, y - 1);
        rotateCellAt(x + 1, y);
        rotateCellAt(x + 1, y);
        rotateCellAt(x + 1, y);
        rotateCellAt(x - 1, y);
        rotateCellAt(x - 1, y);
        rotateCellAt(x - 1, y);
        rotateCellAt(x, y + 1);
        rotateCellAt(x, y + 1);
        rotateCellAt(x, y + 1);
      }
      if (current is GeneratorCell) {
        int copiedX = x - current.moveDir.x;
        int copiedY = y - current.moveDir.y;
        int newX = x + current.moveDir.x;
        int newY = y + current.moveDir.y;
        if (newX < 0 || newX >= kGridWidth || newY < 0 || newY >= kGridHeight) {
          //print("Out of bounds!");
          return false;
        }
        if (copiedX < 0 ||
            copiedX >= kGridWidth ||
            copiedY < 0 ||
            copiedY >= kGridHeight) {
          //print("Out of bounds!");
          return false;
        }
        Cell copied = grid[copiedX + copiedY * kGridWidth];
        if (copied is EmptyCell) {
          return false;
        }
        if (grid[newX + newY * kGridWidth] is! EmptyCell) {
          if (!moveCellAt(newX, newY, moveTo: current.moveDir)) {
            //print("($x,$y)'s front can't move!");
            return true;
          }
        }
        grid[newX + newY * kGridWidth] = copied.copy()..ticked = true;
        return true;
      }
    }
    if (dir.x == 0 && dir.y == 0) {
      return moveTo == null;
    }
    //print("Moving ${dir.x}, ${dir.y} ");
    int newX = x + dir.x;
    int newY = y + dir.y;
    if (newX < 0 || newX >= kGridWidth || newY < 0 || newY >= kGridHeight) {
      //print("Out of bounds!");
      return false;
    }
    if (grid[newX + newY * kGridWidth] is TrashCell) {
      grid[x + y * kGridWidth] = EmptyCell(current.setInStone);
      return true;
    }
    if (grid[newX + newY * kGridWidth] is! EmptyCell) {
      if (!moveCellAt(newX, newY, moveTo: dir)) {
        //print("($x,$y)'s front can't move!");
        return false;
      }
    }
    grid[x + y * kGridWidth] = EmptyCell(current.setInStone);
    grid[newX + newY * kGridWidth] = current;
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
                                      Text(levelText),
                                      World(
                                        kCellDim,
                                        grid,
                                        kGridWidth,
                                        () => cursorStack,
                                        onTap: (Cell x) {
                                          setState(() {
                                            if (cursorStack == null &&
                                                x is! EmptyCell &&
                                                !x.setInStone) {
                                              cursorStack = x;
                                              grid[grid.indexOf(x)] =
                                                  EmptyCell(x.setInStone);
                                            } else if (x is EmptyCell &&
                                                cursorStack != null &&
                                                !x.setInStone) {
                                              grid[grid.indexOf(x)] =
                                                  cursorStack;
                                              cursorStack = null;
                                            }
                                          });
                                        },
                                      ),
                                      World(
                                        kCellDim,
                                        hotbar,
                                        hotbar.length,
                                        () => cursorStack,
                                        onTap: (Cell x) {
                                          setState(() {
                                            if (cursorStack == null) {
                                              cursorStack = x.copy();
                                            } else {
                                              cursorStack = null;
                                            }
                                          });
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Pause/Play"),
                                        onPressed: () {
                                          if (timer == null) {
                                            timer = Timer.periodic(
                                                Duration(milliseconds: 250),
                                                tick);
                                          } else {
                                            timer.cancel();
                                            timer = null;
                                          }
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Clear screen"),
                                        onPressed: () {
                                          grid = List.generate(
                                            kGridWidth * kGridHeight,
                                            (index) => EmptyCell(false),
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        child: TextField(
                                          controller: textFieldA,
                                          decoration: InputDecoration(
                                            labelText: "File to save/load",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        width: 150,
                                        height: 20,
                                      ),
                                      TextButton(
                                        child: Text("Save to file"),
                                        onPressed: () {
                                          File(textFieldA.value.text)
                                            ..createSync()
                                            ..writeAsStringSync(grid.join(''));
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Load from file"),
                                        onPressed: () {
                                          grid = File(textFieldA.value.text)
                                              .readAsStringSync()
                                              .split('')
                                              .map((e) => parse(e, true))
                                              .toList();
                                        },
                                      ),
                                      SizedBox(
                                        child: TextField(
                                          controller: textFieldB,
                                          decoration: InputDecoration(
                                            labelText: "Level number (0-**)",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        width: 150,
                                        height: 20,
                                      ),
                                      TextButton(
                                        child: Text("Load level"),
                                        onPressed: () async {
                                          grid = (await rootBundle.loadString(
                                                  'levels/level-'+textFieldB.value.text))
                                              .split('')
                                              .map((e) => parse(e, true))
                                              .toList();
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
    if (x < 0 || x >= kGridWidth || y < 0 || y >= kGridHeight) {
      return;
    }

    grid[x + y * kGridWidth] = grid[x + y * kGridWidth].rotatedCW()
      ..ticked = grid[x + y * kGridWidth].ticked;
  }
}

class CursorStack extends CustomPainter {
  CursorStack(this.position, this.cell);
  final Offset position;
  final Cell cell;

  bool shouldRepaint(CursorStack old) =>
      position != old.position || cell != old.cell;

  void paint(Canvas canvas, Size size) {
    //print(size);
    cell.paintedCell.paint(
      canvas,
      Size(kCellDim, kCellDim),
      position - Offset(kCellDim / 2, kCellDim / 2),
    );
  }
}
