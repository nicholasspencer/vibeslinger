# Itemized Context Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace aggregate context load tracking with itemized segments, add per-shot context cost, and render sub-bars in the context bar.

**Architecture:** Introduce a `ContextSegment` class for named context chunks. Refactor `ContextWindow` to hold lists of segments instead of flat doubles. Update `GameState.fire()` to consume user context per shot. Update the context bar painter to render sub-segments with dividers.

**Tech Stack:** Dart, Flutter, CustomPainter, flutter_test

---

### Task 1: Add ContextSegment class and ContextSegmentType enum

**Files:**
- Modify: `lib/models/context_window.dart:1`

**Step 1: Write the failing test**

Add to `test/models/context_window_test.dart`:

```dart
import 'package:flutter/material.dart';

// Add inside main():
group('ContextSegment', () {
  test('segment has type, label, amount, and color', () {
    final seg = ContextSegment(
      type: ContextSegmentType.harness,
      label: 'Harness',
      amount: 0.15,
      color: const Color(0xFF3366AA),
    );
    expect(seg.type, ContextSegmentType.harness);
    expect(seg.label, 'Harness');
    expect(seg.amount, 0.15);
    expect(seg.color, const Color(0xFF3366AA));
  });
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/context_window_test.dart`
Expected: FAIL — `ContextSegment` and `ContextSegmentType` not defined

**Step 3: Write minimal implementation**

Add to top of `lib/models/context_window.dart`:

```dart
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
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/context_window_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/context_window.dart test/models/context_window_test.dart
git commit -m "feat: add ContextSegment class and ContextSegmentType enum"
```

---

### Task 2: Refactor ContextWindow to use segment lists

**Files:**
- Modify: `lib/models/context_window.dart`
- Modify: `test/models/context_window_test.dart`

**Step 1: Write the failing tests**

Replace the existing `ContextWindow` group in `test/models/context_window_test.dart` with:

```dart
group('ContextWindow with segments', () {
  late ContextWindow ctx;

  setUp(() {
    ctx = ContextWindow();
  });

  test('default has harness system segment at 15%', () {
    expect(ctx.systemSegments.length, 1);
    expect(ctx.systemSegments.first.type, ContextSegmentType.harness);
    expect(ctx.systemSegments.first.amount, 0.15);
    expect(ctx.systemLoad, closeTo(0.15, 0.01));
  });

  test('default user segments are empty', () {
    expect(ctx.userSegments, isEmpty);
    expect(ctx.userLoad, 0.0);
  });

  test('totalLoad is system + buffer + user', () {
    expect(ctx.totalLoad, closeTo(0.30, 0.01)); // 0.15 system + 0.15 buffer
  });

  test('addToolSegment adds a system segment', () {
    ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
    expect(ctx.systemSegments.length, 2);
    expect(ctx.systemLoad, closeTo(0.21, 0.01));
  });

  test('removeToolSegment removes the tool segment', () {
    ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
    ctx.removeToolSegment('Web Search');
    expect(ctx.systemSegments.length, 1);
    expect(ctx.systemLoad, closeTo(0.15, 0.01));
  });

  test('consumeUserContext creates or updates segment by type', () {
    ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
    expect(ctx.userSegments.length, 1);
    expect(ctx.userLoad, closeTo(0.05, 0.01));

    ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
    expect(ctx.userSegments.length, 1); // still 1, updated in place
    expect(ctx.userLoad, closeTo(0.10, 0.01));
  });

  test('consumeUserContext adds different types as separate segments', () {
    ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.05, const Color(0xFF44AA88));
    ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.02, const Color(0xFF44CC88));
    expect(ctx.userSegments.length, 2);
    expect(ctx.userLoad, closeTo(0.07, 0.01));
  });

  test('consumeUserContext returns false when near full', () {
    ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.60, const Color(0xFF44CC88));
    final result = ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.10, const Color(0xFF44CC88));
    expect(result, false);
  });

  test('compact scales each user segment by 0.4', () {
    ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.20, const Color(0xFF44AA88));
    ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.10, const Color(0xFF44CC88));
    ctx.compact();
    expect(ctx.userSegments[0].amount, closeTo(0.08, 0.01)); // 0.20 * 0.4
    expect(ctx.userSegments[1].amount, closeTo(0.04, 0.01)); // 0.10 * 0.4
    expect(ctx.isCompacted, true);
  });

  test('compact removes tiny segments', () {
    ctx.consumeUserContext(ContextSegmentType.scout, 'Scouts', 0.002, const Color(0xFFAACC44));
    ctx.compact();
    expect(ctx.userSegments, isEmpty); // 0.002 * 0.4 = 0.0008 < 0.001
  });

  test('overloaded when total > 0.70', () {
    ctx.consumeUserContext(ContextSegmentType.shot, 'Shots', 0.45, const Color(0xFF44CC88));
    expect(ctx.isOverloaded, true);
  });

  test('reset clears user segments and tool segments', () {
    ctx.addToolSegment('Web Search', 0.06, const Color(0xFF5599DD));
    ctx.consumeUserContext(ContextSegmentType.aim, 'Aims', 0.10, const Color(0xFF44AA88));
    ctx.compact();
    ctx.reset();
    expect(ctx.systemSegments.length, 1); // only harness
    expect(ctx.userSegments, isEmpty);
    expect(ctx.isCompacted, false);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/context_window_test.dart`
