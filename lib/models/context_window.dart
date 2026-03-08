import 'package:flutter/material.dart';

enum ContextSegmentType { harness, tool, aim, scout, shot }

class ContextSegment {
  final ContextSegmentType type;
  final String label;
  double amount;
  final Color color;

  ContextSegment({
    required this.type,
    required this.label,
    required this.amount,
    required this.color,
  });
}

class ContextWindow {
  static const double baseSystemLoad = 0.15;
  static const double compactionBufferSize = 0.165;

  final List<ContextSegment> systemSegments = [];
  final List<ContextSegment> userSegments = [];
  final double bufferLoad;
  bool _isCompacted = false;

  ContextWindow({this.bufferLoad = 0.15}) {
    systemSegments.add(ContextSegment(
      type: ContextSegmentType.harness,
      label: 'Harness',
      amount: baseSystemLoad,
      color: const Color(0xFF3366AA),
    ));
  }

  double get systemLoad => systemSegments.fold(0.0, (sum, s) => sum + s.amount);
  double get userLoad => userSegments.fold(0.0, (sum, s) => sum + s.amount);
  bool get isCompacted => _isCompacted;
  double get totalLoad => (systemLoad + bufferLoad + userLoad).clamp(0.0, 1.0);
  double get remainingCapacity => (1.0 - totalLoad).clamp(0.0, 1.0);
  double get compactionThreshold => 1.0 - compactionBufferSize;
  bool get isInCompactionZone => totalLoad > compactionThreshold;
  bool get isOverloaded => totalLoad > 0.70;
  bool get isNearFull => totalLoad > 0.8999;

  double get loadWobblePenalty {
    if (totalLoad <= 0.70) return 0.0;
    return ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  double get heatRateMultiplier {
    if (totalLoad <= 0.70) return 1.0;
    return 1.0 + ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  void addToolSegment(String label, double cost, Color color) {
    systemSegments.add(ContextSegment(
      type: ContextSegmentType.tool,
      label: label,
      amount: cost,
      color: color,
    ));
  }

  void removeToolSegment(String label) {
    systemSegments.removeWhere((s) => s.type == ContextSegmentType.tool && s.label == label);
  }

  bool consumeUserContext(ContextSegmentType type, String label, double amount, Color color) {
    if (isNearFull) return false;
    final existing = userSegments.where((s) => s.type == type).firstOrNull;
    if (existing != null) {
      final maxAdd = 1.0 - totalLoad;
      existing.amount += amount.clamp(0.0, maxAdd);
    } else {
      userSegments.add(ContextSegment(
        type: type,
        label: label,
        amount: amount,
        color: color,
      ));
    }
    return true;
  }

  void compact() {
    for (final seg in userSegments) {
      seg.amount *= 0.4;
    }
    userSegments.removeWhere((s) => s.amount < 0.001);
    _isCompacted = true;
  }

  void reset() {
    systemSegments.removeWhere((s) => s.type != ContextSegmentType.harness);
    userSegments.clear();
    _isCompacted = false;
  }

  ContextWindow copy() {
    final c = ContextWindow(bufferLoad: bufferLoad);
    c.systemSegments.clear();
    for (final s in systemSegments) {
      c.systemSegments.add(ContextSegment(
        type: s.type, label: s.label, amount: s.amount, color: s.color,
      ));
    }
    for (final s in userSegments) {
      c.userSegments.add(ContextSegment(
        type: s.type, label: s.label, amount: s.amount, color: s.color,
      ));
    }
    c._isCompacted = _isCompacted;
    return c;
  }
}
