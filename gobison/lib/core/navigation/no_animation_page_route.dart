import 'package:flutter/material.dart';

class NoAnimationPageRoute<T> extends PageRouteBuilder<T> {
  NoAnimationPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return child;
         },
         transitionDuration: Duration.zero,
         reverseTransitionDuration: Duration.zero,
         opaque: true,
       );
}
