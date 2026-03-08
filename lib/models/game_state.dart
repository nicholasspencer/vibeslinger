import 'dart:math';
import 'package:flutter/material.dart';
import 'context_window.dart';
import 'gun.dart';
import 'planning.dart';
import 'tool.dart';

const _aimColor = Color(0xFF44AA88);
const _scoutColor = Color(0xFFAACC44);
const _shotColor = Color(0xFF44CC88);

class ShotResult {
  final Offset offset; // offset from center of target, normalized -1 to 1
  final DateTime time;
  final bool isBullseye;

  const ShotResult({required this.offset, required this.time, this.isBullseye = false});
}

class GameState extends ChangeNotifier {
  Gun _selectedGun = Gun.all[0];
  double _skillLevel = 0.5; // 0.0 novice, 1.0 expert
  final List<ShotResult> _shots = [];
  double _heatLevel = 0.0; // 0.0 cool, 1.0 overheated
  final Random _random = Random();
  final ContextWindow _contextWindow = ContextWindow();
  final PlanningState _planning = PlanningState();
  final Set<ToolType> _loadedTools = {};

  Gun get selectedGun => _selectedGun;
  double get skillLevel => _skillLevel;
  List<ShotResult> get shots => List.unmodifiable(_shots);
  double get heatLevel => _heatLevel;
  ContextWindow get contextWindow => _contextWindow;
  PlanningState get planning => _planning;
  Set<ToolType> get loadedTools => Set.unmodifiable(_loadedTools);

  static const double _baseShotCost = 0.02;

  double get _perShotCost {
    final skillScale = 1.5 - (_skillLevel * 0.75);
    double toolPenalties = 0.0;
    for (final type in _loadedTools) {
      final tool = Tool.all.firstWhere((t) => t.type == type);
      toolPenalties += tool.shotCostPenalty;
    }
    return _baseShotCost * skillScale + toolPenalties;
  }

  double get effectiveAccuracy {
    final base = _selectedGun.baseAccuracy + _toolAccuracyBonus;
    final aimBonus = _planning.bonus.spreadReduction * 0.3;
    final heat = 1.0 - (_heatLevel * 0.35);
    final loadPenalty = 1.0 - (_contextWindow.loadWobblePenalty * 0.4);
    return ((base + aimBonus) * heat * loadPenalty).clamp(0.05, 0.99);
  }

  void selectGun(Gun gun) {
    _selectedGun = gun;
    notifyListeners();
  }

  void setSkillLevel(double level) {
    _skillLevel = level.clamp(0.0, 1.0);
    notifyListeners();
  }

  ShotResult fire() {
    final accuracy = effectiveAccuracy;
    final spreadMultiplier = 1.0 - _planning.bonus.spreadReduction - _toolSpreadBonus;
    final spread = (1.0 - accuracy) * 2.0 * spreadMultiplier;

    // Bullseye check: above 80% accuracy, chance scales linearly up to ~15% at 99%
    bool bullseye = false;
    if (accuracy > 0.80) {
      final bullseyeChance = (accuracy - 0.80) / 0.20 * 0.15;
      if (_random.nextDouble() < bullseyeChance) {
        bullseye = true;
      }
    }

    final Offset offset;
    if (bullseye) {
      offset = Offset.zero;
    } else {
      final u1 = _random.nextDouble();
      final u2 = _random.nextDouble();
      final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      final z1 = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
      offset = Offset(
        (z0 * spread * 0.3).clamp(-1.0, 1.0),
        (z1 * spread * 0.3).clamp(-1.0, 1.0),
      );
    }

    final shot = ShotResult(offset: offset, time: DateTime.now(), isBullseye: bullseye);
    _shots.add(shot);

    final heatPenalty = 1.0 + _toolHeatPenalty;
    _heatLevel = (_heatLevel + 0.09 * _selectedGun.heatRate * _contextWindow.heatRateMultiplier * heatPenalty).clamp(0.0, 1.0);

    // Consume planning bonuses after firing
    _planning.consumeBonuses();

    _autoCompactIfNeeded();
    _contextWindow.consumeUserContext(
      ContextSegmentType.shot, 'Shots', _perShotCost, _shotColor,
    );

    notifyListeners();
    return shot;
  }

  void coolDown(double amount) {
    _heatLevel = (_heatLevel - amount).clamp(0.0, 1.0);
    notifyListeners();
  }

  void togglePlanning() {
    _planning.togglePlanning();
    notifyListeners();
  }

  bool executePlanningAction(PlanningAction action) {
    _autoCompactIfNeeded();
    if (_contextWindow.isNearFull) return false;
    final cost = _planning.contextCostFor(action, skillLevel: _skillLevel);
    final segType = action == PlanningAction.aim
        ? ContextSegmentType.aim
        : ContextSegmentType.scout;
    final segLabel = action == PlanningAction.aim ? 'Aims' : 'Scouts';
    final segColor = action == PlanningAction.aim ? _aimColor : _scoutColor;
    if (!_contextWindow.consumeUserContext(segType, segLabel, cost, segColor)) return false;
    final result = _planning.applyAction(action, skillLevel: _skillLevel);
    if (result) notifyListeners();
    return result;
  }

  bool loadTool(ToolType type) {
    if (_loadedTools.contains(type)) return false;
    final tool = Tool.all.firstWhere((t) => t.type == type);
    _contextWindow.addToolSegment(tool.name, tool.systemCost, const Color(0xFF5599DD));
    _loadedTools.add(type);
    notifyListeners();
    return true;
  }

  bool unloadTool(ToolType type) {
    if (!_loadedTools.contains(type)) return false;
    final tool = Tool.all.firstWhere((t) => t.type == type);
    _contextWindow.removeToolSegment(tool.name);
    _loadedTools.remove(type);
    notifyListeners();
    return true;
  }

  double get _toolAccuracyBonus {
    double bonus = 0.0;
    for (final type in _loadedTools) {
      final tool = Tool.all.firstWhere((t) => t.type == type);
      bonus += tool.accuracyBonus;
    }
    return bonus;
  }

  double get _toolSpreadBonus {
    double bonus = 0.0;
    for (final type in _loadedTools) {
      final tool = Tool.all.firstWhere((t) => t.type == type);
      bonus += tool.spreadBonus;
    }
    return bonus;
  }

  double get _toolHeatPenalty {
    double penalty = 0.0;
    for (final type in _loadedTools) {
      final tool = Tool.all.firstWhere((t) => t.type == type);
      penalty += tool.heatPenalty;
    }
    return penalty;
  }

  void compact() {
    _contextWindow.compact();
    _planning.bonus.scale(0.4);
    notifyListeners();
  }

  bool _autoCompactIfNeeded() {
    if (_contextWindow.isNearFull) {
      compact();
      return true;
    }
    return false;
  }

  bool startSubagentScout() {
    final success = executePlanningAction(PlanningAction.subagentScout);
    if (success) {
      _planning.setExecutingAction(true);
      notifyListeners();
    }
    return success;
  }

  void completeSubagentScout() {
    _planning.applySubagentScoutResult();
    _planning.setExecutingAction(false);
    notifyListeners();
  }

  void clearShots() {
    _shots.clear();
    _heatLevel = 0.0;
    _loadedTools.clear();
    _contextWindow.reset();
    _planning.reset();
    notifyListeners();
  }

}
