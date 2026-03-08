# Context Window & Planning System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add context window backpack visualization and a planning mode with three actions (Aim, Scout, Load) that consume context but improve accuracy.

**Architecture:** Extend GameState with context window tracking and planning state. Add a backpack painter to the stick figure. Add context window bar widget and planning controls to the UI. Planning actions are animated, consume context, improve next-volley accuracy with diminishing returns, and disable firing while active.

**Tech Stack:** Flutter, CustomPainter, ChangeNotifier, AnimationController

---

### Task 1: Context Window Model

**Files:**
- Create: `lib/models/context_window.dart`
- Modify: `lib/models/game_state.dart`
- Create: `test/models/context_window_test.dart`

**Step 1: Write the ContextWindow model**

```dart
// lib/models/context_window.dart

/// Represents the context window as a backpack with three compartments.
class ContextWindow {
  /// System/tools overhead — always present (blue/water)
  final double systemLoad; // 0.0 to 1.0, default 0.20

  /// Safety buffer — reserved space (amber/survival gear)
  final double bufferLoad; // 0.0 to 1.0, default 0.15

  /// User-controllable space — mission payload (green/operational gear)
  double _userLoad; // starts at 0.0, grows with planning

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

  /// Wobble penalty from heavy load. Returns 0.0 when light, up to 1.0 when full.
  double get loadWobblePenalty {
    if (totalLoad <= 0.70) return 0.0;
    // Linear ramp from 0.7 to 1.0
    return ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  /// Heat rate multiplier. >0.7 load means heat builds faster.
  double get heatRateMultiplier {
    if (totalLoad <= 0.70) return 1.0;
    // Up to 2x heat rate at full load
    return 1.0 + ((totalLoad - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  /// Add to user load (planning consumes context). Returns false if no room.
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
```

**Step 2: Write tests**

```dart
// test/models/context_window_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
  group('ContextWindow', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('default loads are system 20% + buffer 15%', () {
      expect(ctx.systemLoad, 0.20);
      expect(ctx.bufferLoad, 0.15);
      expect(ctx.userLoad, 0.0);
      expect(ctx.totalLoad, closeTo(0.35, 0.01));
    });

    test('is not overloaded at default', () {
      expect(ctx.isOverloaded, false);
      expect(ctx.loadWobblePenalty, 0.0);
    });

    test('consumeContext adds to user load', () {
      ctx.consumeContext(0.10);
      expect(ctx.userLoad, closeTo(0.10, 0.01));
      expect(ctx.totalLoad, closeTo(0.45, 0.01));
    });

    test('overloaded when total > 0.70', () {
      ctx.consumeContext(0.40); // 0.20 + 0.15 + 0.40 = 0.75
      expect(ctx.isOverloaded, true);
      expect(ctx.loadWobblePenalty, greaterThan(0.0));
    });

    test('heat rate multiplier increases when overloaded', () {
      expect(ctx.heatRateMultiplier, 1.0);
      ctx.consumeContext(0.50); // total = 0.85
      expect(ctx.heatRateMultiplier, greaterThan(1.0));
    });

    test('cannot consume past capacity', () {
      ctx.consumeContext(0.60); // max user = 0.65
      expect(ctx.userLoad, closeTo(0.65, 0.01));
    });

    test('isNearFull blocks further consumption', () {
      ctx.consumeContext(0.60); // total ~0.95
      final result = ctx.consumeContext(0.10);
      expect(result, false);
    });

    test('reset clears user load', () {
      ctx.consumeContext(0.30);
      ctx.reset();
      expect(ctx.userLoad, 0.0);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/models/context_window_test.dart`
Expected: All 8 tests pass

**Step 4: Integrate into GameState**

Modify `lib/models/game_state.dart`:
- Add `import 'context_window.dart';`
- Add field: `final ContextWindow _contextWindow = ContextWindow();`
- Add getter: `ContextWindow get contextWindow => _contextWindow;`
- Update `effectiveAccuracy` to include context load penalty:
  ```dart
  double get effectiveAccuracy {
    final base = _selectedGun.baseAccuracy;
    final skill = 0.5 + (_skillLevel * 0.5);
    final heat = 1.0 - (_heatLevel * 0.6);
    final env = _environment.penaltyMultiplier;
    final loadPenalty = 1.0 - (_contextWindow.loadWobblePenalty * 0.4);
    return (base * skill * heat * env * loadPenalty).clamp(0.05, 1.0);
  }
  ```
