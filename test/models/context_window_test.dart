import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
  group('ContextWindow', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('default loads are system 20% + buffer 15%', () {
      expect(ctx.systemLoad, 0.20);
      expect(ctx.bufferLoad, 0.15);
      expect(ctx.userLoad, 0.0);
      expect(ctx.totalLoad, closeTo(0.35, 0.01));
    });

    test('is not overloaded at default', () {
      expect(ctx.isOverloaded, false);
      expect(ctx.loadWobblePenalty, 0.0);
    });

    test('consumeContext adds to user load', () {
      ctx.consumeContext(0.10);
      expect(ctx.userLoad, closeTo(0.10, 0.01));
      expect(ctx.totalLoad, closeTo(0.45, 0.01));
    });

    test('overloaded when total > 0.70', () {
      ctx.consumeContext(0.40);
      expect(ctx.isOverloaded, true);
      expect(ctx.loadWobblePenalty, greaterThan(0.0));
    });

    test('heat rate multiplier increases when overloaded', () {
      expect(ctx.heatRateMultiplier, 1.0);
      ctx.consumeContext(0.50);
      expect(ctx.heatRateMultiplier, greaterThan(1.0));
    });

    test('cannot consume past capacity', () {
      ctx.consumeContext(0.60);
      expect(ctx.userLoad, closeTo(0.60, 0.01));
    });

    test('isNearFull blocks further consumption', () {
      ctx.consumeContext(0.60);
      final result = ctx.consumeContext(0.10);
      expect(result, false);
    });

    test('reset clears user load', () {
      ctx.consumeContext(0.30);
      ctx.reset();
      expect(ctx.userLoad, 0.0);
    });
  });

  group('ContextSegment', () {
    test('segment has type, label, amount, and color', () {
      final seg = ContextSegment(
        type: ContextSegmentType.harness,
        label: 'Harness',
        amount: 0.15,
        color: const Color(0xFF3366AA),
      );
      expect(seg.type, ContextSegmentType.harness);
      expect(seg.label, 'Harness');
      expect(seg.amount, 0.15);
      expect(seg.color, const Color(0xFF3366AA));
    });
  });
}
