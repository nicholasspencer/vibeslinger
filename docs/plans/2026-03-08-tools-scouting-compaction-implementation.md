# Tools, Scouting Modes & Compaction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace "Load" with a tools menu that modifies system context, split scouting into direct vs subagent modes, add compaction buffer visualization, and add a compact action that compresses user space with a lossy animation.

**Architecture:** Extend ContextWindow to support mutable system load (tools), compaction buffer, and compaction state. Refactor PlanningState to remove Load action and add subagent scout. Update context bar painter to render compaction buffer right-aligned. Add tools menu popup and compact button to UI.

**Tech Stack:** Flutter, CustomPainter, ChangeNotifier, AnimationController

---

### Task 1: Tools Model

**Files:**
- Create: `lib/models/tool.dart`
- Modify: `lib/models/context_window.dart`
- Create: `test/models/tool_test.dart`

**Step 1: Create the Tool model**

```dart
// lib/models/tool.dart

enum ToolType {
  webSearch,
  codeAnalysis,
  fileReader,
}

class Tool {
  final ToolType type;
  final String name;
  final double systemCost; // added to system load when equipped
  final String passiveBenefit; // human-readable description

  // Numeric benefits for gameplay
  final double scoutBonus;    // multiplier for scout effectiveness
  final double accuracyBonus; // added to base accuracy
  final double spreadBonus;   // reduction in spread (0-1)

  const Tool({
    required this.type,
    required this.name,
    required this.systemCost,
    required this.passiveBenefit,
    this.scoutBonus = 0.0,
    this.accuracyBonus = 0.0,
    this.spreadBonus = 0.0,
  });

  static const List<Tool> all = [
    Tool(
      type: ToolType.webSearch,
      name: 'Web Search',
      systemCost: 0.08,
      passiveBenefit: '+10% scout effectiveness',
      scoutBonus: 0.10,
    ),
    Tool(
      type: ToolType.codeAnalysis,
      name: 'Code Analysis',
      systemCost: 0.10,
      passiveBenefit: '+10% base accuracy',
      accuracyBonus: 0.10,
    ),
    Tool(
      type: ToolType.fileReader,
      name: 'File Reader',
      systemCost: 0.06,
      passiveBenefit: '-5% spread',
      spreadBonus: 0.05,
    ),
  ];
}
```

**Step 2: Update ContextWindow to support mutable system load and compaction**

Replace `lib/models/context_window.dart` entirely:

```dart
// lib/models/context_window.dart

class ContextWindow {
  static const double baseSystemLoad = 0.20;
  static const double compactionBufferSize = 0.165; // 16.5%

  final double bufferLoad; // safety buffer
  double _systemLoad;      // base + tools (mutable now)
  double _userLoad;
  bool _isCompacted = false; // true if user space has been compacted

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

  /// The compaction buffer starts at (1.0 - compactionBufferSize)
  double get compactionThreshold => 1.0 - compactionBufferSize;

  /// True when content encroaches into compaction buffer
  bool get isInCompactionZone => totalLoad > compactionThreshold;

  /// Original overload threshold
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

  /// Add tool to system load
  void addToolLoad(double cost) {
    _systemLoad = (_systemLoad + cost).clamp(0.0, 1.0);
  }

  /// Remove tool from system load
  void removeToolLoad(double cost) {
    _systemLoad = (_systemLoad - cost).clamp(baseSystemLoad, 1.0);
  }

  /// Compact user space: compress by ~60%, mark as compacted (lossy)
  void compact() {
    _userLoad = _userLoad * 0.4; // keep 40%, lose 60%
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
```

**Step 3: Write tests**