- Update `fire()` heat increment to use context heat multiplier:
  ```dart
  _heatLevel = (_heatLevel + 0.12 * _contextWindow.heatRateMultiplier).clamp(0.0, 1.0);
  ```
- Update `clearShots()` to also reset context: `_contextWindow.reset();`
- Update `loadScene()` to reset context for all scenes

**Step 5: Update existing tests**

The existing test for default accuracy will change because `loadPenalty` is 1.0 at default load (no change). Verify existing tests still pass.

Run: `flutter test`
Expected: All tests pass (accuracy values unchanged since default context load < 0.7)

**Step 6: Commit**

```bash
git add lib/models/context_window.dart lib/models/game_state.dart test/models/context_window_test.dart
git commit -m "feat: add context window model with load tracking and accuracy impact"
```

---

### Task 2: Planning State Model

**Files:**
- Create: `lib/models/planning.dart`
- Modify: `lib/models/game_state.dart`
- Create: `test/models/planning_test.dart`

**Step 1: Write the Planning model**

```dart
// lib/models/planning.dart

enum PlanningAction {
  aim,   // reduces spread
  scout, // negates environment penalty
  load,  // boosts base accuracy
}

class PlanningBonus {
  double spreadReduction;    // 0.0 to 1.0, reduces shot spread
  int scoutNegations;        // count of environment penalties negated
  double accuracyBoost;      // 0.0 to 1.0, added to base accuracy

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
  bool _isExecutingAction = false; // true while animation plays
  final PlanningBonus bonus = PlanningBonus();

  // Track uses for diminishing returns
  int _aimUses = 0;
  int _scoutUses = 0;
  int _loadUses = 0;

  bool get isPlanning => _isPlanning;
  bool get isExecutingAction => _isExecutingAction;
  bool get canFire => !_isPlanning;

  // Diminishing returns: first use full value, halves each subsequent use
  double _diminish(double base, int uses) => base / (1 << uses); // base / 2^uses

  /// Context cost for each action
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

  /// Benefit amount for next use (with diminishing returns)
  double benefitFor(PlanningAction action) {
    switch (action) {
      case PlanningAction.aim:
        return _diminish(0.30, _aimUses);
      case PlanningAction.scout:
        return 1.0; // negates one penalty (no diminishing for boolean)
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

  /// Apply a planning action. Returns true if applied.
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

  /// Called after firing — consume planning bonuses
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
```

**Step 2: Write tests**

```dart
// test/models/planning_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/planning.dart';

void main() {
  group('PlanningState', () {
    late PlanningState planning;

    setUp(() {
      planning = PlanningState();
    });

    test('starts not in planning mode', () {
      expect(planning.isPlanning, false);
      expect(planning.canFire, true);
    });

    test('toggle enables planning and disables fire', () {
      planning.togglePlanning();
      expect(planning.isPlanning, true);
      expect(planning.canFire, false);
    });

    test('aim applies spread reduction with diminishing returns', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.45, 0.01)); // 0.30 + 0.15
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.525, 0.01)); // + 0.075
    });

    test('scout increments negation count', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.scout);
      expect(planning.bonus.scoutNegations, 1);
      planning.applyAction(PlanningAction.scout);
      expect(planning.bonus.scoutNegations, 2);
    });

    test('load applies accuracy boost with diminishing returns', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.load);
      expect(planning.bonus.accuracyBoost, closeTo(0.15, 0.01));
      planning.applyAction(PlanningAction.load);
      expect(planning.bonus.accuracyBoost, closeTo(0.225, 0.01)); // + 0.075
    });

    test('cannot apply action when not planning', () {
      final result = planning.applyAction(PlanningAction.aim);
      expect(result, false);
    });

    test('consumeBonuses resets all bonuses and use counts', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      planning.applyAction(PlanningAction.load);
      planning.consumeBonuses();
      expect(planning.bonus.hasBonus, false);
      // Next aim should give full 0.30 again (uses reset)
      planning.applyAction(PlanningAction.aim);
      expect(planning.bonus.spreadReduction, closeTo(0.30, 0.01));
    });

    test('context costs are correct', () {
      expect(planning.contextCostFor(PlanningAction.aim), 0.05);
      expect(planning.contextCostFor(PlanningAction.scout), 0.08);
      expect(planning.contextCostFor(PlanningAction.load), 0.06);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/models/planning_test.dart`
Expected: All 8 tests pass

**Step 4: Integrate into GameState**

