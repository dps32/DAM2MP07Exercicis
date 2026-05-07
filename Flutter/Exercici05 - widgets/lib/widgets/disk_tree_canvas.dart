import 'package:flutter/material.dart';
import 'package:exercici05/models/disk_tree_node.dart';
import 'package:exercici05/models/remote_entry.dart';

class DiskTreeCanvas extends StatelessWidget {
  const DiskTreeCanvas({
    super.key,
    required this.root,
  });

  final DiskTreeNode root;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DiskTreePainter(root),
        );
      },
    );
  }
}

class _DiskTreePainter extends CustomPainter {
  _DiskTreePainter(this.root);

  final DiskTreeNode root;
  final List<Color> _palette = <Color>[
    const Color(0xFF2E7D32),
    const Color(0xFF00695C),
    const Color(0xFF283593),
    const Color(0xFF6A1B9A),
    const Color(0xFFEF6C00),
    const Color(0xFFAD1457),
    const Color(0xFF0277BD),
    const Color(0xFF558B2F),
  ];


  

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF3F6FA);
    canvas.drawRect(Offset.zero & size, background);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final titlePainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      text: TextSpan(
        text: '${root.name}  (${formatBytes(root.size)})',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
    titlePainter.layout(maxWidth: size.width - 12);
    titlePainter.paint(canvas, const Offset(6, 6));

    if (root.children.isEmpty) {
      final emptyPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: const TextSpan(
          text: 'Sin datos',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
      emptyPainter.layout(maxWidth: size.width - 12);
      emptyPainter.paint(canvas, Offset(8, size.height / 2 - 8));
      return;
    }

    final graphRect = Rect.fromLTWH(
      fullRect.left + 4,
      fullRect.top + 26,
      fullRect.width - 8,
      fullRect.height - 30,
    );
    _paintChildren(canvas, graphRect, root.children, root.size, 0, true);
  }

  void _paintChildren(
    Canvas canvas,
    Rect area,
    List<DiskTreeNode> children,
    int totalSize,
    int depth,
    bool vertical,
  ) {
    if (children.isEmpty) {
      return;
    }

    var cursor = vertical ? area.left : area.top;
    var used = 0.0;
    var index = 0;

    for (final child in children) {
      index++;
      var ratio = 0.0;
      if (totalSize > 0) {
        ratio = child.size / totalSize;
      }
      if (ratio <= 0) {
        ratio = 1.0 / children.length;
      }

      var extent = (vertical ? area.width : area.height) * ratio;
      final isLast = index == children.length;
      if (isLast) {
        extent = (vertical ? area.width : area.height) - used;
      }

      Rect childRect;
      if (vertical) {
        childRect = Rect.fromLTWH(cursor, area.top, extent, area.height);
      } else {
        childRect = Rect.fromLTWH(area.left, cursor, area.width, extent);
      }

      cursor += extent;
      used += extent;

      final color = _palette[(depth + index) % _palette.length];
      final fillPaint = Paint()..color = color.withValues(alpha: 0.75);
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(childRect, fillPaint);
      canvas.drawRect(childRect, borderPaint);

      if (childRect.width > 60 && childRect.height > 28) {
        final label = '${child.name} (${formatBytes(child.size)})';
        final painter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
          text: const TextSpan(style: TextStyle(fontSize: 11, color: Colors.white)),
        );
        painter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
        );
        painter.layout(maxWidth: childRect.width - 8);
        painter.paint(canvas, Offset(childRect.left + 4, childRect.top + 4));
      }

      if (child.children.isNotEmpty && childRect.width > 45 && childRect.height > 45) {
        final innerRect = childRect.deflate(2);
        _paintChildren(
          canvas,
          innerRect,
          child.children,
          child.size,
          depth + 1,
          !vertical,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiskTreePainter oldDelegate) {
    return oldDelegate.root != root;
  }
}
