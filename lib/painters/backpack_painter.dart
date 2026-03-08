import 'package:flutter/material.dart';
import '../models/context_window.dart';

class BackpackPainter {
  static void paint(
    Canvas canvas,
    Offset shoulderPos,
    double scale,
    ContextWindow contextWindow,
  ) {
    final packWidth = 16.0 * scale;
    final packHeight = 30.0 * scale;
    final packLeft = shoulderPos.dx - packWidth - 8 * scale;
    final packTop = shoulderPos.dy - 5 * scale;

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    final packRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(packLeft, packTop, packWidth, packHeight),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(packRect, outlinePaint);

    final strapPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(
      Offset(packLeft + packWidth, packTop + 3 * scale),
      Offset(shoulderPos.dx, shoulderPos.dy),
      strapPaint,
    );

    final innerLeft = packLeft + 2 * scale;
    final innerWidth = packWidth - 4 * scale;
    final innerBottom = packTop + packHeight - 2 * scale;
    final innerHeight = packHeight - 4 * scale;

    final systemHeight = innerHeight * contextWindow.systemLoad;
    canvas.drawRect(
      Rect.fromLTWH(innerLeft, innerBottom - systemHeight, innerWidth, systemHeight),
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.6),
    );

    final bufferHeight = innerHeight * contextWindow.bufferLoad;
    canvas.drawRect(
      Rect.fromLTWH(innerLeft, innerBottom - systemHeight - bufferHeight, innerWidth, bufferHeight),
      Paint()..color = const Color(0xFFCCA844).withValues(alpha: 0.6),
    );

    final userHeight = innerHeight * contextWindow.userLoad;
    canvas.drawRect(
      Rect.fromLTWH(innerLeft, innerBottom - systemHeight - bufferHeight - userHeight, innerWidth, userHeight),
      Paint()..color = const Color(0xFF44CC88).withValues(alpha: 0.6),
    );

    if (contextWindow.isOverloaded) {
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.3 * contextWindow.loadWobblePenalty)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);
      canvas.drawRRect(packRect, glowPaint);
    }
  }
}
