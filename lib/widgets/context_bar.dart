import 'package:flutter/material.dart';
import '../models/context_window.dart';

class ContextBar extends StatelessWidget {
  final ContextWindow contextWindow;

  const ContextBar({super.key, required this.contextWindow});

  @override
  Widget build(BuildContext context) {
    final total = contextWindow.totalLoad;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Context: ${(total * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: contextWindow.isOverloaded ? Colors.red : Colors.white70,
                  fontSize: 12,
                  fontWeight: contextWindow.isOverloaded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: CustomPaint(
                    painter: _ContextBarPainter(contextWindow: contextWindow),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _legend(const Color(0xFF4488CC), 'System ${(contextWindow.systemLoad * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFCCA844), 'Buffer ${(contextWindow.bufferLoad * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _legend(const Color(0xFF44CC88), 'User ${(contextWindow.userLoad * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _ContextBarPainter extends CustomPainter {
  final ContextWindow contextWindow;

  _ContextBarPainter({required this.contextWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final radius = Radius.circular(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      bgPaint,
    );

    double x = 0;

    final systemWidth = size.width * contextWindow.systemLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, systemWidth, size.height),
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.7),
    );
    x += systemWidth;

    final bufferWidth = size.width * contextWindow.bufferLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, bufferWidth, size.height),
      Paint()..color = const Color(0xFFCCA844).withValues(alpha: 0.7),
    );
    x += bufferWidth;

    final userWidth = size.width * contextWindow.userLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, userWidth, size.height),
      Paint()..color = const Color(0xFF44CC88).withValues(alpha: 0.7),
    );

    final thresholdX = size.width * 0.70;
    canvas.drawLine(
      Offset(thresholdX, 0),
      Offset(thresholdX, size.height),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ContextBarPainter oldDelegate) {
    return oldDelegate.contextWindow.totalLoad != contextWindow.totalLoad;
  }
}
