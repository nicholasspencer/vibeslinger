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
              _legend(const Color(0xFF3366AA), 'System ${(contextWindow.systemLoad * 100).toStringAsFixed(0)}%'),
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
    // System segments (with dividers)
    double x = 0;
    for (int i = 0; i < contextWindow.systemSegments.length; i++) {
      final seg = contextWindow.systemSegments[i];
      final segWidth = size.width * seg.amount;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, segWidth, size.height),
        Paint()..color = seg.color.withValues(alpha: 0.7),
      );
      if (i > 0) {
        // 1px divider between segments
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
      }
      x += segWidth;
    }

    // User segments (with dividers)
    final userStartX = x;
    for (int i = 0; i < contextWindow.userSegments.length; i++) {
      final seg = contextWindow.userSegments[i];
      final segWidth = size.width * seg.amount;
      final color = contextWindow.isCompacted
          ? seg.color.withValues(alpha: 0.4)
          : seg.color.withValues(alpha: 0.7);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, segWidth, size.height),
        Paint()..color = color,
      );
      if (i > 0) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
      }
      x += segWidth;
    }
    // Divider between system and user if both have content
    if (contextWindow.userSegments.isNotEmpty) {
      canvas.drawLine(
        Offset(userStartX, 0),
        Offset(userStartX, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

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
  bool shouldRepaint(covariant _ContextBarPainter oldDelegate) => true;
}
