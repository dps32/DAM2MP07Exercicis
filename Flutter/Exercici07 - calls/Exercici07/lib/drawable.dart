import 'dart:math';
import 'package:flutter/material.dart';

enum FillGradient { none, linear, radial }

abstract class Drawable {
  final int id;
  bool selected;

  Drawable({required this.id, this.selected = false});

  void draw(Canvas canvas);
  bool hitTest(Offset point);
  void update(Map<String, dynamic> values);

  Paint strokePaint(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
  }

  Paint fillPaint(
      Rect bounds, Color color, FillGradient gradient, Color? gradientTo) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (gradient == FillGradient.linear && gradientTo != null) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, gradientTo],
      ).createShader(bounds);
    } else if (gradient == FillGradient.radial && gradientTo != null) {
      paint.shader =
          RadialGradient(colors: [color, gradientTo]).createShader(bounds);
    } else {
      paint.color = color;
    }
    return paint;
  }

  void drawSelection(Canvas canvas, Rect rect) {
    if (!selected) {
      return;
    }
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.inflate(4), paint);
  }
}

class Line extends Drawable {
  Offset start;
  Offset end;
  Color color;
  double strokeWidth;

  Line({
    required super.id,
    required this.start,
    required this.end,
    this.color = Colors.black,
    this.strokeWidth = 2,
  });

  @override
  void draw(Canvas canvas) {
    canvas.drawLine(start, end, strokePaint(color, strokeWidth));
    drawSelection(canvas, Rect.fromPoints(start, end));
  }

  @override
  bool hitTest(Offset point) {
    final length = (end - start).distance;
    if (length == 0) {
      return (point - start).distance <= strokeWidth + 6;
    }
    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        pow(length, 2);
    final clamped = t.clamp(0.0, 1.0);
    final closest = Offset(
      start.dx + (end.dx - start.dx) * clamped,
      start.dy + (end.dy - start.dy) * clamped,
    );
    return (point - closest).distance <= max(strokeWidth + 6, 10);
  }

  @override
  void update(Map<String, dynamic> values) {
    if (values['start'] is Offset) start = values['start'];
    if (values['end'] is Offset) end = values['end'];
    if (values['color'] is Color) color = values['color'];
    if (values['strokeWidth'] is double) strokeWidth = values['strokeWidth'];
  }
}




class RectangleShape extends Drawable {
  Offset topLeft;
  Offset bottomRight;
  Color strokeColor;
  Color fillColor;
  Color? gradientTo;
  double strokeWidth;
  FillGradient gradient;

  RectangleShape({
    required super.id,
    required this.topLeft,
    required this.bottomRight,
    this.strokeColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.gradientTo,
    this.strokeWidth = 2,
    this.gradient = FillGradient.none,
  });

  Rect get rect => Rect.fromPoints(topLeft, bottomRight);

  @override
  void draw(Canvas canvas) {
    final r = rect;
    if (fillColor.a > 0 || gradient != FillGradient.none) {
      canvas.drawRect(r, fillPaint(r, fillColor, gradient, gradientTo));
    }
    canvas.drawRect(r, strokePaint(strokeColor, strokeWidth));
    drawSelection(canvas, r);
  }

  @override
  bool hitTest(Offset point) {
    return rect.inflate(max(strokeWidth, 8)).contains(point);
  }

  @override
  void update(Map<String, dynamic> values) {
    if (values['topLeft'] is Offset) topLeft = values['topLeft'];
    if (values['bottomRight'] is Offset) bottomRight = values['bottomRight'];
    if (values['strokeColor'] is Color) strokeColor = values['strokeColor'];
    if (values['fillColor'] is Color) fillColor = values['fillColor'];
    if (values['gradientTo'] is Color?) gradientTo = values['gradientTo'];
    if (values['strokeWidth'] is double) strokeWidth = values['strokeWidth'];
    if (values['gradient'] is FillGradient) gradient = values['gradient'];
  }
}

class CircleShape extends Drawable {
  Offset center;
  double radius;
  Color strokeColor;
  Color fillColor;
  Color? gradientTo;
  double strokeWidth;
  FillGradient gradient;

  CircleShape({
    required super.id,
    required this.center,
    required this.radius,
    this.strokeColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.gradientTo,
    this.strokeWidth = 2,
    this.gradient = FillGradient.none,
  });

  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  void draw(Canvas canvas) {
    if (fillColor.a > 0 || gradient != FillGradient.none) {
      canvas.drawCircle(
        center,
        radius,
        fillPaint(bounds, fillColor, gradient, gradientTo),
      );
    }
    canvas.drawCircle(center, radius, strokePaint(strokeColor, strokeWidth));
    drawSelection(canvas, bounds);
  }

  @override
  bool hitTest(Offset point) {
    return (point - center).distance <= radius + max(strokeWidth, 8);
  }

  @override
  void update(Map<String, dynamic> values) {
    if (values['center'] is Offset) center = values['center'];
    if (values['radius'] is double) radius = values['radius'];
    if (values['strokeColor'] is Color) strokeColor = values['strokeColor'];
    if (values['fillColor'] is Color) fillColor = values['fillColor'];
    if (values['gradientTo'] is Color?) gradientTo = values['gradientTo'];
    if (values['strokeWidth'] is double) strokeWidth = values['strokeWidth'];
    if (values['gradient'] is FillGradient) gradient = values['gradient'];
  }
}

class TextElement extends Drawable {
  String text;
  Offset position;
  Color color;
  double fontSize;
  String fontFamily;
  FontWeight fontWeight;
  FontStyle fontStyle;

  TextElement({
    required super.id,
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 20,
    this.fontFamily = 'Arial',
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  TextPainter _painter() {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void draw(Canvas canvas) {
    final painter = _painter();
    painter.paint(canvas, position);
    drawSelection(canvas, position & painter.size);
  }

  @override
  bool hitTest(Offset point) {
    return (position & _painter().size).inflate(6).contains(point);
  }

  @override
  void update(Map<String, dynamic> values) {
    if (values['text'] is String) text = values['text'];
    if (values['position'] is Offset) position = values['position'];
    if (values['color'] is Color) color = values['color'];
    if (values['fontSize'] is double) fontSize = values['fontSize'];
    if (values['fontFamily'] is String) fontFamily = values['fontFamily'];
    if (values['fontWeight'] is FontWeight) fontWeight = values['fontWeight'];
    if (values['fontStyle'] is FontStyle) fontStyle = values['fontStyle'];
  }
}