Expected: FAIL — new methods don't exist yet

**Step 3: Rewrite ContextWindow**

Replace the `ContextWindow` class in `lib/models/context_window.dart` with:

```dart
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
  bool get isNearFull => totalLoad > 0.90;

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
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/context_window_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/context_window.dart test/models/context_window_test.dart
git commit -m "feat: refactor ContextWindow to use segment lists"
```

---

### Task 3: Add shotCostPenalty to Tool model

**Files:**
- Modify: `lib/models/tool.dart`
- Modify: `test/models/tool_test.dart`

**Step 1: Write the failing test**

Add to `test/models/tool_test.dart` in the `Tool` group:

```dart
test('each tool has a shotCostPenalty', () {
  final webSearch = Tool.all.firstWhere((t) => t.type == ToolType.webSearch);
  expect(webSearch.shotCostPenalty, 0.005);

  final codeAnalysis = Tool.all.firstWhere((t) => t.type == ToolType.codeAnalysis);
  expect(codeAnalysis.shotCostPenalty, 0.01);

  final fileReader = Tool.all.firstWhere((t) => t.type == ToolType.fileReader);
  expect(fileReader.shotCostPenalty, 0.005);

  final codeReview = Tool.all.firstWhere((t) => t.type == ToolType.codeReview);
  expect(codeReview.shotCostPenalty, 0.015);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/tool_test.dart`
Expected: FAIL — `shotCostPenalty` not defined

**Step 3: Add shotCostPenalty field**

In `lib/models/tool.dart`, add the field to the class and update all tool definitions:

```dart
class Tool {
  final ToolType type;
  final String name;
  final double systemCost;
  final String passiveBenefit;
  final double scoutBonus;
  final double accuracyBonus;
  final double spreadBonus;
  final double heatPenalty;
  final double shotCostPenalty;

  const Tool({
    required this.type,
    required this.name,
    required this.systemCost,
    required this.passiveBenefit,
    this.scoutBonus = 0.0,
    this.accuracyBonus = 0.0,
    this.spreadBonus = 0.0,
    this.heatPenalty = 0.0,
    this.shotCostPenalty = 0.0,
  });

  static const List<Tool> all = [
    Tool(
      type: ToolType.webSearch,
      name: 'Web Search',
      systemCost: 0.08,
      passiveBenefit: '+10% scout effectiveness',
      scoutBonus: 0.10,
      shotCostPenalty: 0.005,
    ),
    Tool(
      type: ToolType.codeAnalysis,
      name: 'Code Analysis',
      systemCost: 0.10,
      passiveBenefit: '+10% base accuracy',
      accuracyBonus: 0.10,
      shotCostPenalty: 0.01,
    ),
    Tool(
      type: ToolType.fileReader,
      name: 'File Reader',
      systemCost: 0.06,
      passiveBenefit: '-5% spread',
      spreadBonus: 0.05,
      shotCostPenalty: 0.005,
    ),
    Tool(
      type: ToolType.codeReview,
      name: 'Code Review',
      systemCost: 0.12,
      passiveBenefit: '+5% accuracy, -8% spread',
      accuracyBonus: 0.05,
      spreadBonus: 0.08,
      heatPenalty: 0.5,
      shotCostPenalty: 0.015,
    ),
  ];
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/tool_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/tool.dart test/models/tool_test.dart
git commit -m "feat: add shotCostPenalty to Tool model"
```

---

### Task 4: Update GameState to use segment-based context methods

**Files:**
- Modify: `lib/models/game_state.dart`
- Modify: `test/models/game_state_test.dart`
- Modify: `test/models/tool_test.dart`

This task updates `GameState` to call the new `ContextWindow` segment API instead of the old `consumeContext`/`addToolLoad`/`removeToolLoad` methods.

**Step 1: Write the failing tests**

Add to `test/models/game_state_test.dart`:

