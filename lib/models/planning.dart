enum PlanningAction {
  aim,
  directScout,
  subagentScout,
}

class PlanningBonus {
  double spreadReduction;
  int scoutNegations;

  PlanningBonus({
    this.spreadReduction = 0.0,
    this.scoutNegations = 0,
  });

  bool get hasBonus => spreadReduction > 0 || scoutNegations > 0;

  void reset() {
    spreadReduction = 0.0;
    scoutNegations = 0;
  }

  void scale(double factor) {
    spreadReduction = (spreadReduction * factor).clamp(0.0, 0.90);
    scoutNegations = (scoutNegations * factor).floor();
  }
}

class PlanningState {
  bool _isPlanning = false;
  bool _isExecutingAction = false;
  final PlanningBonus bonus = PlanningBonus();
  int _aimUses = 0;

  bool get isPlanning => _isPlanning;
  bool get isExecutingAction => _isExecutingAction;
  bool get canFire => !_isPlanning && !_isExecutingAction;

  double _diminish(double base, int uses) => base / (1 << uses);

  double contextCostFor(PlanningAction action) {
    switch (action) {
      case PlanningAction.aim:
        return 0.05;
      case PlanningAction.directScout:
        return 0.08;
      case PlanningAction.subagentScout:
        return 0.03;
    }
  }

  void togglePlanning() {
    _isPlanning = !_isPlanning;
  }

  void setExecutingAction(bool value) {
    _isExecutingAction = value;
  }

  bool applyAction(PlanningAction action) {
    if (!_isPlanning) return false;
    if (action != PlanningAction.subagentScout && _isExecutingAction) return false;

    switch (action) {
      case PlanningAction.aim:
        bonus.spreadReduction += _diminish(0.30, _aimUses);
        bonus.spreadReduction = bonus.spreadReduction.clamp(0.0, 0.90);
        _aimUses++;
        break;
      case PlanningAction.directScout:
        bonus.scoutNegations++;
        break;
      case PlanningAction.subagentScout:
        // Benefit applied after delay via applySubagentScoutResult()
        break;
    }
    return true;
  }

  void applySubagentScoutResult() {
    bonus.scoutNegations++;
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
