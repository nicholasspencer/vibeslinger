import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/context_window.dart';
import 'package:inference_gunslinger/models/game_state.dart';
import 'package:inference_gunslinger/models/gun.dart';
import 'package:inference_gunslinger/models/planning.dart';
import 'package:inference_gunslinger/models/tool.dart';

void main() {
  group('GameState', () {
    late GameState state;

    setUp(() {
      state = GameState();
    });

    test('default effective accuracy equals gun base accuracy', () {
      // Skill no longer affects base accuracy — model capability is fixed
      expect(state.effectiveAccuracy, closeTo(0.55, 0.01));
    });

    test('novice and expert have same base accuracy', () {
      state.selectGun(Gun.all[0]);
      state.setSkillLevel(0.0);
      final novice = state.effectiveAccuracy;
      state.setSkillLevel(1.0);
      final expert = state.effectiveAccuracy;
      expect(novice, closeTo(expert, 0.01));
    });

    test('environment penalties stack', () {
      state.setSkillLevel(1.0);
      state.selectGun(Gun.all[0]);
      state.setEnvironment(const EnvironmentFactors(
        windy: true,
        lowLight: true,
        unstable: true,
      ));
      // 0.55 * 0.82 * 0.88 * 0.78 ≈ 0.309
      expect(state.effectiveAccuracy, closeTo(0.309, 0.02));
    });

    test('firing increases heat', () {
      expect(state.heatLevel, 0.0);
      state.fire();
      // 0.09 * 1.3 (Opus heat rate) = 0.117
      expect(state.heatLevel, closeTo(0.117, 0.01));
    });

    test('heat degrades accuracy', () {
      state.setSkillLevel(1.0);
      final before = state.effectiveAccuracy;
      for (var i = 0; i < 5; i++) {
        state.fire();
      }
      expect(state.effectiveAccuracy, lessThan(before));
    });

    test('clearShots resets heat and shots', () {
      state.fire();
      state.fire();
      state.clearShots();
      expect(state.shots, isEmpty);
      expect(state.heatLevel, 0.0);
    });

    test('clearShots resets tools', () {
      state.clearShots();
      expect(state.loadedTools, isEmpty);
      expect(state.shots, isEmpty);
    });

    test('accuracy is capped at 99%', () {
      state.setSkillLevel(1.0);
      state.selectGun(Gun.all[0]); // Claude Opus 4.6, 55% base
      state.loadTool(ToolType.codeAnalysis); // +10%
      state.loadTool(ToolType.codeReview); // +5%
      // Even with bonuses, should cap at 99%
      expect(state.effectiveAccuracy, lessThanOrEqualTo(0.99));
    });

    test('no bullseyes below 80% effective accuracy', () {
      state.setSkillLevel(1.0);
      state.selectGun(Gun.all[0]); // Opus 55% base
      // Even with all accuracy tools: 55% + 15% = 70%, below 80% threshold
      state.loadTool(ToolType.codeAnalysis);
      state.loadTool(ToolType.codeReview);
      final bullseyes = <ShotResult>[];
      for (var i = 0; i < 200; i++) {
        final shot = state.fire();
        if (shot.isBullseye) bullseyes.add(shot);
        state.coolDown(0.2);
      }
      // Accuracy maxes at ~70%, well below 80% bullseye threshold
      expect(bullseyes, isEmpty);
    });

    test('code review tool increases heat generation', () {
      state.setSkillLevel(0.5);
      state.fire();
      final heatWithout = state.heatLevel;
      state.clearShots();

      state.loadTool(ToolType.codeReview);
      state.fire();
      final heatWith = state.heatLevel;

      expect(heatWith, greaterThan(heatWithout));
    });

    test('firing consumes user context into shot segment', () {
      state.fire();
      final shotSegment = state.contextWindow.userSegments
          .where((s) => s.type == ContextSegmentType.shot)
          .firstOrNull;
      expect(shotSegment, isNotNull);
      expect(shotSegment!.amount, greaterThan(0));
    });

    test('expert shot cost is less than novice', () {
      state.setSkillLevel(1.0);
      state.fire();
      final expertCost = state.contextWindow.userSegments
          .firstWhere((s) => s.type == ContextSegmentType.shot)
          .amount;

      state.clearShots();
      state.setSkillLevel(0.0);
      state.fire();
      final noviceCost = state.contextWindow.userSegments
          .firstWhere((s) => s.type == ContextSegmentType.shot)
          .amount;

      expect(expertCost, lessThan(noviceCost));
    });

    test('tools increase per-shot context cost', () {
      state.setSkillLevel(0.5);
      state.fire();
      final baseCost = state.contextWindow.userSegments
          .firstWhere((s) => s.type == ContextSegmentType.shot)
          .amount;

      state.clearShots();
      state.loadTool(ToolType.codeReview);
      state.fire();
      final toolCost = state.contextWindow.userSegments
          .firstWhere((s) => s.type == ContextSegmentType.shot)
          .amount;

      expect(toolCost, greaterThan(baseCost));
    });

    test('aim action creates aim user segment', () {
      state.togglePlanning();
      state.executePlanningAction(PlanningAction.aim);
      final aimSeg = state.contextWindow.userSegments
          .where((s) => s.type == ContextSegmentType.aim)
          .firstOrNull;
      expect(aimSeg, isNotNull);
      expect(aimSeg!.amount, greaterThan(0));
    });

    test('scout action creates scout user segment', () {
      state.togglePlanning();
      state.executePlanningAction(PlanningAction.directScout);
      final scoutSeg = state.contextWindow.userSegments
          .where((s) => s.type == ContextSegmentType.scout)
          .firstOrNull;
      expect(scoutSeg, isNotNull);
      expect(scoutSeg!.amount, greaterThan(0));
    });

    test('loading tool adds system segment', () {
      state.loadTool(ToolType.webSearch);
      expect(state.contextWindow.systemSegments.length, 2); // harness + tool
      expect(state.contextWindow.systemSegments[1].label, 'Web Search');
    });

    test('unloading tool removes system segment', () {
      state.loadTool(ToolType.webSearch);
      state.unloadTool(ToolType.webSearch);
      expect(state.contextWindow.systemSegments.length, 1); // harness only
    });

    test('auto-compacts when firing at near-full context', () {
      // Fill context by firing repeatedly
      for (var i = 0; i < 40; i++) {
        state.fire();
        state.coolDown(0.2);
      }
      final shotsBefore = state.shots.length;
      state.fire();
      expect(state.shots.length, shotsBefore + 1); // shot not lost
      expect(state.contextWindow.isCompacted, true);
    });

    test('skill creator boosts accuracy by 25%', () {
      final before = state.effectiveAccuracy;
      state.loadTool(ToolType.skillCreator);
      final after = state.effectiveAccuracy;
      expect(after - before, closeTo(0.25, 0.02));
    });

    test('skill creator removes 1 environment penalty', () {
      state.setEnvironment(const EnvironmentFactors(windy: true));
      final withPenalty = state.effectiveAccuracy;
      state.loadTool(ToolType.skillCreator);
      final withTool = state.effectiveAccuracy;
      // Without tool: base * 0.82; with tool: (base+0.25) * 1.0 (penalty negated)
      expect(withTool, greaterThan(withPenalty));
      // Verify penalty is actually negated (not just offset by accuracy bonus)
      state.unloadTool(ToolType.skillCreator);
      // Re-check: accuracy should drop back
      expect(state.effectiveAccuracy, closeTo(withPenalty, 0.01));
    });

    test('aim improves effective accuracy', () {
      final before = state.effectiveAccuracy;
      state.togglePlanning();
      state.executePlanningAction(PlanningAction.aim);
      expect(state.effectiveAccuracy, greaterThan(before));
    });

    test('aim accuracy bonus scales with skill level', () {
      state.setSkillLevel(1.0);
      state.togglePlanning();
      state.executePlanningAction(PlanningAction.aim);
      final expert = state.effectiveAccuracy;

      state.clearShots();
      state.setSkillLevel(0.0);
      state.togglePlanning();
      state.executePlanningAction(PlanningAction.aim);
      final novice = state.effectiveAccuracy;

      expect(expert, greaterThan(novice));
    });

    test('auto-compacts when executing planning action at near-full', () {
      for (var i = 0; i < 40; i++) {
        state.fire();
        state.coolDown(0.2);
      }
      state.togglePlanning();
      final result = state.executePlanningAction(PlanningAction.aim);
      expect(result, true);
      expect(state.contextWindow.isCompacted, true);
    });
  });
}
