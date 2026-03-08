# Scout Accuracy & Remove Environment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make scouting increase accuracy (spreadReduction) and remove environment penalties entirely.

**Architecture:** Remove `EnvironmentFactors` class and all references. Change scout actions from `scoutNegations` to `spreadReduction`. Direct scout adds 0.20 spread reduction, subagent adds 0.15 (both flat, no diminishing returns). Remove `scoutNegations` from `PlanningBonus` and `Tool`.

**Tech Stack:** Flutter/Dart

---

### Task 1: Update PlanningBonus and PlanningState

**Files:**
- Modify: `lib/models/planning.dart`
- Test: `test/models/planning_test.dart`

**Step 1: Write/update failing tests**

In `test/models/planning_test.dart`, replace the scout-related tests:

```dart
test('direct scout adds spread reduction', () {
  planning.togglePlanning();
  planning.applyAction(PlanningAction.directScout);
  expect(planning.bonus.spreadReduction, closeTo(0.20, 0.01));
});

test('multiple direct scouts stack', () {
  planning.togglePlanning();
  planning.applyAction(PlanningAction.directScout);
  planning.applyAction(PlanningAction.directScout);
  expect(planning.bonus.spreadReduction, closeTo(0.40, 0.01));
});

test('subagent scout does not immediately apply', () {
  planning.togglePlanning();
  planning.applyAction(PlanningAction.subagentScout);
  expect(planning.bonus.spreadReduction, closeTo(0.0, 0.01));
});

test('applySubagentScoutResult adds spread reduction', () {
  planning.togglePlanning();
  planning.applySubagentScoutResult();
  expect(planning.bonus.spreadReduction, closeTo(0.15, 0.01));
});
```

Remove the test `'bonus scale reduces proportionally'` scoutNegations assertion — update to only check spreadReduction.

**Step 2: Run tests to verify they fail**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test test/models/planning_test.dart`
Expected: FAIL (directScout still adds scoutNegations, not spreadReduction)

**Step 3: Update planning.dart**

In `lib/models/planning.dart`:

1. Remove `scoutNegations` from `PlanningBonus`:
```dart
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
```

2. Update `applyAction` for directScout:
```dart
case PlanningAction.directScout:
  bonus.spreadReduction += 0.20;
  bonus.spreadReduction = bonus.spreadReduction.clamp(0.0, 0.90);
  break;
```

3. Update `applySubagentScoutResult`:
```dart
void applySubagentScoutResult() {
  bonus.spreadReduction += 0.15;
  bonus.spreadReduction = bonus.spreadReduction.clamp(0.0, 0.90);
}
```

**Step 4: Run tests to verify they pass**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test test/models/planning_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/planning.dart test/models/planning_test.dart
git commit -m "feat: scout actions now add spreadReduction instead of scoutNegations"
```

---

### Task 2: Remove EnvironmentFactors from GameState

**Files:**
- Modify: `lib/models/game_state.dart`
- Test: `test/models/game_state_test.dart`

**Step 1: Update tests**

In `test/models/game_state_test.dart`:

1. Remove the `'environment penalties stack'` test entirely.
2. Remove the `'skill creator removes 1 environment penalty'` test entirely.
3. Remove all imports/references to `EnvironmentFactors`.
4. Add a new test for scout improving accuracy:

```dart
test('direct scout improves effective accuracy', () {
  final before = state.effectiveAccuracy;
  state.togglePlanning();
  state.executePlanningAction(PlanningAction.directScout);
  expect(state.effectiveAccuracy, greaterThan(before));
});
```

