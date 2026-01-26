import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class NavigationBarPage extends StatefulWidget {
  const NavigationBarPage(this.pages, {super.key});

  final List<Widget> pages;

  @override
  State<NavigationBarPage> createState() => _NavigationBarPageState();
}

class _NavigationBarPageState extends State<NavigationBarPage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Icons.add),
            icon: Icon(Symbols.add_2_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.key),
            icon: Icon(Symbols.key_rounded),
            label: 'Secret Manager',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: widget.pages[currentPageIndex],
    );
  }
}
