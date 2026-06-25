import 'package:flutter/material.dart';

class DotPatternPainter extends CustomPainter {
  final Color? color;
  final double spacing;
  final double radius;

  DotPatternPainter({this.color, this.spacing = 18.0, this.radius = 1.2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color ?? Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