```dart
// test/models/tool_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/tool.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
  group('Tool', () {
    test('three tools defined', () {
      expect(Tool.all.length, 3);
    });

    test('web search costs 8% system', () {
      expect(Tool.all[0].systemCost, 0.08);
    });
  });

  group('ContextWindow with tools', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('addToolLoad increases system load', () {
      ctx.addToolLoad(0.08);
      expect(ctx.systemLoad, closeTo(0.28, 0.01));
    });

    test('removeToolLoad decreases system load', () {
      ctx.addToolLoad(0.10);
      ctx.removeToolLoad(0.10);
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
    });

    test('removeToolLoad cannot go below base', () {
      ctx.removeToolLoad(0.50);
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
    });

    test('compaction buffer threshold is 83.5%', () {
      expect(ctx.compactionThreshold, closeTo(0.835, 0.01));
    });

    test('isInCompactionZone when load exceeds threshold', () {
      ctx.consumeContext(0.50); // system 0.20 + buffer 0.15 + user 0.50 = 0.85
      expect(ctx.isInCompactionZone, true);
    });

    test('compact reduces user space by 60%', () {
      ctx.consumeContext(0.40);
      ctx.compact();
      expect(ctx.userLoad, closeTo(0.16, 0.01));
      expect(ctx.isCompacted, true);
    });

    test('reset clears compacted state and tool loads', () {
      ctx.addToolLoad(0.10);
      ctx.consumeContext(0.20);
      ctx.compact();
      ctx.reset();
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
      expect(ctx.userLoad, 0.0);
      expect(ctx.isCompacted, false);
    });
  });
}
```

**Step 4: Run tests**

Run: `flutter test test/models/tool_test.dart`
Expected: All tests pass

**Step 5: Update existing context_window_test.dart**

The existing tests reference `systemLoad` as a final field. Since systemLoad is now mutable via `addToolLoad`/`removeToolLoad`, the tests for default values should still pass. Run existing tests to verify.

Run: `flutter test test/models/context_window_test.dart`
Expected: All pass (default systemLoad is still 0.20)

**Step 6: Commit**

```bash
git add lib/models/tool.dart lib/models/context_window.dart test/models/tool_test.dart
git commit -m "feat: add tool model and extend context window with tools, compaction buffer, and compact action"
```

---

### Task 2: Refactor Planning — Remove Load, Add Subagent Scout

**Files:**
- Modify: `lib/models/planning.dart`
- Modify: `lib/models/game_state.dart`
- Modify: `test/models/planning_test.dart`

**Step 1: Update PlanningAction enum and PlanningState**

Replace `lib/models/planning.dart` entirely:

```dart
// lib/models/planning.dart

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

  /// Scale bonuses by a factor (used during compaction)
  void scale(double factor) {
    spreadReduction = (spreadReduction * factor).clamp(0.0, 0.90);
    // scoutNegations are integer, round down
    scoutNegations = (scoutNegations * factor).floor();
  }
}

class PlanningState {
  bool _isPlanning = false;
  bool _isExecutingAction = false; // true while subagent scout animates
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
    // Subagent scout is handled externally (delayed), but still check isPlanning
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
        // Benefit applied after delay — caller handles the delay,
        // then calls applySubagentScoutResult()
        break;
    }
    return true;
  }

  /// Called after subagent scout delay completes
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
```

**Step 2: Update GameState**

Modify `lib/models/game_state.dart`:

1. Add `import 'tool.dart';`
2. Add tools tracking to GameState:
```dart
final Set<ToolType> _loadedTools = {};
Set<ToolType> get loadedTools => Set.unmodifiable(_loadedTools);
```
3. Add tool management methods:
```dart
bool loadTool(ToolType type) {
  if (_loadedTools.contains(type)) return false;
  final tool = Tool.all.firstWhere((t) => t.type == type);
  _contextWindow.addToolLoad(tool.systemCost);
  _loadedTools.add(type);
  notifyListeners();
  return true;
}

bool unloadTool(ToolType type) {
  if (!_loadedTools.contains(type)) return false;
  final tool = Tool.all.firstWhere((t) => t.type == type);
  _contextWindow.removeToolLoad(tool.systemCost);
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
```
4. Update `effectiveAccuracy` — replace `_planning.bonus.accuracyBoost` with `_toolAccuracyBonus`:
```dart
double get effectiveAccuracy {
  final base = _selectedGun.baseAccuracy + _toolAccuracyBonus;
  final skill = 0.5 + (_skillLevel * 0.5);
  final heat = 1.0 - (_heatLevel * 0.6);
  final env = _effectiveEnvironmentPenalty;
  final loadPenalty = 1.0 - (_contextWindow.loadWobblePenalty * 0.4);
  return (base * skill * heat * env * loadPenalty).clamp(0.05, 1.0);
}
```
5. Update `fire()` — include tool spread bonus:
```dart
final spreadMultiplier = 1.0 - _planning.bonus.spreadReduction - _toolSpreadBonus;
```
6. Add compact method:
```dart
void compact() {
  _contextWindow.compact();
  // Scale planning bonuses proportionally (lossy)
  _planning.bonus.scale(0.4);
  notifyListeners();
}
```
7. Update `executePlanningAction` to handle the new action types:
```dart
bool executePlanningAction(PlanningAction action) {
  if (_contextWindow.isNearFull) return false;
  final cost = _planning.contextCostFor(action);
  if (!_contextWindow.consumeContext(cost)) return false;
  final result = _planning.applyAction(action);
  if (result) notifyListeners();
  return result;
}

/// Called by UI after subagent scout delay completes
void completeSubagentScout() {
  _planning.applySubagentScoutResult();
  _planning.setExecutingAction(false);
  notifyListeners();
}
```
8. Update `clearShots()` to also clear tools:
```dart
void clearShots() {
  _shots.clear();
  _heatLevel = 0.0;
  _loadedTools.clear();
  _contextWindow.reset();
  _planning.reset();
  notifyListeners();
}
```

