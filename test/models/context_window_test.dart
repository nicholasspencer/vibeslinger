import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
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

  group('ContextWindow with segments', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('default has harness system segment at 15%', () {
      expect(ctx.systemSegments.length, 1);
      expect(ctx.systemSegments.first.type, ContextSegmentType.harness);
      expect(ctx.systemSegments.first.amount, 0.15);
      expect(ctx.systemLoad, closeTo(0.15, 0.01));
    });

    test('default user segments are empty', () {
      expect(ctx.userSegments, isEmpty);
      expect(ctx.userLoad, 0.0);
    });

    test('totalLoad is system + buffer + user', () {
      expect(ctx.totalLoad, closeTo(0.30, 0.01)); // 0.15 system + 0.15 buffer
    });

    test('addToolSegment adds a system segment', () {
      ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
      expect(ctx.systemSegments.length, 2);
      expect(ctx.systemLoad, closeTo(0.21, 0.01));
    });

    test('removeToolSegment removes the tool segment', () {
      ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
      ctx.removeToolSegment('Web Search');
      expect(ctx.systemSegments.length, 1);
      expect(ctx.systemLoad, closeTo(0.15, 0.01));
    });

    test('consumeUserContext creates or updates segment by type', () {
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
      expect(ctx.userSegments.length, 1);
      expect(ctx.userLoad, closeTo(0.05, 0.01));

      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
      expect(ctx.userSegments.length, 1); // still 1, updated in place
      expect(ctx.userLoad, closeTo(0.10, 0.01));
    });

    test('consumeUserContext adds different types as separate segments', () {
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.02, const Color(0xFF44CC88));
      expect(ctx.userSegments.length, 2);
      expect(ctx.userLoad, closeTo(0.07, 0.01));
    });

    test('consumeUserContext returns false when near full', () {
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.60, const Color(0xFF44CC88));
      final result = ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.10, const Color(0xFF44CC88));
      expect(result, false);
    });

    test('compact scales each user segment by 0.4', () {
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.20, const Color(0xFF44AA88));
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.10, const Color(0xFF44CC88));
      ctx.compact();
      expect(ctx.userSegments[0].amount, closeTo(0.08, 0.01)); // 0.20 * 0.4
      expect(ctx.userSegments[1].amount, closeTo(0.04, 0.01)); // 0.10 * 0.4
      expect(ctx.isCompacted, true);
    });

    test('compact removes tiny segments', () {
      ctx.consumeUserContext(ContextSegmentType.scout, 'Scouts', 0.002, const Color(0xFFAACC44));
      ctx.compact();
      expect(ctx.userSegments, isEmpty); // 0.002 * 0.4 = 0.0008 < 0.001
    });

    test('overloaded when total > 0.70', () {
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.45, const Color(0xFF44CC88));
      expect(ctx.isOverloaded, true);
    });

    test('reset clears user segments and tool segments', () {
      ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.10, const Color(0xFF44AA88));
      ctx.compact();
      ctx.reset();
      expect(ctx.systemSegments.length, 1); // only harness
      expect(ctx.userSegments, isEmpty);
      expect(ctx.isCompacted, false);
    });

    test('is not overloaded at default', () {
      expect(ctx.isOverloaded, false);
      expect(ctx.loadWobblePenalty, 0.0);
    });

    test('heat rate multiplier increases when overloaded', () {
      expect(ctx.heatRateMultiplier, 1.0);
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.50, const Color(0xFF44CC88));
      expect(ctx.heatRateMultiplier, greaterThan(1.0));
    });

    test('workspace file segment type exists', () {
      final cw = ContextWindow();
      cw.consumeUserContext(
        ContextSegmentType.workspaceFile, 'plan_s1.md', 0.06, const Color(0xFF8866CC),
      );
      final seg = cw.userSegments.where((s) => s.type == ContextSegmentType.workspaceFile).firstOrNull;
      expect(seg, isNotNull);
      expect(seg!.label, 'plan_s1.md');
    });

    test('copy produces independent deep copy', () {
      ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.10, const Color(0xFF44AA88));

      final copied = ctx.copy();

      // Same segment counts and amounts
      expect(copied.systemSegments.length, ctx.systemSegments.length);
      expect(copied.userSegments.length, ctx.userSegments.length);
      expect(copied.systemLoad, closeTo(ctx.systemLoad, 0.001));
      expect(copied.userLoad, closeTo(ctx.userLoad, 0.001));

      // Mutate the copy and verify original is unchanged
      copied.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.15, const Color(0xFF44CC88));
      expect(copied.userSegments.length, 2);
      expect(ctx.userSegments.length, 1);
      expect(ctx.userLoad, closeTo(0.10, 0.001));
    });
  });
}
