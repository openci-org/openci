import 'dart:collection';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const List<String> list = <String>['One', 'Two', 'Three', 'Four'];

typedef MenuEntry = DropdownMenuEntry<String>;

class DotGridPainter extends CustomPainter {
  final double dotSpacing;
  final double dotRadius;
  final Color dotColor;

  DotGridPainter({
    this.dotSpacing = 20,
    this.dotRadius = 1.5,
    this.dotColor = const Color(0xFFCCCCCC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += dotSpacing) {
      for (double y = 0; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MyHomePageState extends State<MyHomePage> {
  static final List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    list.map<MenuEntry>((String name) => MenuEntry(value: name, label: name)),
  );
  String dropdownValue = list.first;
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            constrained: false,
            boundaryMargin: EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: SizedBox(
                        width: 260,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            spacing: 20.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Basic Info",
                                style: TextStyle(fontSize: 24),
                              ),
                              DropdownMenu<String>(
                                width: 160,
                                label: Text("Repository"),
                                initialSelection: list.first,
                                onSelected: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                                dropdownMenuEntries: menuEntries,
                              ),
                              DropdownMenu<String>(
                                width: 160,
                                label: Text("Current Working Directory"),
                                initialSelection: list.first,
                                onSelected: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                                dropdownMenuEntries: menuEntries,
                              ),
                              DropdownMenu<String>(
                                width: 160,
                                label: Text("Trigger"),
                                initialSelection: list.first,
                                onSelected: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                                dropdownMenuEntries: menuEntries,
                              ),
                              DropdownMenu<String>(
                                width: 160,
                                label: Text("Trigger Branch"),
                                initialSelection: list.first,
                                onSelected: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                                dropdownMenuEntries: menuEntries,
                              ),
                              DropdownMenu<String>(
                                width: 160,
                                label: Text("Machine Type"),
                                initialSelection: list.first,
                                onSelected: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                                dropdownMenuEntries: menuEntries,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(Icons.arrow_downward_rounded, size: 40),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isHovering = true),
                      onExit: (_) => setState(() => _isHovering = false),
                      child: Container(
                        color: _isHovering
                            ? Colors.grey[100]
                            : Colors.transparent,
                        foregroundDecoration: DottedDecoration(
                          shape: Shape.box,
                          borderRadius: BorderRadius.circular(4),
                          strokeWidth: 1,
                          dash: const [4, 4],
                          color: Colors.black,
                        ),
                        width: 260,
                        height: 100,
                        child: Center(child: Text("Next Action")),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
