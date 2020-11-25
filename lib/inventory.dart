import 'package:flutter/material.dart';

import 'grid.dart';
import 'items.dart';

class Inventory extends StatelessWidget {
  Inventory(
    this.cellDim,
    this.items,
    this.gridWidth,
    this.cursorStack,
    this.setCS,
    this.newLIfL, {
    @required this.onTap,
  });
  final double cellDim;

  final List<Item> items;
  final int gridWidth;
  final void Function(Item item) onTap;

  final Item Function() cursorStack;
  final void Function(Item) setCS;
  final void Function(int) newLIfL;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Crafting"),
              Recipe(
                [
                  StoneItem(),
                  StoneItem(),
                  StoneItem(),
                ],
                FurnaceItem(),
                cursorStack,
                setCS,
                newLIfL,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Inventory"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Recipe extends StatefulWidget {
  Recipe(this.ingredients, this.result, this.cursorStack, this.setCS,
      this.newLIfL);

  final List<Item> ingredients;
  final Item result;
  final Item Function() cursorStack;
  final void Function(Item) setCS;
  final void Function(int) newLIfL;

  @override
  _RecipeState createState() => _RecipeState();
}

class _RecipeState extends State<Recipe> {
  List<Item> neededINGRDNTS;
  Item result = EmptyItem();

  void initState() {
    super.initState();
    neededINGRDNTS = widget.ingredients;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            GridDrawer(
              neededINGRDNTS.map((e) => e.paintedCell).toList(),
              neededINGRDNTS.length,
              kCellDim,
            ),
            Text("=>"),
            GridDrawer([widget.result.paintedCell], 1, kCellDim)
          ],
        ),
        Row(
          children: [
            FlatButton(
              child: Text("Add to recipe"),
              onPressed: () {
                if (widget.cursorStack() != null) {
                  setState(() {
                    int i = neededINGRDNTS.indexWhere((element) =>
                        widget.cursorStack().runtimeType ==
                        element.runtimeType);
                    if (i == -1) return;
                    widget.newLIfL(5);
                    neededINGRDNTS.removeAt(i);
                    if (neededINGRDNTS.length == 0) {
                      result = widget.result;
                      neededINGRDNTS = widget.ingredients.toList();
                      widget.newLIfL(6);
                    }
                    widget.setCS(null);
                  });
                }
              },
            ),
            GestureDetector(
              child: GridDrawer(
                [result.paintedCell],
                1,
                kCellDim,
              ),
              onTap: () {
                if (widget.cursorStack() == null && result is! EmptyItem) {
                  setState(() {
                    widget.setCS(result);
                    result = EmptyItem();
                    widget.newLIfL(7);
                  });
                }
              },
            )
          ],
        ),
      ],
    );
  }
}