**Step 2: Run tests to verify failures**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test test/models/game_state_test.dart`
Expected: Compilation errors (EnvironmentFactors still referenced in game_state.dart)

**Step 3: Update game_state.dart**

1. Remove `EnvironmentFactors` class entirely.
2. Remove `_environment` field, getter, `setEnvironment()` method.
3. Remove `_effectiveEnvironmentPenalty` getter.
4. Remove `_toolScoutNegations` getter.
5. Update `effectiveAccuracy`:
```dart
double get effectiveAccuracy {
  final base = _selectedGun.baseAccuracy + _toolAccuracyBonus;
  final aimBonus = _planning.bonus.spreadReduction * 0.3;
  final heat = 1.0 - (_heatLevel * 0.35);
  final loadPenalty = 1.0 - (_contextWindow.loadWobblePenalty * 0.4);
  return ((base + aimBonus) * heat * loadPenalty).clamp(0.05, 0.99);
}
```
(Just remove `* env` from the calculation.)

**Step 4: Run tests to verify they pass**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test test/models/game_state_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/game_state.dart test/models/game_state_test.dart
git commit -m "feat: remove EnvironmentFactors, scout now improves accuracy"
```

---

### Task 3: Remove scoutNegations from Tool model

**Files:**
- Modify: `lib/models/tool.dart`
- Test: `test/models/tool_test.dart`

**Step 1: Update tool.dart**

Remove `scoutNegations` field from `Tool` class. Remove it from the `skillCreator` tool definition. Update the `skillCreator` `passiveBenefit` string to just `'+25% accuracy'`.

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
  // ... Tool.all stays the same except skillCreator loses scoutNegations
}
```

**Step 2: Run tests**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test test/models/tool_test.dart`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/models/tool.dart test/models/tool_test.dart
git commit -m "feat: remove scoutNegations from Tool model"
```

---

### Task 4: Update UI — remove environment section, update scout descriptions

**Files:**
- Modify: `lib/widgets/sidebar_panel.dart`
- Modify: `lib/widgets/game_canvas.dart`
- Modify: `lib/painters/stick_figure_painter.dart`

**Step 1: Update sidebar_panel.dart**

1. Remove entire ENVIRONMENT section (lines 107-151): the `_sectionLabel('ENVIRONMENT')`, all three `_buildEnvironmentChip` calls, and spacers.
2. Remove `_buildEnvironmentChip` method entirely.
3. Update scout info text from "Remove Penalties" to "Improve Accuracy":
```dart
onInfo: () => _showInfo(
  'Improve Accuracy (Scout)',
  'Improves accuracy by reducing shot spread.\n\n'
  '• Direct Scout: 8% user context, +20% spread reduction (instant)\n'
  '• Subagent Scout: 3% user context, +15% spread reduction (~3s delay)\n\n'
  'Maps to retrieval / tool use — gathering information to improve response quality.',
  accuracyImpact: '+6% accuracy per direct scout, +4.5% per subagent',
),
```
4. Update popup menu item descriptions:
   - Direct: `'...% user ctx • +20% spread reduction (instant)'`
   - Subagent: `'...% user ctx • +15% spread reduction (~3s delay)'`
5. Update Skill Creator tool info to remove "removes 1 penalty" text.

**Step 2: Update game_canvas.dart**

Remove the three environment property references from `StickFigurePainter` constructor (lines 171-173). Just remove the `isWindy`, `isLowLight`, `isUnstable` named args.

**Step 3: Update stick_figure_painter.dart**

1. Remove `isWindy`, `isLowLight`, `isUnstable` fields from constructor and class.
2. Remove wind lean calculation (`leanX`), use `0.0` instead.
3. Remove squint eyes block (`if (isLowLight)`).
4. Remove `isUnstable` from wobble and stance calculations.

**Step 4: Run all tests**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/widgets/sidebar_panel.dart lib/widgets/game_canvas.dart lib/painters/stick_figure_painter.dart
git commit -m "feat: remove environment UI, update scout descriptions"
```

---

### Task 5: Run app and verify

**Step 1: Run the app**

Run: `cd /Users/nico/development/com.nicospencer/inference-visual && flutter run -d macos`

Verify:
- No environment section in sidebar
- Scout (both direct and subagent) visibly increases accuracy percentage
- Aim still works with diminishing returns
- All planning actions consume context correctly
