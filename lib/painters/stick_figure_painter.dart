import 'dart:math';
import 'package:flutter/material.dart';
import '../models/gun.dart';

class StickFigurePainter extends CustomPainter {
  final double skillLevel; // 0.0 to 1.0
  final Gun gun;
  final bool isWindy;
  final bool isLowLight;
  final bool isUnstable;
  final double wobblePhase; // animated value for wobble

  StickFigurePainter({
    required this.skillLevel,
    required this.gun,
    this.isWindy = false,
    this.isLowLight = false,
    this.isUnstable = false,
    this.wobblePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.85;
    final scale = size.height / 200;

    // Calculate wobble based on skill and conditions
    final wobbleAmount = (1.0 - skillLevel) * 8.0 +
        (isWindy ? 4.0 : 0.0) +
        (isUnstable ? 5.0 : 0.0);
    final wobbleX = sin(wobblePhase * 3) * wobbleAmount * scale;
    final wobbleY = sin(wobblePhase * 2.3) * wobbleAmount * 0.3 * scale;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Wind lean
    final leanX = isWindy ? sin(wobblePhase) * 6 * scale : 0.0;

    // Head
    final headCenter = Offset(
      centerX + wobbleX + leanX,
      baseY - 160 * scale + wobbleY,
    );
    canvas.drawCircle(headCenter, 12 * scale, paint);

    // Squint eyes if low light
    if (isLowLight) {
      final eyePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(headCenter.dx - 5 * scale, headCenter.dy - 2 * scale),
        Offset(headCenter.dx - 1 * scale, headCenter.dy - 2 * scale),
        eyePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + 1 * scale, headCenter.dy - 2 * scale),
        Offset(headCenter.dx + 5 * scale, headCenter.dy - 2 * scale),
        eyePaint,
      );
    }

    // Neck to body
    final neckBottom = Offset(
      centerX + wobbleX * 0.8 + leanX * 0.8,
      baseY - 145 * scale + wobbleY * 0.8,
    );
    final hipCenter = Offset(
      centerX + wobbleX * 0.3 + leanX * 0.5,
      baseY - 80 * scale + wobbleY * 0.3,
    );
    canvas.drawLine(neckBottom, hipCenter, paint);

    // Legs
    final leftFoot = Offset(centerX - 20 * scale, baseY);
    final rightFoot = Offset(centerX + 20 * scale, baseY);
    final stanceOffset = isUnstable ? 10 * scale : 0.0;
    canvas.drawLine(
      hipCenter,
      Offset(leftFoot.dx - stanceOffset, leftFoot.dy),
      paint,
    );
    canvas.drawLine(
      hipCenter,
      Offset(rightFoot.dx + stanceOffset, rightFoot.dy),
      paint,
    );

    // Arms - one extended holding gun
    final shoulderPos = Offset(
      centerX + wobbleX * 0.7 + leanX * 0.7,
      baseY - 130 * scale + wobbleY * 0.7,
    );

    // Back arm (relaxed)
    final backHand = Offset(
      shoulderPos.dx - 25 * scale,
      shoulderPos.dy + 30 * scale,
    );
    canvas.drawLine(shoulderPos, backHand, paint);

    // Gun arm (extended right)
    final gunTip = Offset(
      shoulderPos.dx + 60 * scale + wobbleX * 0.5,
      shoulderPos.dy + wobbleY * 0.5,
    );
    canvas.drawLine(shoulderPos, gunTip, paint);

    // Draw gun
    final gunPaint = Paint()
      ..color = gun.color
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      gunTip,
      Offset(gunTip.dx + 20 * scale, gunTip.dy),
      gunPaint,
    );

    // Gun glow
    final glowPaint = Paint()
      ..color = gun.color.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
    canvas.drawCircle(
      Offset(gunTip.dx + 20 * scale, gunTip.dy),
      6 * scale,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StickFigurePainter oldDelegate) => true;
}
