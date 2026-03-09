import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/planning.dart';

void main() {
  group('PlanningState', () {
    late PlanningState planning;

    setUp(() {
      planning = PlanningState();
    });

    test('starts in planning mode', () {
      expect(planning.isPlanning, true);
      expect(planning.canFire, true);
    });

    test('toggle disables planning', () {
      planning.togglePlanning();
      expect(planning.isPlanning, false);
    });

    test('aim applies spread reduction with diminishing returns (expert)', () {
      planning.applyAction(PlanningAction.aim, skillLevel: 1.0);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
      planning.applyAction(PlanningAction.aim, skillLevel: 1.0);
      expect(planning.bonus.spreadReduction, closeTo(0.45, 0.01));
    });

    test('novice aim gives less spread reduction', () {
      planning.applyAction(PlanningAction.aim, skillLevel: 0.0);
      expect(planning.bonus.spreadReduction, closeTo(0.15, 0.01));
    });

    test('direct scout adds spread reduction', () {
      planning.applyAction(PlanningAction.directScout);
      expect(planning.bonus.spreadReduction, closeTo(0.20, 0.01));
    });

    test('multiple direct scouts stack', () {
      planning.applyAction(PlanningAction.directScout);
      planning.applyAction(PlanningAction.directScout);
      expect(planning.bonus.spreadReduction, closeTo(0.40, 0.01));
    });

    test('subagent scout does not immediately apply', () {
      planning.applyAction(PlanningAction.subagentScout);
      expect(planning.bonus.spreadReduction, 0.0);
    });

    test('applySubagentScoutResult adds spread reduction', () {
      planning.applySubagentScoutResult();
      expect(planning.bonus.spreadReduction, closeTo(0.15, 0.01));
    });

    test('cannot apply action when not planning', () {
      planning.togglePlanning(); // disable planning
      final result = planning.applyAction(PlanningAction.aim);
      expect(result, false);
    });

    test('consumeBonuses resets', () {
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
      planning.bonus.scale(0.4);
      expect(planning.bonus.spreadReduction, closeTo(0.20, 0.01));
    });
  });
}
