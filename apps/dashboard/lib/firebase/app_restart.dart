import 'package:flutter/material.dart';

/// Wraps the application root and provides a mechanism to force-rebuild the
/// entire widget tree.  Used after switching the Firebase project so that
/// every Riverpod provider is recreated with the new Firebase app instance.
class RestartWidget extends StatefulWidget {
  const RestartWidget({required this.child, super.key});

  final Widget child;

  /// Trigger a full application restart from anywhere in the tree.
  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
