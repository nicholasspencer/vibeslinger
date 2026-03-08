class ContextWindow {
  static const double baseSystemLoad = 0.20;
  static const double compactionBufferSize = 0.165;

  final double bufferLoad;
  double _systemLoad;
  double _userLoad;
  bool _isCompacted = false;

  ContextWindow({
    double systemLoad = baseSystemLoad,
    this.bufferLoad = 0.15,
    double userLoad = 0.0,
  })  : _systemLoad = systemLoad,
        _userLoad = userLoad;

  double get systemLoad => _systemLoad;
  double get userLoad => _userLoad;
  bool get isCompacted => _isCompacted;
  double get totalLoad => (_systemLoad + bufferLoad + _userLoad).clamp(0.0, 1.0);
  double get remainingCapacity => (1.0 - totalLoad).clamp(0.0, 1.0);
  double get compactionThreshold => 1.0 - compactionBufferSize;
  bool get isInCompactionZone => totalLoad > compactionThreshold;
  bool get isOverloaded => totalLoad > 0.70;
  bool get isNearFull => totalLoad > 0.90;

  double get loadWobblePenalty {
    if (totalLoad <= 0.70) return 0.0;
    return ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  double get heatRateMultiplier {
    if (totalLoad <= 0.70) return 1.0;
    return 1.0 + ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  bool consumeContext(double amount) {
    if (isNearFull) return false;
    final maxUser = 1.0 - _systemLoad - bufferLoad;
    _userLoad = (_userLoad + amount).clamp(0.0, maxUser);
    return true;
  }

  void addToolLoad(double cost) {
    _systemLoad = (_systemLoad + cost).clamp(0.0, 1.0);
  }

  void removeToolLoad(double cost) {
    _systemLoad = (_systemLoad - cost).clamp(baseSystemLoad, 1.0);
  }

  void compact() {
    _userLoad = _userLoad * 0.4;
    _isCompacted = true;
  }

  void reset() {
    _systemLoad = baseSystemLoad;
    _userLoad = 0.0;
    _isCompacted = false;
  }

  ContextWindow copy() {
    return ContextWindow(
      systemLoad: _systemLoad,
      bufferLoad: bufferLoad,
      userLoad: _userLoad,
    ).._isCompacted = _isCompacted;
  }
}