**Step 3: Update planning tests**

Replace `test/models/planning_test.dart`:

```dart
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
      expect(planning.bonus.spreadReduction, closeTo(0.45, 0.01));
    });

    test('direct scout increments negation count', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.directScout);
      expect(planning.bonus.scoutNegations, 1);
    });

    test('subagent scout does not immediately apply', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.subagentScout);
      expect(planning.bonus.scoutNegations, 0);
    });

    test('applySubagentScoutResult increments negation', () {
      planning.togglePlanning();
      planning.applySubagentScoutResult();
      expect(planning.bonus.scoutNegations, 1);
    });

    test('cannot apply action when not planning', () {
      final result = planning.applyAction(PlanningAction.aim);
      expect(result, false);
    });

    test('consumeBonuses resets', () {
      planning.togglePlanning();
      planning.applyAction(PlanningAction.aim);
      planning.consumeBonuses();
      expect(planning.bonus.hasBonus, false);
    });

    test('context costs differ for scout types', () {
      expect(planning.contextCostFor(PlanningAction.directScout), 0.08);
      expect(planning.contextCostFor(PlanningAction.subagentScout), 0.03);
    });

    test('bonus scale reduces proportionally', () {
      planning.bonus.spreadReduction = 0.50;
      planning.bonus.scoutNegations = 3;
      planning.bonus.scale(0.4);
      expect(planning.bonus.spreadReduction, closeTo(0.20, 0.01));
      expect(planning.bonus.scoutNegations, 1); // floor(3 * 0.4)
    });
  });
}
```

**Step 4: Run all tests**

Run: `flutter test`
Expected: All pass (some existing game_state_tests may need adjustment if they reference old PlanningAction.load or accuracyBoost)

Note: The existing `game_state_test.dart` doesn't directly test planning, so it should be fine. But verify.

**Step 5: Commit**

```bash
git add lib/models/planning.dart lib/models/game_state.dart lib/models/tool.dart test/models/planning_test.dart
git commit -m "feat: refactor planning to remove Load, add direct/subagent scout, add tools and compact"
```

---

### Task 3: Update Context Bar with Compaction Buffer

**Files:**
- Modify: `lib/widgets/context_bar.dart`

**Step 1: Update the context bar painter and widget**

