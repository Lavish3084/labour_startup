import 'package:flutter/material.dart';

/// Symmetric concave scoops at both bottom corners (white curves up into green).
class ConcaveBottomHeaderClipper extends CustomClipper<Path> {
  final double radius;

  const ConcaveBottomHeaderClipper({this.radius = 40});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.arcToPoint(
      Offset(size.width - radius, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(radius, size.height - radius);
    path.arcToPoint(
      Offset(0, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ConcaveBottomHeaderClipper oldClipper) =>
      oldClipper.radius != radius;
}