```dart
test('firing consumes user context into shot segment', () {
  state.fire();
  final shotSegment = state.contextWindow.userSegments
      .where((s) => s.type == ContextSegmentType.shot)
      .firstOrNull;
  expect(shotSegment, isNotNull);
  expect(shotSegment!.amount, greaterThan(0));
});

test('expert shot cost is less than novice', () {
  state.setSkillLevel(1.0);
  state.fire();
  final expertCost = state.contextWindow.userSegments
      .firstWhere((s) => s.type == ContextSegmentType.shot)
      .amount;

  state.clearShots();
  state.setSkillLevel(0.0);
  state.fire();
  final noviceCost = state.contextWindow.userSegments
      .firstWhere((s) => s.type == ContextSegmentType.shot)
      .amount;

  expect(expertCost, lessThan(noviceCost));
});

test('tools increase per-shot context cost', () {
  state.setSkillLevel(0.5);
  state.fire();
  final baseCost = state.contextWindow.userSegments
      .firstWhere((s) => s.type == ContextSegmentType.shot)
      .amount;

  state.clearShots();
  state.loadTool(ToolType.codeReview);
  state.fire();
  final toolCost = state.contextWindow.userSegments
      .firstWhere((s) => s.type == ContextSegmentType.shot)
      .amount;

  expect(toolCost, greaterThan(baseCost));
});

test('aim action creates aim user segment', () {
  state.togglePlanning();
  state.executePlanningAction(PlanningAction.aim);
  final aimSeg = state.contextWindow.userSegments
      .where((s) => s.type == ContextSegmentType.aim)
      .firstOrNull;
  expect(aimSeg, isNotNull);
  expect(aimSeg!.amount, greaterThan(0));
});

test('scout action creates scout user segment', () {
  state.togglePlanning();
  state.executePlanningAction(PlanningAction.directScout);
  final scoutSeg = state.contextWindow.userSegments
      .where((s) => s.type == ContextSegmentType.scout)
      .firstOrNull;
  expect(scoutSeg, isNotNull);
  expect(scoutSeg!.amount, greaterThan(0));
});

test('loading tool adds system segment', () {
  state.loadTool(ToolType.webSearch);
  expect(state.contextWindow.systemSegments.length, 2); // harness + tool
  expect(state.contextWindow.systemSegments[1].label, 'Web Search');
});

test('unloading tool removes system segment', () {
  state.loadTool(ToolType.webSearch);
  state.unloadTool(ToolType.webSearch);
  expect(state.contextWindow.systemSegments.length, 1); // harness only
});
```

Add import at top of test file:
```dart
import 'package:inference_gunslinger/models/context_window.dart';
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/game_state_test.dart`
Expected: FAIL — fire() doesn't create shot segments yet

**Step 3: Update GameState**

In `lib/models/game_state.dart`, make these changes:

1. Add segment color constants at top of file:

```dart
import 'package:flutter/material.dart';
// Remove: import 'dart:ui';

const _aimColor = Color(0xFF44AA88);
const _scoutColor = Color(0xFFAACC44);
const _shotColor = Color(0xFF44CC88);
const _shotCompactedColor = Color(0xFF2A8855);
```

2. Add per-shot cost calculation:

```dart
static const double _baseShotCost = 0.02;

double get _shotCostMultiplier {
  final skillScale = 1.5 - (_skillLevel * 0.75);
  final toolPenalty = _loadedTools.fold(0.0, (sum, type) {
    final tool = Tool.all.firstWhere((t) => t.type == type);
    return sum + tool.shotCostPenalty;
  });
  return skillScale * (1.0 + toolPenalty / _baseShotCost);
}
```

Wait — simpler formula. The tool penalties are absolute additions, not multiplied by skill. Let's use:

```dart
double get _perShotCost {
  final skillScale = 1.5 - (_skillLevel * 0.75);
  double toolPenalties = 0.0;
  for (final type in _loadedTools) {
    final tool = Tool.all.firstWhere((t) => t.type == type);
    toolPenalties += tool.shotCostPenalty;
  }
  return _baseShotCost * skillScale + toolPenalties;
}
```

3. In `fire()`, after `_planning.consumeBonuses();` add:

```dart
_contextWindow.consumeUserContext(
  ContextSegmentType.shot, 'Shots', _perShotCost, _shotColor,
);
```

4. In `executePlanningAction()`, replace the `consumeContext` call with segment-aware calls:

```dart
bool executePlanningAction(PlanningAction action) {
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
```

5. In `loadTool()`, replace `_contextWindow.addToolLoad(tool.systemCost)` with:

```dart
_contextWindow.addToolSegment(tool.name, tool.systemCost, const Color(0xFF5599DD));
```

6. In `unloadTool()`, replace `_contextWindow.removeToolLoad(tool.systemCost)` with:

```dart
_contextWindow.removeToolSegment(tool.name);
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/game_state_test.dart`
Expected: PASS

Also run all tests to check for regressions:

Run: `flutter test`
Expected: PASS (some existing tests may need updates — see Step 4a)

**Step 4a: Fix existing tests if needed**

The existing `context_window_test.dart` tool group tests use old API (`addToolLoad`, `removeToolLoad`, `consumeContext`). These were already replaced in Task 2. The `game_state_test.dart` tests for `firing increases heat` and `clearShots resets tools` should still pass since the underlying behavior is the same.

