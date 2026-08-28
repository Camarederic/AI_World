import 'package:flutter/material.dart';

import 'detection.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;

  const DetectionOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: DetectionPainter(detections),
        size: Size.infinite,
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final detection in detections) {
      final left = detection.left * size.width;
      final top = detection.top * size.height;
      final right = detection.right * size.width;
      final bottom = detection.bottom * size.height;

      final rect = Rect.fromLTRB(
        left.clamp(0.0, size.width),
        top.clamp(0.0, size.height),
        right.clamp(0.0, size.width),
        bottom.clamp(0.0, size.height),
      );

      canvas.drawRect(rect, boxPaint);

      final label =
          '${detection.label} '
          '${(detection.score * 100).toStringAsFixed(0)}%';

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();

      final labelTop = (rect.top - textPainter.height).clamp(0.0, size.height);

      final labelBackground = Paint()..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          labelTop,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        labelBackground,
      );

      textPainter.paint(canvas, Offset(rect.left + 4, labelTop + 2));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
