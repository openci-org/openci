import 'package:flutter/material.dart';

class Root extends StatelessWidget {
  const Root(this.home, {super.key});
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: home);
  }
}
