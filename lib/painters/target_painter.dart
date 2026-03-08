import 'package:flutter/material.dart';
import '../models/game_state.dart';

class TargetPainter extends CustomPainter {
  final List<ShotResult> shots;
  final Color shotColor;

  TargetPainter({required this.shots, required this.shotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2 * 0.9;

    // Draw concentric rings
    const ringColors = [
      Color(0xFFFF4444), // bullseye
      Color(0xFFFF8844),
      Color(0xFFFFCC44),
      Color(0xFF88CC44),
      Color(0xFF4488CC),
    ];

    for (var i = ringColors.length - 1; i >= 0; i--) {
      final radius = maxRadius * ((i + 1) / ringColors.length);
      final paint = Paint()
        ..color = ringColors[i].withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);

      final strokePaint = Paint()
        ..color = ringColors[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, strokePaint);
    }

    // Draw crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );

    // Draw shots
    for (final shot in shots) {
      final shotPos = Offset(
        center.dx + shot.offset.dx * maxRadius,
        center.dy + shot.offset.dy * maxRadius,
      );

      // Glow
      final glowPaint = Paint()
        ..color = shotColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(shotPos, 5, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = shotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(shotPos, 3, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TargetPainter oldDelegate) {
    return oldDelegate.shots.length != shots.length ||
        oldDelegate.shotColor != shotColor;
  }
}
