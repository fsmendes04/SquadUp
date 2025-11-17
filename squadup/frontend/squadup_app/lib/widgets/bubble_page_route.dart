import 'package:flutter/material.dart';
import 'dart:math';

class BubblePageRoute extends PageRouteBuilder {
  final Widget page;
  final Offset bubbleCenter;
  final Color bubbleColor;

  BubblePageRoute({
    required this.page,
    required this.bubbleCenter,
    this.bubbleColor = Colors.blue,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 700),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            final maxRadius = sqrt(size.width * size.width + size.height * size.height);
            final radius = animation.value * maxRadius;
            return ClipPath(
              clipper: BubbleClipper(bubbleCenter, radius),
              child: Container(
                color: bubbleColor,
                child: child,
              ),
            );
          },
        ),
      ],
    );
  }
}

class BubbleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  BubbleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(BubbleClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
