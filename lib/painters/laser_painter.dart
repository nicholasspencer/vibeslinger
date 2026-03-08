import 'package:flutter/material.dart';

class LaserPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double progress; // 0.0 to 1.0 animation progress
  final double beamWidth;

  LaserPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.progress,
    this.beamWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final currentEnd = Offset.lerp(start, end, progress)!;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1.0 - progress * 0.5))
      ..strokeWidth = beamWidth * 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(start, currentEnd, glowPaint);

    // Core beam
    final corePaint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress * 0.3)
      ..strokeWidth = beamWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, currentEnd, corePaint);

    // Bright center
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * (1.0 - progress * 0.5))
      ..strokeWidth = beamWidth * 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, currentEnd, centerPaint);
  }

  @override
  bool shouldRepaint(covariant LaserPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
