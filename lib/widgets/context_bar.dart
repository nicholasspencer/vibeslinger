import 'package:flutter/material.dart';
import '../models/context_window.dart';

class ContextBar extends StatelessWidget {
  final ContextWindow contextWindow;

  const ContextBar({super.key, required this.contextWindow});

  @override
  Widget build(BuildContext context) {
    final total = contextWindow.totalLoad;
    final inDanger = contextWindow.isInCompactionZone;
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
                  color: inDanger ? Colors.red : (contextWindow.isOverloaded ? Colors.orange : Colors.white70),
                  fontSize: 12,
                  fontWeight: inDanger ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (contextWindow.isCompacted) ...[
                const SizedBox(width: 6),
                const Text('(compacted)', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
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
              _legend(
                contextWindow.isCompacted ? const Color(0xFF2A8855) : const Color(0xFF44CC88),
                'User ${(contextWindow.userLoad * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 12),
              _legend(const Color(0xFF555555), 'Compact ${(ContextWindow.compactionBufferSize * 100).toStringAsFixed(1)}%'),
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
    final radius = Radius.circular(3);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    // Compaction buffer zone (right-aligned)
    final compactWidth = size.width * ContextWindow.compactionBufferSize;
    final compactLeft = size.width - compactWidth;
    canvas.drawRect(
      Rect.fromLTWH(compactLeft, 0, compactWidth, size.height),
      Paint()..color = const Color(0xFF555555).withValues(alpha: 0.4),
    );
    // Hatching pattern
    final hatchPaint = Paint()
      ..color = const Color(0xFF666666).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (double hx = compactLeft; hx < size.width; hx += 4) {
      canvas.drawLine(
        Offset(hx, 0),
        Offset(hx + size.height, size.height),
        hatchPaint,
      );
    }

    // Content sections (left-to-right)
    double x = 0;

    // System (blue)
    final systemWidth = size.width * contextWindow.systemLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, systemWidth, size.height),
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.7),
    );
    x += systemWidth;

    // User (green — desaturated if compacted)
    final userWidth = size.width * contextWindow.userLoad;
    final userColor = contextWindow.isCompacted
        ? const Color(0xFF2A8855).withValues(alpha: 0.7)
        : const Color(0xFF44CC88).withValues(alpha: 0.7);
    canvas.drawRect(
      Rect.fromLTWH(x, 0, userWidth, size.height),
      Paint()..color = userColor,
    );

    // Border — red when in compaction zone
    if (contextWindow.isInCompactionZone) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
        Paint()
          ..color = Colors.red.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContextBarPainter oldDelegate) {
    return oldDelegate.contextWindow.totalLoad != contextWindow.totalLoad ||
        oldDelegate.contextWindow.isCompacted != contextWindow.isCompacted ||
        oldDelegate.contextWindow.systemLoad != contextWindow.systemLoad;
  }
}
