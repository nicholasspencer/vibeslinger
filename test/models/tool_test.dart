import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/tool.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
  group('Tool', () {
    test('four tools defined', () {
      expect(Tool.all.length, 4);
    });

    test('code review tool exists with correct properties', () {
      final codeReview = Tool.all.firstWhere((t) => t.type == ToolType.codeReview);
      expect(codeReview.name, 'Code Review');
      expect(codeReview.systemCost, 0.12);
      expect(codeReview.accuracyBonus, 0.05);
      expect(codeReview.spreadBonus, 0.08);
      expect(codeReview.heatPenalty, 0.5);
    });

    test('web search costs 8% system', () {
      expect(Tool.all[0].systemCost, 0.08);
    });

    test('each tool has a shotCostPenalty', () {
      final webSearch = Tool.all.firstWhere((t) => t.type == ToolType.webSearch);
      expect(webSearch.shotCostPenalty, 0.005);

      final codeAnalysis = Tool.all.firstWhere((t) => t.type == ToolType.codeAnalysis);
      expect(codeAnalysis.shotCostPenalty, 0.01);

      final fileReader = Tool.all.firstWhere((t) => t.type == ToolType.fileReader);
      expect(fileReader.shotCostPenalty, 0.005);

      final codeReview = Tool.all.firstWhere((t) => t.type == ToolType.codeReview);
      expect(codeReview.shotCostPenalty, 0.015);
    });
  });

  group('ContextWindow with tools', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('addToolSegment increases system load', () {
      ctx.addToolSegment('Web Search', 0.08, const Color(0xFF5599DD));
      expect(ctx.systemLoad, closeTo(0.23, 0.01));
    });

    test('removeToolSegment removes tool', () {
      ctx.addToolSegment('Code Analysis', 0.10, const Color(0xFF5599DD));
      ctx.removeToolSegment('Code Analysis');
      expect(ctx.systemLoad, closeTo(0.15, 0.01));
    });

    test('removeToolSegment with no matching tool does nothing', () {
      ctx.removeToolSegment('Nonexistent');
      expect(ctx.systemLoad, closeTo(0.15, 0.01));
    });

    test('compaction buffer threshold is 83.5%', () {
      expect(ctx.compactionThreshold, closeTo(0.835, 0.01));
    });

    test('isInCompactionZone when load exceeds threshold', () {
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.55, const Color(0xFF44CC88));
      expect(ctx.isInCompactionZone, true);
    });

    test('compact reduces user space by 60%', () {
      ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.40, const Color(0xFF44CC88));
      ctx.compact();
      expect(ctx.userLoad, closeTo(0.16, 0.01));
      expect(ctx.isCompacted, true);
    });

    test('reset clears compacted state and tool loads', () {
      ctx.addToolSegment('Web Search', 0.10, const Color(0xFF5599DD));
      ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.20, const Color(0xFF44AA88));
      ctx.compact();
      ctx.reset();
      expect(ctx.systemLoad, closeTo(0.15, 0.01));
      expect(ctx.userLoad, 0.0);
      expect(ctx.isCompacted, false);
    });
  });
}
