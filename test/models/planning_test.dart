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
    });

    test('direct scout increments negation count', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.directScout);
      expect(planning.bonus.scoutNegations, 1);
    });

    test('subagent scout does not immediately apply', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.subagentScout);
      expect(planning.bonus.scoutNegations, 0);
    });

    test('applySubagentScoutResult increments negation', () {
      planning.togglePlanning();
      planning.applySubagentScoutResult();
      expect(planning.bonus.scoutNegations, 1);
    });

    test('cannot apply action when not planning', () {
      final result = planning.applyAction(PlanningAction.aim);
      expect(result, false);
    });

    test('consumeBonuses resets', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      planning.consumeBonuses();
      expect(planning.bonus.hasBonus, false);
    });

    test('context costs differ for scout types', () {
      expect(planning.contextCostFor(PlanningAction.directScout), 0.08);
      expect(planning.contextCostFor(PlanningAction.subagentScout), 0.03);
    });

    test('bonus scale reduces proportionally', () {
      planning.bonus.spreadReduction = 0.50;
      planning.bonus.scoutNegations = 3;
      planning.bonus.scale(0.4);
      expect(planning.bonus.spreadReduction, closeTo(0.20, 0.01));
      expect(planning.bonus.scoutNegations, 1);
    });
  });
}