Replace `lib/widgets/context_bar.dart` entirely:

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
    final inDanger = contextWindow.isInCompactionZone;
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
                  color: inDanger ? Colors.red : (contextWindow.isOverloaded ? Colors.orange : Colors.white70),
                  fontSize: 12,
                  fontWeight: inDanger ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (contextWindow.isCompacted) ...[
                const SizedBox(width: 6),
                const Text('(compacted)', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
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
              _legend(
                contextWindow.isCompacted ? const Color(0xFF2A8855) : const Color(0xFF44CC88),
                'User ${(contextWindow.userLoad * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 12),
              _legend(const Color(0xFF555555), 'Compact ${(ContextWindow.compactionBufferSize * 100).toStringAsFixed(1)}%'),
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
    final radius = Radius.circular(3);

    // Background
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
      bgPaint,
    );

    // Compaction buffer zone (right-aligned)
    final compactWidth = size.width * ContextWindow.compactionBufferSize;
    final compactLeft = size.width - compactWidth;
    canvas.drawRect(
      Rect.fromLTWH(compactLeft, 0, compactWidth, size.height),
      Paint()..color = const Color(0xFF555555).withValues(alpha: 0.4),
    );
    // Hatching pattern for compact buffer
    final hatchPaint = Paint()
      ..color = const Color(0xFF666666).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (double hx = compactLeft; hx < size.width; hx += 4) {
      canvas.drawLine(
        Offset(hx, 0),
        Offset(hx + size.height, size.height),
        hatchPaint,
      );
    }

    // Content sections (left-to-right)
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

    // User (green — desaturated if compacted)
    final userWidth = size.width * contextWindow.userLoad;
    final userColor = contextWindow.isCompacted
        ? const Color(0xFF2A8855).withValues(alpha: 0.7)
        : const Color(0xFF44CC88).withValues(alpha: 0.7);
    canvas.drawRect(
      Rect.fromLTWH(x, 0, userWidth, size.height),
      Paint()..color = userColor,
    );

    // Red border when in compaction zone
    if (contextWindow.isInCompactionZone) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
        Paint()
          ..color = Colors.red.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      // Normal border
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContextBarPainter oldDelegate) {
    return oldDelegate.contextWindow.totalLoad != contextWindow.totalLoad ||
        oldDelegate.contextWindow.isCompacted != contextWindow.isCompacted ||
        oldDelegate.contextWindow.systemLoad != contextWindow.systemLoad;
  }
}
```

**Step 2: Verify compile**

Run: `flutter analyze lib/widgets/context_bar.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/widgets/context_bar.dart
git commit -m "feat: update context bar with compaction buffer zone and lossy compaction visual"
```

---

### Task 4: Update Planning Controls — Tools Menu, Scout Split, Compact Button

**Files:**
- Modify: `lib/widgets/planning_controls.dart`
- Modify: `lib/widgets/game_canvas.dart`

**Step 1: Rewrite planning controls**

Replace `lib/widgets/planning_controls.dart` entirely:

```dart
// lib/widgets/planning_controls.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/planning.dart';
import '../models/tool.dart';

class PlanningControls extends StatelessWidget {
  final GameState state;
  final VoidCallback? onSubagentScoutStarted;

  const PlanningControls({
    super.key,
    required this.state,
    this.onSubagentScoutStarted,
  });

  @override
  Widget build(BuildContext context) {
    final planning = state.planning;
    final isPlanning = planning.isPlanning;
    final isExecuting = planning.isExecutingAction;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
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
        // Aim
        _planButton(
          icon: Icons.gps_fixed,
          label: 'Aim (A)',
          enabled: isPlanning && !isExecuting && !state.contextWindow.isNearFull,
          color: Colors.cyan,
          tooltip: '-5% ctx / +${(planning.bonus.spreadReduction < 0.90 ? 30 : 0)}% focus',
          onPressed: () => state.executePlanningAction(PlanningAction.aim),
        ),
        // Direct Scout
        _planButton(
          icon: Icons.visibility,
          label: 'Scout (S)',
          enabled: isPlanning && !isExecuting && !state.contextWindow.isNearFull,
          color: Colors.teal,
          tooltip: '-8% ctx / Negate 1 env (instant)',
          onPressed: () => state.executePlanningAction(PlanningAction.directScout),
        ),
        // Subagent Scout
        _planButton(
          icon: Icons.smart_toy,
          label: 'Subagent (D)',
          enabled: isPlanning && !isExecuting && !state.contextWindow.isNearFull,
          color: Colors.tealAccent,
          tooltip: '-3% ctx / Negate 1 env (~3s delay)',
          onPressed: () {
            final success = state.executePlanningAction(PlanningAction.subagentScout);
            if (success) {
              state.planning.setExecutingAction(true);
              state.notifyListeners();
              onSubagentScoutStarted?.call();
            }
          },
        ),
        // Tools (Load)
        _ToolsMenuButton(state: state, enabled: isPlanning && !isExecuting),
        // Compact (always available)
        _planButton(
          icon: Icons.compress,
          label: 'Compact (X)',
          enabled: state.contextWindow.userLoad > 0,
          color: Colors.deepOrange,
          tooltip: 'Compress user space ~60% (lossy)',
          onPressed: () => state.compact(),
        ),
      ],
    );
  }

  Widget _planButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
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

