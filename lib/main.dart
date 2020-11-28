import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool inventory = false;

  List<Item> board = List.filled(100, EmptyItem(), growable: true);
  int boardW = 10;

  int tutorialLevel = 0;
  int stoneMined = 0;
  List<String> texts = [
    "Hello, welcome to Explorer. You are the orange ball. To move, use WASD (not arrow keys!). Move to the right 9 times.",
    "Now hold the v key until the bar at the bottom fills up while hovering over the blue squares with your mouse (they're supposed to be iron).",
    "You have mined some iron! Press e to open the inventory. You can close it with e too.",
    "Put the iron in your inventory by clicking on a square.",
    "Mine three stone, or brown squares, like that (and put them in your inventory)",
    "Tap the Add to recipe button (at the left of the inventory) holding a stone.",
    "Do that 2 more times",
    "Now take out the orange triangle (a furnace).",
    "Place it by clicking on a square in the board.",
    "Now mine it.",
    "Place it again.",
    "Mine some coal (the black squares).",
    "Put it in the inventory.",
    "Tap on the furnace.",
    "Put the iron and coal in the slots at the left of the gray rectangle (not far left).",
    "Take the iron plate (the blue square) out.",
    "The end (for now)."
  ];

  //cursor stack
  Item cursorStack;
  Offset cursorPosition;

  //random inventory
  final Random r = Random();
  final List<Item Function()> possibleItems = [
    () => EmptyItem(),
  ];

  Item dialog;

  //mining
  Timer miningTimer;
  int miningMilliseconds = 0;
  Completer<bool> mined;
  Item thingMining;

  //player
  int playerX = 0;
  int playerY = 0;

  void initState() {
    super.initState();
    //print("neWI");
    inventoryItems = List.generate(
      100,
      (index) => possibleItems[r.nextInt(possibleItems.length)](),
    );
  }

  int numb = 0;
  Item get expanding {
    if (tutorialLevel == 0) {
      tutorialLevel++;
      return IronOreItem();
    } else {
      if (numb == 0) {
        numb++;
        return CoalItem();
      }
      if (numb == 1) {
        numb++;
        return StoneItem();
      }
      return EmptyItem();
    }
  }

  bool onKey(FocusNode focusNode, RawKeyEvent event) {
    switch (event.character) {
      case "e":
        setState(() {
          inventory = !inventory;
          if (tutorialLevel == 2) tutorialLevel++;
        });
        break;
      case "w":
        setState(() {
          if (playerY != 0) playerY--;
        });
        break;
      case "a":
        setState(() {
          if (playerX != 0) playerX--;
        });
        break;
      case "d":
        setState(() {
          playerX++;
          if (playerX + 1 == boardW) {
            int offset = 0;
            int bL = board.length;
            for (int y = 1; y <= bL / boardW; y++) {
              board.insert((y * boardW + offset), expanding);
              offset++;
            }
            boardW++;
          }
        });
        break;
      case "s":
        setState(() {
          playerY++;
          if (playerY + 1 == board.length / boardW) {
            for (int x = 0; x < boardW; x++) {
              board.add(expanding);
            }
          }
        });
        break;
      case "v":
        //print("got v");
        setState(() {
          if (cursorStack != null) return;
          int boardX = (cursorPosition.dx / kCellDim).floor();
          int boardY = (cursorPosition.dy / kCellDim).floor();
          if (boardX > boardW) return;
          if (boardY > board.length / boardW) return;
          Item thing = board[boardX + boardY * boardW];
          if (!thing.minable) return;
          thingMining = thing;
          if (miningTimer != null) return;
          mined = Completer();
          miningTimer = Timer.periodic(
            Duration(milliseconds: 20),
            (_) {
              setState(() {
                miningMilliseconds += 20;
              });
              //print(miningMilliseconds);
              if (miningMilliseconds == thing.millisecondsToMine) {
                miningTimer?.cancel();
                miningTimer = null;
                mined?.complete(true);
                //print("completed: ${mined.isCompleted}");
                mined = null;
                setState(() {
                  miningMilliseconds = 0;
                  cursorStack = thing.copy();
                  if (tutorialLevel == 1 && thingMining is IronOreItem) {
                    tutorialLevel++;
                  }
                  if (tutorialLevel == 9 && thingMining is FurnaceItem) {
                    tutorialLevel++;
                  }
                  if (tutorialLevel == 11 && thingMining is CoalItem) {
                    tutorialLevel++;
                  }
                  if (tutorialLevel == 4 && thingMining is StoneItem) {
                    stoneMined++;
                    if (stoneMined % 3 == 0) {
                      tutorialLevel++;
                    }
                  }
                });
              }
            },
          );
          if (thing.infinite) return;
          //print("!infinite");
          mined.future.then((bool value) {
            //print("got $value");
            setState(() {
              //print("!!!: $value");
              if (value) board[boardX + boardY * boardW] = EmptyItem();
            });
          });
        });
        break;
      default:
        if (event is RawKeyUpEvent && event.logicalKey.keyLabel == "v") {
          miningTimer?.cancel();
          miningTimer = null;
          mined?.complete(false);
          mined = null;
          miningMilliseconds = 0;
        } else if (event is RawKeyUpEvent) {
        } else {
          print("Unknown key $event.");
        }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    //print("rebuild: $miningMilliseconds ${thingMining?.millisecondsToMine}");
    return Scaffold(
      body: Center(
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
                onKey: onKey,
                child: Builder(builder: (BuildContext context) {
                  FocusNode node = Focus.of(context);
                  try {
                    return node.hasFocus
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ListView(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                children: [
                                  LayoutBuilder(
                                    builder: (BuildContext context,
                                            BoxConstraints _) =>
                                        //ListView(
                                        //height: constraints.maxHeight,
                                        SizedBox(
                                      height: max(
                                          (board.length / boardW) * kCellDim,
                                          constraints.maxHeight),
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        children: [
                                          GestureDetector(
                                            onTapDown:
                                                (TapDownDetails details) {
                                              if (cursorStack == null) {
                                                int boardX =
                                                    (details.localPosition.dx /
                                                            kCellDim)
                                                        .floor();
                                                int boardY =
                                                    (details.localPosition.dy /
                                                            kCellDim)
                                                        .floor();
                                                if (boardX > boardW) return;
                                                if (boardY >
                                                    board.length / boardW)
                                                  return;
                                                setState(() {
                                                  if (tutorialLevel == 13)
                                                    tutorialLevel++;
                                                  dialog = board[
                                                      boardX + boardY * boardW];
                                                });
                                                return;
                                              }
                                              if (!cursorStack.placable) return;
                                              int boardX =
                                                  (details.localPosition.dx /
                                                          kCellDim)
                                                      .floor();
                                              int boardY =
                                                  (details.localPosition.dy /
                                                          kCellDim)
                                                      .floor();
                                              if (boardX > boardW) return;
                                              if (boardY >
                                                  board.length / boardW) return;
                                              if (board[
                                                      boardX + boardY * boardW]
                                                  is! EmptyItem) return;
                                              setState(() {
                                                board[boardX +
                                                        boardY * boardW] =
                                                    cursorStack;
                                                cursorStack = null;
                                                if (tutorialLevel == 8 ||
                                                    tutorialLevel == 10)
                                                  tutorialLevel++;
                                              });
                                            },
                                            child: GridDrawer(
                                              board
                                                  .map((e) => e.paintedCell)
                                                  .toList(),
                                              boardW,
                                              kCellDim,
                                              playerX,
                                              playerY,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              inventory
                                  ? Center(
                                      child: Inventory(
                                        kCellDim,
                                        inventoryItems,
                                        kInventoryGridWidth,
                                        () => cursorStack,
                                        (Item x) => setState(()=>cursorStack = x),
                                        (int x) => x == tutorialLevel
                                            ? tutorialLevel++
                                            : null,
                                        onTap: (Item x) {
                                          setState(() {
                                            if (cursorStack == null &&
                                                x is! EmptyItem) {
                                              cursorStack = x;
                                              inventoryItems[inventoryItems
                                                  .indexOf(x)] = EmptyItem();
                                              if (x is FurnaceItem &&
                                                  (tutorialLevel == 10)) {
                                                tutorialLevel++;
                                              }
                                            } else if (x is EmptyItem &&
                                                cursorStack != null) {
                                              inventoryItems[inventoryItems
                                                  .indexOf(x)] = cursorStack;
                                              if (tutorialLevel == 3 &&
                                                  cursorStack is IronOreItem)
                                                tutorialLevel++;
                                              if (tutorialLevel == 12 &&
                                                  cursorStack is CoalItem) {
                                                tutorialLevel++;
                                              }
                                              cursorStack = null;
                                            }
                                          });
                                        },
                                      ),
                                    )
                                  : Container(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  dialog?.ui(
                                          (Item cS) => setState(
                                                () => cursorStack = cS,
                                              ),
                                          cursorStack,
                                          setState,
                                          (int l) => tutorialLevel == l
                                              ? tutorialLevel++
                                              : null) ??
                                      Container(),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: LinearProgressIndicator(
                                      minHeight: 10,
                                      value: ((miningMilliseconds ?? 0) /
                                              (thingMining
                                                      ?.millisecondsToMine ??
                                                  1000))
                                          .toDouble(),
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.yellow),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      color: Colors.grey.withOpacity(.5),
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          texts[tutorialLevel],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                        : FlatButton(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Explorer 1.0 out now, along with Thanksgiving Edition!",
                                ),
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
    );
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
