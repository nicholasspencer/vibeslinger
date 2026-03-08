class ContextWindow {
  final double systemLoad;
  final double bufferLoad;
  double _userLoad;

  ContextWindow({
    this.systemLoad = 0.20,
    this.bufferLoad = 0.15,
    double userLoad = 0.0,
  }) : _userLoad = userLoad;

  double get userLoad => _userLoad;
  double get totalLoad => (systemLoad + bufferLoad + _userLoad).clamp(0.0, 1.0);
  double get remainingCapacity => (1.0 - totalLoad).clamp(0.0, 1.0);
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
    _userLoad = (_userLoad + amount).clamp(0.0, 1.0 - systemLoad - bufferLoad);
    return true;
  }

  void reset() {
    _userLoad = 0.0;
  }

  ContextWindow copy() {
    return ContextWindow(
      systemLoad: systemLoad,
      bufferLoad: bufferLoad,
      userLoad: _userLoad,
    );
  }
}
