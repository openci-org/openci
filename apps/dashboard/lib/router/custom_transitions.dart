import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FastBottomSheetPage<T> extends CustomTransitionPage<T> {
  FastBottomSheetPage({
    required super.child,
    super.key,
    Duration duration = const Duration(milliseconds: 150),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (_, animation, _, child) {
           return SlideTransition(
             position: animation.drive(
               Tween<Offset>(
                 begin: const Offset(0, 1),
                 end: Offset.zero,
               ).chain(CurveTween(curve: Curves.easeOutCubic)),
             ),
             child: child,
           );
         },
       );
}
