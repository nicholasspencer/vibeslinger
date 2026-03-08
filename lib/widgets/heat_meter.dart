import 'package:flutter/material.dart';

class HeatMeter extends StatelessWidget {
  final double heatLevel;

  const HeatMeter({super.key, required this.heatLevel});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.green, Colors.red, heatLevel)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('HEAT', style: TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        SizedBox(
          width: 20,
          height: 100,
          child: CustomPaint(
            painter: _HeatMeterPainter(heatLevel: heatLevel, color: color),
          ),
        ),
      ],
    );
  }
}

class _HeatMeterPainter extends CustomPainter {
  final double heatLevel;
  final Color color;

  _HeatMeterPainter({required this.heatLevel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Fill
    final fillHeight = size.height * heatLevel;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Glow when hot
    if (heatLevel > 0.6) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
          const Radius.circular(4),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatMeterPainter oldDelegate) {
    return oldDelegate.heatLevel != heatLevel;
  }
}
