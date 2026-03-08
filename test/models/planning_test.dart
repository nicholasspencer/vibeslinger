import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/planning.dart';

void main() {
  group('PlanningState', () {
    late PlanningState planning;

    setUp(() {
      planning = PlanningState();
    });

    test('starts not in planning mode', () {
      expect(planning.isPlanning, false);
      expect(planning.canFire, true);
    });

    test('toggle enables planning and disables fire', () {
      planning.togglePlanning();
      expect(planning.isPlanning, true);
      expect(planning.canFire, false);
    });

    test('aim applies spread reduction with diminishing returns', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.45, 0.01));
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.525, 0.01));
    });

    test('scout increments negation count', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.scout);
      expect(planning.bonus.scoutNegations, 1);
      planning.applyAction(PlanningAction.scout);
      expect(planning.bonus.scoutNegations, 2);
    });

    test('load applies accuracy boost with diminishing returns', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.load);
      expect(planning.bonus.accuracyBoost, closeTo(0.15, 0.01));
      planning.applyAction(PlanningAction.load);
      expect(planning.bonus.accuracyBoost, closeTo(0.225, 0.01));
    });

    test('cannot apply action when not planning', () {
      final result = planning.applyAction(PlanningAction.aim);
      expect(result, false);
    });

    test('consumeBonuses resets all bonuses and use counts', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      planning.applyAction(PlanningAction.load);
      planning.consumeBonuses();
      expect(planning.bonus.hasBonus, false);
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
    });

    test('context costs are correct', () {
      expect(planning.contextCostFor(PlanningAction.aim), 0.05);
      expect(planning.contextCostFor(PlanningAction.scout), 0.08);
      expect(planning.contextCostFor(PlanningAction.load), 0.06);
    });
  });
}
