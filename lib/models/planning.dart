enum PlanningAction {
  aim,
  directScout,
  subagentScout,
}

class PlanningBonus {
  double spreadReduction;

  PlanningBonus({
    this.spreadReduction = 0.0,
  });

  bool get hasBonus => spreadReduction > 0;

  void reset() {
    spreadReduction = 0.0;
  }

  void scale(double factor) {
    spreadReduction = (spreadReduction * factor).clamp(0.0, 0.90);
  }
}

class PlanningState {
  bool _isPlanning = true;
  bool _isExecutingAction = false;
  final PlanningBonus bonus = PlanningBonus();
  int _aimUses = 0;

  bool get isPlanning => _isPlanning;
  bool get isExecutingAction => _isExecutingAction;
  bool get canFire => !_isExecutingAction;

  double _diminish(double base, int uses) => base / (1 << uses);

  double contextCostFor(PlanningAction action, {double skillLevel = 1.0}) {
    final skillScale = 1.5 - skillLevel * 0.5;
    switch (action) {
      case PlanningAction.aim:
        return 0.05 * skillScale;
      case PlanningAction.directScout:
        return 0.08 * skillScale;
      case PlanningAction.subagentScout:
        return 0.03 * skillScale;
    }
  }

  void togglePlanning() {
    _isPlanning = !_isPlanning;
  }

  void setExecutingAction(bool value) {
    _isExecutingAction = value;
  }

  bool applyAction(PlanningAction action, {double skillLevel = 1.0}) {
    if (!_isPlanning) return false;
    if (action != PlanningAction.subagentScout && _isExecutingAction) return false;

    switch (action) {
      case PlanningAction.aim:
        final skillScale = 0.5 + skillLevel * 0.5;
        bonus.spreadReduction += _diminish(0.30 * skillScale, _aimUses);
        bonus.spreadReduction = bonus.spreadReduction.clamp(0.0, 0.90);
        _aimUses++;
        break;
      case PlanningAction.directScout:
        bonus.spreadReduction = (bonus.spreadReduction + 0.20).clamp(0.0, 0.90);
        break;
      case PlanningAction.subagentScout:
        // Benefit applied after delay via applySubagentScoutResult()
        break;
    }
    return true;
  }

  void applySubagentScoutResult() {
    bonus.spreadReduction = (bonus.spreadReduction + 0.15).clamp(0.0, 0.90);
  }

  void consumeBonuses() {
    bonus.reset();
    _aimUses = 0;
  }

  void reset() {
    _isPlanning = false;
    _isExecutingAction = false;
    bonus.reset();
    _aimUses = 0;
  }
}