Modify `lib/models/game_state.dart`:
- Add `import 'planning.dart';`
- Add field: `final PlanningState _planning = PlanningState();`
- Add getter: `PlanningState get planning => _planning;`
- Update `effectiveAccuracy` to include planning bonuses:
  ```dart
  double get effectiveAccuracy {
    final base = _selectedGun.baseAccuracy + _planning.bonus.accuracyBoost;
    final skill = 0.5 + (_skillLevel * 0.5);
    final heat = 1.0 - (_heatLevel * 0.6);
    final env = _effectiveEnvironmentPenalty;
    final loadPenalty = 1.0 - (_contextWindow.loadWobblePenalty * 0.4);
    return (base * skill * heat * env * loadPenalty).clamp(0.05, 1.0);
  }
  ```
- Add helper for scout-modified environment:
  ```dart
  double get _effectiveEnvironmentPenalty {
    double penalty = 1.0;
    int negationsLeft = _planning.bonus.scoutNegations;
    // Negate penalties in order: unstable (worst) first, then windy, then lowLight
    if (_environment.unstable && negationsLeft > 0) {
      negationsLeft--;
    } else if (_environment.unstable) {
      penalty *= 0.78;
    }
    if (_environment.windy && negationsLeft > 0) {
      negationsLeft--;
    } else if (_environment.windy) {
      penalty *= 0.82;
    }
    if (_environment.lowLight && negationsLeft > 0) {
      negationsLeft--;
    } else if (_environment.lowLight) {
      penalty *= 0.88;
    }
    return penalty;
  }
  ```
- Update `fire()` to apply spread reduction and consume bonuses:
  ```dart
  ShotResult fire() {
    if (!_planning.canFire) throw StateError('Cannot fire while planning');
    final accuracy = effectiveAccuracy;
    final spreadMultiplier = 1.0 - _planning.bonus.spreadReduction;
    final spread = (1.0 - accuracy) * 2.0 * spreadMultiplier;
    // ... Box-Muller with modified spread ...
    // After shot:
    _planning.consumeBonuses();
    // Exit planning mode if it was on
    if (_planning.isPlanning) _planning.togglePlanning();
    notifyListeners();
    return shot;
  }
  ```
- Add planning methods:
  ```dart
  void togglePlanning() {
    _planning.togglePlanning();
    notifyListeners();
  }

  bool executePlanningAction(PlanningAction action) {
    if (_contextWindow.isNearFull) return false;
    final cost = _planning.contextCostFor(action);
    if (!_contextWindow.consumeContext(cost)) return false;
    final result = _planning.applyAction(action);
    if (result) notifyListeners();
    return result;
  }
  ```
- Update `clearShots()` and `loadScene()` to also reset planning state
- Add scene 4 "The Planner" to `loadScene()`:
  ```dart
  case 4: // The Planner
    _selectedGun = Gun.all[0];
    _skillLevel = 1.0;
    _environment = const EnvironmentFactors(windy: true);
    // Pre-apply some planning for demo
    _planning.reset();
    _contextWindow.reset();
    break;
  ```

**Step 5: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/models/planning.dart lib/models/game_state.dart test/models/planning_test.dart
git commit -m "feat: add planning state model with diminishing returns and context consumption"
```

---

### Task 3: Backpack Painter

**Files:**
- Create: `lib/painters/backpack_painter.dart`
- Modify: `lib/painters/stick_figure_painter.dart`

**Step 1: Create the backpack painter**

```dart
// lib/painters/backpack_painter.dart
import 'package:flutter/material.dart';
import '../models/context_window.dart';

class BackpackPainter {
  /// Draw backpack on the stick figure. Call from within StickFigurePainter.
  /// shoulderPos is where the backpack attaches. scale is the figure's scale factor.
  static void paint(
    Canvas canvas,
    Offset shoulderPos,
    double scale,
    ContextWindow contextWindow,
  ) {
    final packWidth = 16.0 * scale;
    final packHeight = 30.0 * scale;
    final packLeft = shoulderPos.dx - packWidth - 8 * scale;
    final packTop = shoulderPos.dy - 5 * scale;

    // Backpack outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    final packRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(packLeft, packTop, packWidth, packHeight),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(packRect, outlinePaint);

    // Strap line to shoulder
    final strapPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(
      Offset(packLeft + packWidth, packTop + 3 * scale),
      Offset(shoulderPos.dx, shoulderPos.dy),
      strapPaint,
    );

    // Draw compartments as stacked sections (bottom to top: system, buffer, user)
    final innerLeft = packLeft + 2 * scale;
    final innerWidth = packWidth - 4 * scale;
    final innerBottom = packTop + packHeight - 2 * scale;
    final innerHeight = packHeight - 4 * scale;

    // System (blue/water) — always at bottom
    final systemHeight = innerHeight * contextWindow.systemLoad;
    final systemRect = Rect.fromLTWH(
      innerLeft,
      innerBottom - systemHeight,
      innerWidth,
      systemHeight,
    );
    canvas.drawRect(
      systemRect,
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.6),
    );

