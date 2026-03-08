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

    test('aim applies spread reduction with diminishing returns (expert)', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim, skillLevel: 1.0);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
      planning.applyAction(PlanningAction.aim, skillLevel: 1.0);
      expect(planning.bonus.spreadReduction, closeTo(0.45, 0.01));
    });

    test('novice aim gives less spread reduction', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim, skillLevel: 0.0);
      expect(planning.bonus.spreadReduction, closeTo(0.15, 0.01));
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

    test('expert context costs match base costs', () {
      expect(planning.contextCostFor(PlanningAction.directScout, skillLevel: 1.0), 0.08);
      expect(planning.contextCostFor(PlanningAction.subagentScout, skillLevel: 1.0), 0.03);
    });

    test('novice context costs are 1.5x base', () {
      expect(planning.contextCostFor(PlanningAction.aim, skillLevel: 0.0), closeTo(0.075, 0.001));
      expect(planning.contextCostFor(PlanningAction.directScout, skillLevel: 0.0), closeTo(0.12, 0.001));
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
