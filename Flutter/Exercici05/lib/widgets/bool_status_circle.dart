import 'package:flutter/material.dart';

class BoolStatusCircle extends StatelessWidget {
  const BoolStatusCircle({
    super.key,
    required this.value,
    this.size = 14,
  });

  final bool value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BoolStatusCirclePainter(value),
    );
  }
}

class _BoolStatusCirclePainter extends CustomPainter {
  const _BoolStatusCirclePainter(this.value);

  final bool value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = value ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BoolStatusCirclePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