    // Buffer (amber/survival) — above system
    final bufferHeight = innerHeight * contextWindow.bufferLoad;
    final bufferRect = Rect.fromLTWH(
      innerLeft,
      innerBottom - systemHeight - bufferHeight,
      innerWidth,
      bufferHeight,
    );
    canvas.drawRect(
      bufferRect,
      Paint()..color = const Color(0xFFCCA844).withValues(alpha: 0.6),
    );

    // User (green/operational) — above buffer
    final userHeight = innerHeight * contextWindow.userLoad;
    final userRect = Rect.fromLTWH(
      innerLeft,
      innerBottom - systemHeight - bufferHeight - userHeight,
      innerWidth,
      userHeight,
    );
    canvas.drawRect(
      userRect,
      Paint()..color = const Color(0xFF44CC88).withValues(alpha: 0.6),
    );

    // Overload glow
    if (contextWindow.isOverloaded) {
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.3 * contextWindow.loadWobblePenalty)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);
      canvas.drawRRect(packRect, glowPaint);
    }
  }
}
```

**Step 2: Integrate into StickFigurePainter**

Modify `lib/painters/stick_figure_painter.dart`:
- Add import: `import '../models/context_window.dart';`
- Add import: `import 'backpack_painter.dart';`
- Add field: `final ContextWindow contextWindow;`
- Add `required this.contextWindow` to constructor
- Add context load to wobble calculation:
  ```dart
  final wobbleAmount = (1.0 - skillLevel) * 8.0 +
      (isWindy ? 4.0 : 0.0) +
      (isUnstable ? 5.0 : 0.0) +
      contextWindow.loadWobblePenalty * 6.0;
  ```
- Add hunch when heavy (modify hipCenter y):
  ```dart
  final hunchOffset = contextWindow.loadWobblePenalty * 8.0 * scale;
  ```
  Apply to neckBottom and shoulderPos y values (add hunchOffset to lower them)
- Call `BackpackPainter.paint(canvas, shoulderPos, scale, contextWindow)` after drawing the back arm

**Step 3: Verify compile**

Run: `flutter analyze`
Expected: No issues (game_canvas.dart will have a compile error because it doesn't pass contextWindow yet — that's expected, we fix it in Task 5)

**Step 4: Commit**

```bash
git add lib/painters/backpack_painter.dart lib/painters/stick_figure_painter.dart
git commit -m "feat: add backpack painter and integrate context load into stick figure"
```

---

### Task 4: Context Window Bar Widget

**Files:**
- Create: `lib/widgets/context_bar.dart`

**Step 1: Create the context window bar widget**

```dart
// lib/widgets/context_bar.dart
import 'package:flutter/material.dart';
import '../models/context_window.dart';

class ContextBar extends StatelessWidget {
  final ContextWindow contextWindow;

  const ContextBar({super.key, required this.contextWindow});

