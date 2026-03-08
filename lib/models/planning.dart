enum PlanningAction {
  aim,
  scout,
  load,
}

class PlanningBonus {
  double spreadReduction;
  int scoutNegations;
  double accuracyBoost;

  PlanningBonus({
    this.spreadReduction = 0.0,
    this.scoutNegations = 0,
    this.accuracyBoost = 0.0,
  });

  bool get hasBonus =>
      spreadReduction > 0 || scoutNegations > 0 || accuracyBoost > 0;

  void reset() {
    spreadReduction = 0.0;
    scoutNegations = 0;
    accuracyBoost = 0.0;
  }
}

class PlanningState {
  bool _isPlanning = false;
  bool _isExecutingAction = false;
  final PlanningBonus bonus = PlanningBonus();
  int _aimUses = 0;
  // ignore: unused_field
  int _scoutUses = 0;
  int _loadUses = 0;

  bool get isPlanning => _isPlanning;
  bool get isExecutingAction => _isExecutingAction;
  bool get canFire => !_isPlanning;

  double _diminish(double base, int uses) => base / (1 << uses);

  double contextCostFor(PlanningAction action) {
    switch (action) {
      case PlanningAction.aim:
        return 0.05;
      case PlanningAction.scout:
        return 0.08;
      case PlanningAction.load:
        return 0.06;
    }
  }

  double benefitFor(PlanningAction action) {
    switch (action) {
      case PlanningAction.aim:
        return _diminish(0.30, _aimUses);
      case PlanningAction.scout:
        return 1.0;
      case PlanningAction.load:
        return _diminish(0.15, _loadUses);
    }
  }

  void togglePlanning() {
    _isPlanning = !_isPlanning;
  }

  void setExecutingAction(bool value) {
    _isExecutingAction = value;
  }

  bool applyAction(PlanningAction action) {
    if (!_isPlanning || _isExecutingAction) return false;

    switch (action) {
      case PlanningAction.aim:
        bonus.spreadReduction += _diminish(0.30, _aimUses);
        bonus.spreadReduction = bonus.spreadReduction.clamp(0.0, 0.90);
        _aimUses++;
        break;
      case PlanningAction.scout:
        bonus.scoutNegations++;
        _scoutUses++;
        break;
      case PlanningAction.load:
        bonus.accuracyBoost += _diminish(0.15, _loadUses);
        bonus.accuracyBoost = bonus.accuracyBoost.clamp(0.0, 0.50);
        _loadUses++;
        break;
    }
    return true;
  }

  void consumeBonuses() {
    bonus.reset();
    _aimUses = 0;
    _scoutUses = 0;
    _loadUses = 0;
  }

  void reset() {
    _isPlanning = false;
    _isExecutingAction = false;
    bonus.reset();
    _aimUses = 0;
    _scoutUses = 0;
    _loadUses = 0;
  }
}