class _ToolsMenuButton extends StatelessWidget {
  final GameState state;
  final bool enabled;

  const _ToolsMenuButton({required this.state, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final loadedCount = state.loadedTools.length;
    return PopupMenuButton<ToolType>(
      enabled: enabled,
      tooltip: 'Load/unload tools (L)',
      offset: const Offset(0, -200),
      color: const Color(0xFF2A2A4E),
      onSelected: (type) {
        if (state.loadedTools.contains(type)) {
          state.unloadTool(type);
        } else {
          state.loadTool(type);
        }
      },
      itemBuilder: (context) => Tool.all.map((tool) {
        final isLoaded = state.loadedTools.contains(tool.type);
        return PopupMenuItem(
          value: tool.type,
          child: Row(
            children: [
              Icon(
                isLoaded ? Icons.check_box : Icons.check_box_outline_blank,
                color: isLoaded ? Colors.lime : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tool.name, style: const TextStyle(color: Colors.white)),
                    Text(
                      '${(tool.systemCost * 100).toStringAsFixed(0)}% system • ${tool.passiveBenefit}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: ElevatedButton.icon(
        onPressed: enabled ? null : null, // PopupMenuButton handles tap
        icon: const Icon(Icons.build, size: 16),
        label: Text('Tools (L) ${loadedCount > 0 ? "[$loadedCount]" : ""}',
            style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.lime.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
```

**Step 2: Update game_canvas.dart**

Key changes to `lib/widgets/game_canvas.dart`:

1. Update keyboard handler — replace old L/S keys:
```dart
if (key == LogicalKeyboardKey.keyS) state.executePlanningAction(PlanningAction.directScout);
// Remove old keyL handler for planning action
// Add:
if (key == LogicalKeyboardKey.keyX) widget.state.compact();
if (key == LogicalKeyboardKey.keyD) {
  // Subagent scout with delay
  final success = widget.state.executePlanningAction(PlanningAction.subagentScout);
  if (success) {
    widget.state.planning.setExecutingAction(true);
    widget.state.notifyListeners();
    _startSubagentScoutTimer();
  }
}
```

2. Add subagent scout timer method:
```dart
void _startSubagentScoutTimer() {
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      widget.state.completeSubagentScout();
    }
  });
}
```

3. Update PlanningControls usage — pass `onSubagentScoutStarted`:
```dart
PlanningControls(
  state: widget.state,
  onSubagentScoutStarted: _startSubagentScoutTimer,
),
```

4. Also update `canFire` check — `canFire` now also checks `_isExecutingAction`, so fire buttons should use `widget.state.planning.canFire`.

5. Update keyboard hints:
```
'Space: Fire | P: Plan | A: Aim | S: Scout | D: Subagent | L: Tools | X: Compact | 1-4: Scenes | 0: Free Play | C: Clear'
```

**Step 3: Run tests and verify build**

Run: `flutter test && flutter analyze && flutter build web`
Expected: All pass, builds

**Step 4: Commit**

```bash
git add lib/widgets/planning_controls.dart lib/widgets/game_canvas.dart
git commit -m "feat: add tools menu, split scout into direct/subagent, add compact button"
```

---

### Task 5: Final Polish & Verification

**Files:**
- Possibly modify: any files needing minor fixes

**Step 1: Run full test suite and builds**

Run: `flutter test && flutter analyze && flutter build web && flutter build macos`
Expected: All pass

**Step 2: Verify all features**

By reading code, confirm:
- Tools menu opens from L button with 3 tools
- Tools increase system load, can be unloaded
- Direct scout (S) is instant, costs 8% user
- Subagent scout (D) has 3s delay, costs 3% user
- Compact (X) compresses user space by 60%, desaturates green
- Compaction buffer visible right-aligned in context bar
- Context bar turns red when load enters compaction zone
- Keyboard shortcuts all work

**Step 3: Commit any fixes**

```bash
git add -A && git commit -m "feat: polish tools, scouting, and compaction features"
```