  @override
  Widget build(BuildContext context) {
    final total = contextWindow.totalLoad;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Context: ${(total * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: contextWindow.isOverloaded
                      ? Colors.red
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: contextWindow.isOverloaded
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: CustomPaint(
                    painter: _ContextBarPainter(contextWindow: contextWindow),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _legend(const Color(0xFF4488CC), 'System ${(contextWindow.systemLoad * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFCCA844), 'Buffer ${(contextWindow.bufferLoad * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _legend(const Color(0xFF44CC88), 'User ${(contextWindow.userLoad * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _ContextBarPainter extends CustomPainter {
  final ContextWindow contextWindow;

  _ContextBarPainter({required this.contextWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final radius = Radius.circular(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      bgPaint,
    );

    double x = 0;

    // System (blue)
    final systemWidth = size.width * contextWindow.systemLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, systemWidth, size.height),
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.7),
    );
    x += systemWidth;

    // Buffer (amber)
    final bufferWidth = size.width * contextWindow.bufferLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, bufferWidth, size.height),
      Paint()..color = const Color(0xFFCCA844).withValues(alpha: 0.7),
    );
    x += bufferWidth;

    // User (green)
    final userWidth = size.width * contextWindow.userLoad;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, userWidth, size.height),
      Paint()..color = const Color(0xFF44CC88).withValues(alpha: 0.7),
    );

    // Overload threshold line at 70%
    final thresholdX = size.width * 0.70;
    canvas.drawLine(
      Offset(thresholdX, 0),
      Offset(thresholdX, size.height),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ContextBarPainter oldDelegate) {
    return oldDelegate.contextWindow.totalLoad != contextWindow.totalLoad;
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/context_bar.dart
git commit -m "feat: add context window bar widget with compartment visualization"
```

---

### Task 5: Planning Controls Widget + Wire Into Game Canvas

**Files:**
- Create: `lib/widgets/planning_controls.dart`
- Modify: `lib/widgets/game_canvas.dart`
- Modify: `lib/widgets/control_panel.dart`

**Step 1: Create planning controls widget**

```dart
// lib/widgets/planning_controls.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/planning.dart';

class PlanningControls extends StatelessWidget {
  final GameState state;
  final VoidCallback? onActionStarted;

  const PlanningControls({
    super.key,
    required this.state,
    this.onActionStarted,
  });

  @override
  Widget build(BuildContext context) {
    final planning = state.planning;
    final isPlanning = planning.isPlanning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Plan mode toggle
        ElevatedButton.icon(
          onPressed: () => state.togglePlanning(),
          icon: Icon(isPlanning ? Icons.pause : Icons.psychology),
          label: Text(isPlanning ? 'EXIT PLAN (P)' : 'PLAN (P)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPlanning
                ? Colors.amber.withValues(alpha: 0.8)
                : Colors.amber.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        // Aim
        _actionButton(
          icon: Icons.gps_fixed,
          label: 'Aim (A)',
          action: PlanningAction.aim,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.cyan,
          costLabel: '-${(planning.contextCostFor(PlanningAction.aim) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: '+${(planning.benefitFor(PlanningAction.aim) * 100).toStringAsFixed(0)}% focus',
        ),
        const SizedBox(width: 8),
        // Scout
        _actionButton(
          icon: Icons.visibility,
          label: 'Scout (S)',
          action: PlanningAction.scout,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.teal,
          costLabel: '-${(planning.contextCostFor(PlanningAction.scout) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: 'Negate 1 env',
        ),
        const SizedBox(width: 8),
        // Load
        _actionButton(
          icon: Icons.autorenew,
          label: 'Load (L)',
          action: PlanningAction.load,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.lime,
          costLabel: '-${(planning.contextCostFor(PlanningAction.load) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: '+${(planning.benefitFor(PlanningAction.load) * 100).toStringAsFixed(0)}% acc',
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required PlanningAction action,
    required bool enabled,
    required Color color,
    required String costLabel,
    required String benefitLabel,
  }) {
    return Tooltip(
      message: '$costLabel / $benefitLabel',
      child: ElevatedButton.icon(
        onPressed: enabled
            ? () {
                state.executePlanningAction(action);
                onActionStarted?.call();
              }
            : null,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
```

**Step 2: Update game_canvas.dart**

Key changes:
- Import `context_bar.dart`, `planning_controls.dart`, `../models/planning.dart`
- Pass `contextWindow` to `StickFigurePainter`
- Add `ContextBar` widget between stats bar and canvas
- Add `PlanningControls` widget between canvas and fire buttons
- Disable fire buttons when `!state.planning.canFire`
- Add keyboard shortcuts: P (toggle plan), A (aim), S (scout), L (load)
- Update fire to check `state.planning.canFire`
- Add Scene 4 button text to keyboard hints

**Step 3: Update control_panel.dart**

- Add Scene 4 "The Planner" button to scene buttons list

**Step 4: Run tests and verify build**

Run: `flutter test && flutter build web`
Expected: All pass, builds

**Step 5: Commit**

```bash
git add lib/widgets/ lib/painters/stick_figure_painter.dart
git commit -m "feat: add planning controls, context bar, and wire into game canvas"
```

---

### Task 6: Polish & Scene 4

**Files:**
- Modify: `lib/widgets/game_canvas.dart` (keyboard hints text)
- Verify all scenes work correctly

**Step 1: Update keyboard hints**

Change hint text to:
```
Space: Fire | P: Plan | A/S/L: Aim/Scout/Load | 1-4: Scenes | 0: Free Play | C: Clear
```

**Step 2: Final build and test**

Run: `flutter test && flutter build web && flutter build macos`
Expected: All pass, both platforms build

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: polish planning UI and add Scene 4 (The Planner)"
```