The existing test `'default loads are system 20% + buffer 15%'` was already replaced in Task 2 with the 15% harness test.

**Step 5: Commit**

```bash
git add lib/models/game_state.dart test/models/game_state_test.dart
git commit -m "feat: integrate segment-based context tracking into GameState"
```

---

### Task 5: Update context bar painter to render sub-segments

**Files:**
- Modify: `lib/widgets/context_bar.dart`

**Step 1: No unit test needed** — this is pure rendering. Visual verification.

**Step 2: Update the painter**

In `lib/widgets/context_bar.dart`, update `_ContextBarPainter.paint()` to iterate segments instead of drawing single blocks.

Replace the system and user drawing sections (lines 109-128) with:

```dart
// System segments (left-to-right, with dividers)
double x = 0;
for (int i = 0; i < contextWindow.systemSegments.length; i++) {
  final seg = contextWindow.systemSegments[i];
  final segWidth = size.width * seg.amount;
  canvas.drawRect(
    Rect.fromLTWH(x, 0, segWidth, size.height),
    Paint()..color = seg.color.withValues(alpha: 0.7),
  );
  if (i > 0) {
    // 1px divider between segments
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }
  x += segWidth;
}

// User segments (left-to-right, with dividers)
final userStartX = x;
for (int i = 0; i < contextWindow.userSegments.length; i++) {
  final seg = contextWindow.userSegments[i];
  final segWidth = size.width * seg.amount;
  final color = contextWindow.isCompacted
      ? seg.color.withValues(alpha: 0.4)
      : seg.color.withValues(alpha: 0.7);
  canvas.drawRect(
    Rect.fromLTWH(x, 0, segWidth, size.height),
    Paint()..color = color,
  );
  if (i > 0) {
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }
  x += segWidth;
}
// Divider between system and user if both have content
if (contextWindow.userSegments.isNotEmpty) {
  canvas.drawLine(
    Offset(userStartX, 0),
    Offset(userStartX, size.height),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1,
  );
}
```

**Step 3: Update shouldRepaint**

```dart
@override
bool shouldRepaint(covariant _ContextBarPainter oldDelegate) => true;
```

Simple `true` is fine — the bar is small and repaints are cheap. Avoids complex segment comparison logic.

**Step 4: Run the app to visually verify**

Run: `flutter run -d chrome`
Expected: Context bar shows sub-segments with dividers. System bar shows harness (dark blue). Loading tools adds lighter blue segments. Aiming/scouting/shooting adds colored user segments.

**Step 5: Commit**

```bash
git add lib/widgets/context_bar.dart
git commit -m "feat: render context bar with sub-segment dividers"
```

---

### Task 6: Update legend and clean up imports

**Files:**
- Modify: `lib/widgets/context_bar.dart`
- Modify: `lib/models/game_state.dart`

**Step 1: Update legend colors**

The legend stays simple (System/User/Compact) but update the system legend color to match the harness color:

In `context_bar.dart`, change the system legend color from `0xFF4488CC` to `0xFF3366AA` to match the harness segment color.

**Step 2: Clean up any remaining references to old API**

Search for any remaining calls to `consumeContext`, `addToolLoad`, `removeToolLoad` across the codebase and update them.

Run: `grep -r "consumeContext\|addToolLoad\|removeToolLoad" lib/`
Expected: No matches (all replaced in previous tasks)

**Step 3: Run all tests**

Run: `flutter test`
Expected: All PASS

**Step 4: Run the app for final visual check**

Run: `flutter run -d chrome`
Expected: Everything works. Sub-bars visible. Shots consume context. Tools add system segments and increase shot cost.

**Step 5: Commit**

```bash
git add lib/widgets/context_bar.dart lib/models/game_state.dart
git commit -m "chore: update legend colors and clean up old context API references"
```

---

### Task 7: Update remaining tests for new base system load

**Files:**
- Modify: `test/models/game_state_test.dart`
- Modify: `test/models/tool_test.dart`

**Step 1: Fix any tests that assumed 20% base system load**

The base changed from 20% to 15%. Update assertions:

In `test/models/tool_test.dart`, the `addToolLoad increases system load` test now uses `addToolSegment`. Update:

```dart
test('addToolSegment increases system load', () {
  ctx.addToolSegment('Web Search', 0.08, const Color(0xFF5599DD));
  expect(ctx.systemLoad, closeTo(0.23, 0.01)); // 0.15 + 0.08
});
```

Update any other assertions that reference the old 20%/35% values.

**Step 2: Run all tests**

Run: `flutter test`
Expected: All PASS

**Step 3: Commit**

```bash
git add test/
git commit -m "test: update tests for 15% base system load and segment API"
```
