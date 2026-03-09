import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/context_window.dart';
import 'package:inference_gunslinger/models/game_state.dart';
import 'package:inference_gunslinger/models/gun.dart';
import 'package:inference_gunslinger/models/planning.dart';
import 'package:inference_gunslinger/models/tool.dart';
import 'package:inference_gunslinger/models/workspace.dart';

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

    test('direct scout improves effective accuracy', () {
      final before = state.effectiveAccuracy;
      state.executePlanningAction(PlanningAction.directScout);
      expect(state.effectiveAccuracy, greaterThan(before));
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
      state.executePlanningAction(PlanningAction.aim);
      final aimSeg = state.contextWindow.userSegments
          .where((s) => s.type == ContextSegmentType.aim)
          .firstOrNull;
      expect(aimSeg, isNotNull);
      expect(aimSeg!.amount, greaterThan(0));
    });

    test('scout action creates scout user segment', () {
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


    test('aim improves effective accuracy', () {
      final before = state.effectiveAccuracy;
      state.executePlanningAction(PlanningAction.aim);
      expect(state.effectiveAccuracy, greaterThan(before));
    });

    test('aim accuracy bonus scales with skill level', () {
      state.setSkillLevel(1.0);
      state.executePlanningAction(PlanningAction.aim);
      final expert = state.effectiveAccuracy;

      state.clearShots(); // clearShots calls planning.reset() which sets _isPlanning = false
      state.setSkillLevel(0.0);
      state.togglePlanning(); // re-enable planning after reset
      state.executePlanningAction(PlanningAction.aim);
      final novice = state.effectiveAccuracy;

      expect(expert, greaterThan(novice));
    });

    test('auto-compacts when executing planning action at near-full', () {
      for (var i = 0; i < 40; i++) {
        state.fire();
        state.coolDown(0.2);
      }
      final result = state.executePlanningAction(PlanningAction.aim);
      expect(result, true);
      expect(state.contextWindow.isCompacted, true);
    });

    test('saveToWorkspace creates file and costs context', () {
      final result = state.saveToWorkspace(WorkspaceFileType.plan);
      expect(result, true);
      expect(state.workspace.files.length, 1);
      final seg = state.contextWindow.userSegments
          .where((s) => s.type == ContextSegmentType.workspaceFile)
          .firstOrNull;
      expect(seg, isNotNull);
    });

    test('loadWorkspaceFile costs context', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      final loadBefore = state.contextWindow.userLoad;
      state.loadWorkspaceFile(0);
      expect(state.contextWindow.userLoad, greaterThan(loadBefore));
      expect(state.workspace.files[0].isLoaded, true);
    });

    test('unloadWorkspaceFile frees context', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      state.loadWorkspaceFile(0);
      final loadBefore = state.contextWindow.userLoad;
      state.unloadWorkspaceFile(0);
      expect(state.contextWindow.userLoad, lessThan(loadBefore));
      expect(state.workspace.files[0].isLoaded, false);
    });

    test('loaded plan improves spread reduction in accuracy', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      final beforeLoad = state.effectiveAccuracy;
      state.loadWorkspaceFile(0);
      expect(state.effectiveAccuracy, greaterThan(beforeLoad));
    });

    test('loaded research reduces aim cost', () {
      state.setSkillLevel(1.0);
      state.saveToWorkspace(WorkspaceFileType.research);
      state.loadWorkspaceFile(0);
      final costWithResearch = state.planning.contextCostFor(
        PlanningAction.aim, skillLevel: state.skillLevel, aimCostReduction: state.workspace.passiveAimCostReduction,
      );
      expect(costWithResearch, lessThan(0.05));
    });

    test('newSession clears context and unloads files but keeps them', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      state.loadWorkspaceFile(0);
      state.fire();
      state.newSession();
      expect(state.workspace.files.length, 1);
      expect(state.workspace.files[0].isLoaded, false);
      expect(state.contextWindow.userLoad, 0.0);
      expect(state.shots, isEmpty);
      expect(state.heatLevel, 0.0);
      expect(state.workspace.sessionNumber, 2);
    });

    test('newSession keeps tools loaded', () {
      state.loadTool(ToolType.webSearch);
      state.newSession();
      expect(state.loadedTools.contains(ToolType.webSearch), true);
    });

    test('file reader tool halves workspace load cost', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      state.loadTool(ToolType.fileReader);
      final loadBefore = state.contextWindow.userLoad;
      state.loadWorkspaceFile(0);
      final loadAfter = state.contextWindow.userLoad;
      expect(loadAfter - loadBefore, closeTo(0.03, 0.005));
    });

    test('firing does NOT consume workspace file bonuses', () {
      state.saveToWorkspace(WorkspaceFileType.plan);
      state.loadWorkspaceFile(0);
      state.fire();
      expect(state.workspace.files[0].isLoaded, true);
      expect(state.workspace.passiveSpreadReduction, 0.10);
    });

    test('full session-workspace gameplay loop', () {
      // Session 1: plan, scout, save, fire
      state.executePlanningAction(PlanningAction.aim);
      state.executePlanningAction(PlanningAction.directScout);
      state.saveToWorkspace(WorkspaceFileType.plan);
      state.saveToWorkspace(WorkspaceFileType.research);
      expect(state.workspace.files.length, 2);
      state.fire();

      // New session — files persist, context clears
      state.newSession();
      expect(state.workspace.files.length, 2);
      expect(state.workspace.files[0].isLoaded, false);
      expect(state.contextWindow.userLoad, 0.0);
      expect(state.shots, isEmpty);
      expect(state.workspace.sessionNumber, 2);

      // Session 2: load files back, verify bonuses
      state.loadWorkspaceFile(0); // plan
      state.loadWorkspaceFile(1); // research
      expect(state.workspace.loadedFiles.length, 2);

      // Loaded plan should improve accuracy
      final withFiles = state.effectiveAccuracy;
      state.unloadWorkspaceFile(0);
      state.unloadWorkspaceFile(1);
      final withoutFiles = state.effectiveAccuracy;
      expect(withFiles, greaterThan(withoutFiles));
    });
  });
}
