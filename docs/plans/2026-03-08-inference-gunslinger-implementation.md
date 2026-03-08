# Inference Gunslinger Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an interactive Flutter web app visualizing AI inference concepts through a laser-shooting marksmanship metaphor.

**Architecture:** Single-screen Flutter web app using `CustomPainter` for all canvas rendering (stick figure, target, laser beams, shot impacts). State managed via `ChangeNotifier`. No game engine — just Flutter's animation and painting APIs.

**Tech Stack:** Flutter 3.38.8, Dart, CustomPainter, AnimationController

---

### Task 1: Scaffold Flutter Web Project

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `web/index.html`

**Step 1: Create Flutter project**

Run: `flutter create --project-name inference_gunslinger --platforms web .`
Expected: Flutter project scaffolded with web support

**Step 2: Verify it runs**

Run: `flutter build web`
Expected: Build completes, `build/web/index.html` exists

**Step 3: Clean up default code**

Replace `lib/main.dart` with minimal app shell:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const InferenceGunslingerApp());
}

class InferenceGunslingerApp extends StatelessWidget {
  const InferenceGunslingerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inference Gunslinger',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const GunslingerScreen(),
    );
  }
}

class GunslingerScreen extends StatelessWidget {
  const GunslingerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Inference Gunslinger')),
    );
  }
}
```

**Step 4: Commit**

```bash
git init && git add -A && git commit -m "feat: scaffold flutter web project"
```

---

### Task 2: Game State Model

**Files:**
- Create: `lib/models/game_state.dart`
- Create: `lib/models/gun.dart`
- Create: `test/models/game_state_test.dart`

**Step 1: Write the Gun model**

```dart
// lib/models/gun.dart
import 'dart:ui';

enum GunType {
  precisionRifle,
  pulsePistol,
  scatterBlaster,
}

class Gun {
  final GunType type;
  final String name;
  final String modelLabel;
  final double baseAccuracy; // 0.0 (worst) to 1.0 (best)
  final Color color;
  final double beamWidth;

  const Gun({
    required this.type,
    required this.name,
    required this.modelLabel,
    required this.baseAccuracy,
    required this.color,
    this.beamWidth = 2.0,
  });

  static const List<Gun> all = [
    Gun(
      type: GunType.precisionRifle,
      name: 'Precision Rifle',
      modelLabel: 'Claude Opus',
      baseAccuracy: 0.92,
      color: Color(0xFFD4A574),
      beamWidth: 1.5,
    ),
    Gun(
      type: GunType.pulsePistol,
      name: 'Pulse Pistol',
      modelLabel: 'GPT-4o',
      baseAccuracy: 0.80,
      color: Color(0xFF74D4A5),
      beamWidth: 2.5,
    ),
    Gun(
      type: GunType.scatterBlaster,
      name: 'Scatter Blaster',
      modelLabel: 'Llama 3',
      baseAccuracy: 0.60,
      color: Color(0xFFD474A5),
      beamWidth: 4.0,
    ),
  ];
}
```

**Step 2: Write the GameState model**

```dart
// lib/models/game_state.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'gun.dart';

class EnvironmentFactors {
  final bool windy;      // high temperature
  final bool lowLight;   // small context window
  final bool unstable;   // poor prompt structure

  const EnvironmentFactors({
    this.windy = false,
    this.lowLight = false,
    this.unstable = false,
  });

  double get penaltyMultiplier {
    double penalty = 1.0;
    if (windy) penalty *= 0.82;
    if (lowLight) penalty *= 0.88;
    if (unstable) penalty *= 0.78;
    return penalty;
  }

  EnvironmentFactors copyWith({bool? windy, bool? lowLight, bool? unstable}) {
    return EnvironmentFactors(
      windy: windy ?? this.windy,
      lowLight: lowLight ?? this.lowLight,
      unstable: unstable ?? this.unstable,
    );
  }
}

class ShotResult {
  final Offset offset; // offset from center of target, normalized -1 to 1
  final DateTime time;

  const ShotResult({required this.offset, required this.time});
}

class GameState extends ChangeNotifier {
  Gun _selectedGun = Gun.all[0];
  double _skillLevel = 0.5; // 0.0 novice, 1.0 expert
  EnvironmentFactors _environment = const EnvironmentFactors();
  final List<ShotResult> _shots = [];
  double _heatLevel = 0.0; // 0.0 cool, 1.0 overheated
  final Random _random = Random();

  Gun get selectedGun => _selectedGun;
  double get skillLevel => _skillLevel;
  EnvironmentFactors get environment => _environment;
  List<ShotResult> get shots => List.unmodifiable(_shots);
  double get heatLevel => _heatLevel;

  double get effectiveAccuracy {
    final base = _selectedGun.baseAccuracy;
    final skill = 0.5 + (_skillLevel * 0.5); // skill scales from 0.5x to 1.0x
    final heat = 1.0 - (_heatLevel * 0.6); // heat degrades up to 60%
    final env = _environment.penaltyMultiplier;
    return (base * skill * heat * env).clamp(0.05, 1.0);
  }

  void selectGun(Gun gun) {
    _selectedGun = gun;
    notifyListeners();
  }

  void setSkillLevel(double level) {
    _skillLevel = level.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEnvironment(EnvironmentFactors env) {
    _environment = env;
    notifyListeners();
  }

  ShotResult fire() {
    final accuracy = effectiveAccuracy;
    final spread = (1.0 - accuracy) * 2.0;

    // Gaussian-ish distribution using Box-Muller
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
    final z1 = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);

    final offset = Offset(
      (z0 * spread * 0.3).clamp(-1.0, 1.0),
      (z1 * spread * 0.3).clamp(-1.0, 1.0),
    );

    final shot = ShotResult(offset: offset, time: DateTime.now());
    _shots.add(shot);

    // Increase heat
    _heatLevel = (_heatLevel + 0.12).clamp(0.0, 1.0);

    notifyListeners();
    return shot;
  }

  void coolDown(double amount) {
    _heatLevel = (_heatLevel - amount).clamp(0.0, 1.0);
    notifyListeners();
  }

  void clearShots() {
    _shots.clear();
    _heatLevel = 0.0;
    notifyListeners();
  }

  void loadScene(int sceneIndex) {
    clearShots();
    switch (sceneIndex) {
      case 1: // The Expert
        _selectedGun = Gun.all[0];
        _skillLevel = 1.0;
        _environment = const EnvironmentFactors();
        break;
      case 2: // The Novice
        _selectedGun = Gun.all[2];
        _skillLevel = 0.1;
        _environment = const EnvironmentFactors(
          windy: true, lowLight: true, unstable: true,
        );
        break;
      case 3: // Burnout
        _selectedGun = Gun.all[0];
        _skillLevel = 1.0;
        _environment = const EnvironmentFactors();
        // Heat will build up as they rapid fire
        break;
      default: // Free Play
        _selectedGun = Gun.all[0];
        _skillLevel = 0.5;
        _environment = const EnvironmentFactors();
        break;
    }
    notifyListeners();
  }
}
```

**Step 3: Write tests for accuracy calculation**

```dart
// test/models/game_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/game_state.dart';
import 'package:inference_gunslinger/models/gun.dart';

void main() {
  group('GameState', () {
    late GameState state;

    setUp(() {
      state = GameState();
    });

    test('default effective accuracy uses first gun at mid skill', () {
      // Gun base: 0.92, skill: 0.5 -> multiplier 0.75, heat: 0, env: 1.0
      // 0.92 * 0.75 * 1.0 * 1.0 = 0.69
      expect(state.effectiveAccuracy, closeTo(0.69, 0.01));
    });

    test('expert with precision rifle has high accuracy', () {
      state.setSkillLevel(1.0);
      state.selectGun(Gun.all[0]);
      expect(state.effectiveAccuracy, closeTo(0.92, 0.01));
    });

    test('environment penalties stack', () {
      state.setSkillLevel(1.0);
      state.selectGun(Gun.all[0]);
      state.setEnvironment(const EnvironmentFactors(
        windy: true, lowLight: true, unstable: true,
      ));
      // 0.92 * 1.0 * 1.0 * (0.82 * 0.88 * 0.78) = 0.92 * 0.5627 ≈ 0.518
      expect(state.effectiveAccuracy, closeTo(0.518, 0.02));
    });

    test('firing increases heat', () {
      expect(state.heatLevel, 0.0);
      state.fire();
      expect(state.heatLevel, closeTo(0.12, 0.01));
    });

    test('heat degrades accuracy', () {
      state.setSkillLevel(1.0);
      final before = state.effectiveAccuracy;
      for (var i = 0; i < 5; i++) {
        state.fire();
      }
      expect(state.effectiveAccuracy, lessThan(before));
    });

    test('clearShots resets heat and shots', () {
      state.fire();
      state.fire();
      state.clearShots();
      expect(state.shots, isEmpty);
      expect(state.heatLevel, 0.0);
    });

    test('loadScene 1 sets expert config', () {
      state.loadScene(1);
      expect(state.skillLevel, 1.0);
      expect(state.selectedGun.type, GunType.precisionRifle);
    });
  });
}
```

**Step 4: Run tests**

Run: `flutter test test/models/game_state_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/models/ test/models/ && git commit -m "feat: add game state model with gun, environment, and accuracy"
```

---

### Task 3: Target Painter

**Files:**
- Create: `lib/painters/target_painter.dart`

**Step 1: Implement the target painter**

```dart
// lib/painters/target_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class TargetPainter extends CustomPainter {
  final List<ShotResult> shots;
  final Color shotColor;

  TargetPainter({required this.shots, required this.shotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2 * 0.9;

    // Draw concentric rings
    const ringColors = [
      Color(0xFFFF4444), // bullseye
      Color(0xFFFF8844),
      Color(0xFFFFCC44),
      Color(0xFF88CC44),
      Color(0xFF4488CC),
    ];

    for (var i = ringColors.length - 1; i >= 0; i--) {
      final radius = maxRadius * ((i + 1) / ringColors.length);
      final paint = Paint()
        ..color = ringColors[i].withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);

      final strokePaint = Paint()
        ..color = ringColors[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, strokePaint);
    }

    // Draw crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );

    // Draw shots
    for (final shot in shots) {
      final shotPos = Offset(
        center.dx + shot.offset.dx * maxRadius,
        center.dy + shot.offset.dy * maxRadius,
      );

      // Glow
      final glowPaint = Paint()
        ..color = shotColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(shotPos, 5, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = shotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(shotPos, 3, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TargetPainter oldDelegate) {
    return oldDelegate.shots.length != shots.length ||
        oldDelegate.shotColor != shotColor;
  }
}
```

**Step 2: Commit**

```bash
git add lib/painters/ && git commit -m "feat: add target painter with concentric rings and shot rendering"
```

---

### Task 4: Stick Figure Painter

**Files:**
- Create: `lib/painters/stick_figure_painter.dart`

**Step 1: Implement the stick figure painter**

```dart
// lib/painters/stick_figure_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/gun.dart';

class StickFigurePainter extends CustomPainter {
  final double skillLevel; // 0.0 to 1.0
  final Gun gun;
  final bool isWindy;
  final bool isLowLight;
  final bool isUnstable;
  final double wobblePhase; // animated value for wobble

  StickFigurePainter({
    required this.skillLevel,
    required this.gun,
    this.isWindy = false,
    this.isLowLight = false,
    this.isUnstable = false,
    this.wobblePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.85;
    final scale = size.height / 200;

    // Calculate wobble based on skill and conditions
    final wobbleAmount = (1.0 - skillLevel) * 8.0 +
        (isWindy ? 4.0 : 0.0) +
        (isUnstable ? 5.0 : 0.0);
    final wobbleX = sin(wobblePhase * 3) * wobbleAmount * scale;
    final wobbleY = sin(wobblePhase * 2.3) * wobbleAmount * 0.3 * scale;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Wind lean
    final leanX = isWindy ? sin(wobblePhase) * 6 * scale : 0.0;

    // Head
    final headCenter = Offset(
      centerX + wobbleX + leanX,
      baseY - 160 * scale + wobbleY,
    );
    canvas.drawCircle(headCenter, 12 * scale, paint);

    // Squint eyes if low light
    if (isLowLight) {
      final eyePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round;
      // Squint lines
      canvas.drawLine(
        Offset(headCenter.dx - 5 * scale, headCenter.dy - 2 * scale),
        Offset(headCenter.dx - 1 * scale, headCenter.dy - 2 * scale),
        eyePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + 1 * scale, headCenter.dy - 2 * scale),
        Offset(headCenter.dx + 5 * scale, headCenter.dy - 2 * scale),
        eyePaint,
      );
    }

    // Neck to body
    final neckBottom = Offset(
      centerX + wobbleX * 0.8 + leanX * 0.8,
      baseY - 145 * scale + wobbleY * 0.8,
    );
    final hipCenter = Offset(
      centerX + wobbleX * 0.3 + leanX * 0.5,
      baseY - 80 * scale + wobbleY * 0.3,
    );
    canvas.drawLine(neckBottom, hipCenter, paint);

    // Legs
    final leftFoot = Offset(centerX - 20 * scale, baseY);
    final rightFoot = Offset(centerX + 20 * scale, baseY);
    // Unstable: wider stance
    final stanceOffset = isUnstable ? 10 * scale : 0.0;
    canvas.drawLine(
      hipCenter,
      Offset(leftFoot.dx - stanceOffset, leftFoot.dy),
      paint,
    );
    canvas.drawLine(
      hipCenter,
      Offset(rightFoot.dx + stanceOffset, rightFoot.dy),
      paint,
    );

    // Arms - one extended holding gun
    final shoulderPos = Offset(
      centerX + wobbleX * 0.7 + leanX * 0.7,
      baseY - 130 * scale + wobbleY * 0.7,
    );

    // Back arm (relaxed)
    final backHand = Offset(
      shoulderPos.dx - 25 * scale,
      shoulderPos.dy + 30 * scale,
    );
    canvas.drawLine(shoulderPos, backHand, paint);

    // Gun arm (extended right)
    final gunTip = Offset(
      shoulderPos.dx + 60 * scale + wobbleX * 0.5,
      shoulderPos.dy + wobbleY * 0.5,
    );
    canvas.drawLine(shoulderPos, gunTip, paint);

    // Draw gun
    final gunPaint = Paint()
      ..color = gun.color
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      gunTip,
      Offset(gunTip.dx + 20 * scale, gunTip.dy),
      gunPaint,
    );

    // Gun glow
    final glowPaint = Paint()
      ..color = gun.color.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
    canvas.drawCircle(
      Offset(gunTip.dx + 20 * scale, gunTip.dy),
      6 * scale,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StickFigurePainter oldDelegate) => true;
}
```

**Step 2: Commit**

```bash
git add lib/painters/ && git commit -m "feat: add stick figure painter with wobble, posture, and gun rendering"
```

---

### Task 5: Laser Beam Animation

**Files:**
- Create: `lib/painters/laser_painter.dart`

**Step 1: Implement the laser beam painter**

```dart
// lib/painters/laser_painter.dart
import 'package:flutter/material.dart';

class LaserPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double progress; // 0.0 to 1.0 animation progress
  final double beamWidth;

  LaserPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.progress,
    this.beamWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final currentEnd = Offset.lerp(start, end, progress)!;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1.0 - progress * 0.5))
      ..strokeWidth = beamWidth * 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(start, currentEnd, glowPaint);

    // Core beam
    final corePaint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress * 0.3)
      ..strokeWidth = beamWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, currentEnd, corePaint);

    // Bright center
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * (1.0 - progress * 0.5))
      ..strokeWidth = beamWidth * 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, currentEnd, centerPaint);
  }

  @override
  bool shouldRepaint(covariant LaserPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

**Step 2: Commit**

```bash
git add lib/painters/ && git commit -m "feat: add laser beam painter with glow animation"
```

---

### Task 6: Main Screen — Wire Everything Together

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/widgets/control_panel.dart`
- Create: `lib/widgets/game_canvas.dart`
- Create: `lib/widgets/heat_meter.dart`

**Step 1: Create the control panel widget**

```dart
// lib/widgets/control_panel.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/gun.dart';

class ControlPanel extends StatelessWidget {
  final GameState state;

  const ControlPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Gun selector
          _buildGunSelector(),
          // Skill slider
          _buildSkillSlider(),
          // Environment toggles
          ..._buildEnvironmentToggles(),
          // Scene buttons
          ..._buildSceneButtons(),
          // Clear button
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildGunSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Model: ', style: TextStyle(color: Colors.white70)),
        DropdownButton<GunType>(
          value: state.selectedGun.type,
          dropdownColor: const Color(0xFF2A2A4E),
          style: const TextStyle(color: Colors.white),
          items: Gun.all.map((gun) {
            return DropdownMenuItem(
              value: gun.type,
              child: Text(
                '${gun.name} (${gun.modelLabel})',
                style: TextStyle(color: gun.color),
              ),
            );
          }).toList(),
          onChanged: (type) {
            if (type != null) {
              state.selectGun(Gun.all.firstWhere((g) => g.type == type));
            }
          },
        ),
      ],
    );
  }

  Widget _buildSkillSlider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Skill: ', style: TextStyle(color: Colors.white70)),
        SizedBox(
          width: 150,
          child: Slider(
            value: state.skillLevel,
            onChanged: state.setSkillLevel,
            activeColor: Colors.white70,
          ),
        ),
        Text(
          state.skillLevel < 0.3
              ? 'Novice'
              : state.skillLevel < 0.7
                  ? 'Intermediate'
                  : 'Expert',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _buildEnvironmentToggles() {
    return [
      FilterChip(
        label: const Text('Windy (High Temp)'),
        selected: state.environment.windy,
        onSelected: (v) => state.setEnvironment(
          state.environment.copyWith(windy: v),
        ),
        selectedColor: Colors.orange.withValues(alpha: 0.3),
        checkmarkColor: Colors.orange,
        labelStyle: TextStyle(
          color: state.environment.windy ? Colors.orange : Colors.white54,
        ),
      ),
      FilterChip(
        label: const Text('Low Light (Small Context)'),
        selected: state.environment.lowLight,
        onSelected: (v) => state.setEnvironment(
          state.environment.copyWith(lowLight: v),
        ),
        selectedColor: Colors.purple.withValues(alpha: 0.3),
        checkmarkColor: Colors.purple,
        labelStyle: TextStyle(
          color: state.environment.lowLight ? Colors.purple : Colors.white54,
        ),
      ),
      FilterChip(
        label: const Text('Unstable (Bad Prompts)'),
        selected: state.environment.unstable,
        onSelected: (v) => state.setEnvironment(
          state.environment.copyWith(unstable: v),
        ),
        selectedColor: Colors.red.withValues(alpha: 0.3),
        checkmarkColor: Colors.red,
        labelStyle: TextStyle(
          color: state.environment.unstable ? Colors.red : Colors.white54,
        ),
      ),
    ];
  }

  List<Widget> _buildSceneButtons() {
    return [
      const SizedBox(width: 16),
      const Text('Scenes: ', style: TextStyle(color: Colors.white70)),
      TextButton(
        onPressed: () => state.loadScene(1),
        child: const Text('1: Expert', style: TextStyle(color: Colors.white54)),
      ),
      TextButton(
        onPressed: () => state.loadScene(2),
        child: const Text('2: Novice', style: TextStyle(color: Colors.white54)),
      ),
      TextButton(
        onPressed: () => state.loadScene(3),
        child: const Text('3: Burnout', style: TextStyle(color: Colors.white54)),
      ),
      TextButton(
        onPressed: () => state.loadScene(0),
        child: const Text('0: Free Play', style: TextStyle(color: Colors.white54)),
      ),
    ];
  }

  Widget _buildClearButton() {
    return IconButton(
      onPressed: state.clearShots,
      icon: const Icon(Icons.refresh, color: Colors.white54),
      tooltip: 'Clear shots',
    );
  }
}
```

**Step 2: Create the heat meter widget**

```dart
// lib/widgets/heat_meter.dart
import 'package:flutter/material.dart';

class HeatMeter extends StatelessWidget {
  final double heatLevel;

  const HeatMeter({super.key, required this.heatLevel});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.green, Colors.red, heatLevel)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('HEAT', style: TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        SizedBox(
          width: 20,
          height: 100,
          child: CustomPaint(
            painter: _HeatMeterPainter(heatLevel: heatLevel, color: color),
          ),
        ),
      ],
    );
  }
}

class _HeatMeterPainter extends CustomPainter {
  final double heatLevel;
  final Color color;

  _HeatMeterPainter({required this.heatLevel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Fill
    final fillHeight = size.height * heatLevel;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Glow when hot
    if (heatLevel > 0.6) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
          const Radius.circular(4),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatMeterPainter oldDelegate) {
    return oldDelegate.heatLevel != heatLevel;
  }
}
```

**Step 3: Create the game canvas widget**

```dart
// lib/widgets/game_canvas.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../painters/stick_figure_painter.dart';
import '../painters/target_painter.dart';
import '../painters/laser_painter.dart';
import 'heat_meter.dart';

class GameCanvas extends StatefulWidget {
  final GameState state;

  const GameCanvas({super.key, required this.state});

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _laserController;
  Timer? _cooldownTimer;
  Timer? _rapidFireTimer;
  bool _isRapidFiring = false;

  // Laser animation state
  Offset? _laserStart;
  Offset? _laserEnd;

  @override
  void initState() {
    super.initState();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Passive cooldown
    _cooldownTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (widget.state.heatLevel > 0 && !_isRapidFiring) {
          widget.state.coolDown(0.02);
        }
      },
    );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _laserController.dispose();
    _cooldownTimer?.cancel();
    _rapidFireTimer?.cancel();
    super.dispose();
  }

  void _fire() {
    final shot = widget.state.fire();

    setState(() {
      // Calculate screen positions for laser
      // These are approximate - the laser goes from right side of figure to target area
      _laserStart = null; // Will be calculated in build from layout
      _laserEnd = null;
    });

    _laserController.forward(from: 0.0);
  }

  void _startRapidFire() {
    _isRapidFiring = true;
    _fire();
    _rapidFireTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _fire(),
    );
  }

  void _stopRapidFire() {
    _isRapidFiring = false;
    _rapidFireTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.state,
        _wobbleController,
        _laserController,
      ]),
      builder: (context, _) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              // Number keys for scenes
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.digit1) widget.state.loadScene(1);
              if (key == LogicalKeyboardKey.digit2) widget.state.loadScene(2);
              if (key == LogicalKeyboardKey.digit3) widget.state.loadScene(3);
              if (key == LogicalKeyboardKey.digit0) widget.state.loadScene(0);
              if (key == LogicalKeyboardKey.space) _fire();
              if (key == LogicalKeyboardKey.keyC) widget.state.clearShots();
            }
          },
          child: Column(
            children: [
              // Stats bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Accuracy: ${(widget.state.effectiveAccuracy * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Color.lerp(
                          Colors.red,
                          Colors.green,
                          widget.state.effectiveAccuracy,
                        ),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Text(
                      'Shots: ${widget.state.shots.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
              // Main canvas area
              Expanded(
                child: Row(
                  children: [
                    // Stick figure area
                    Expanded(
                      flex: 3,
                      child: CustomPaint(
                        painter: StickFigurePainter(
                          skillLevel: widget.state.skillLevel,
                          gun: widget.state.selectedGun,
                          isWindy: widget.state.environment.windy,
                          isLowLight: widget.state.environment.lowLight,
                          isUnstable: widget.state.environment.unstable,
                          wobblePhase: _wobbleController.value * 6.28,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    // Heat meter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: HeatMeter(heatLevel: widget.state.heatLevel),
                    ),
                    // Target area
                    Expanded(
                      flex: 3,
                      child: CustomPaint(
                        painter: TargetPainter(
                          shots: widget.state.shots,
                          shotColor: widget.state.selectedGun.color,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
              // Fire buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _fire,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('FIRE (Space)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.state.selectedGun.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onLongPressStart: (_) => _startRapidFire(),
                      onLongPressEnd: (_) => _stopRapidFire(),
                      child: ElevatedButton.icon(
                        onPressed: () {}, // Single tap does nothing, hold to rapid fire
                        icon: const Icon(Icons.local_fire_department),
                        label: const Text('RAPID FIRE (Hold)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Step 4: Update main.dart to wire it all together**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'widgets/control_panel.dart';
import 'widgets/game_canvas.dart';

void main() {
  runApp(const InferenceGunslingerApp());
}

class InferenceGunslingerApp extends StatelessWidget {
  const InferenceGunslingerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inference Gunslinger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const GunslingerScreen(),
    );
  }
}

class GunslingerScreen extends StatefulWidget {
  const GunslingerScreen({super.key});

  @override
  State<GunslingerScreen> createState() => _GunslingerScreenState();
}

class _GunslingerScreenState extends State<GunslingerScreen> {
  final GameState _gameState = GameState();

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _gameState,
        builder: (context, _) {
          return Column(
            children: [
              ControlPanel(state: _gameState),
              const Divider(color: Colors.white24),
              Expanded(child: GameCanvas(state: _gameState)),
            ],
          );
        },
      ),
    );
  }
}
```

**Step 5: Run tests and verify build**

Run: `flutter test && flutter build web`
Expected: Tests pass, web build succeeds

**Step 6: Commit**

```bash
git add lib/ && git commit -m "feat: wire up main screen with controls, canvas, and fire mechanics"
```

---

### Task 7: Polish and Final Touches

**Files:**
- Modify: `web/index.html` (title, favicon, loading style)
- Modify: `lib/main.dart` (keyboard shortcuts help text)

**Step 1: Update web/index.html title**

Change the `<title>` tag to "Inference Gunslinger" and set background color to match the app theme (`#1A1A2E`).

**Step 2: Add a keyboard shortcuts hint**

Add a small help text at the bottom of the screen: "Space: Fire | 1-3: Scenes | 0: Free Play | C: Clear"

**Step 3: Final build and test**

Run: `flutter build web`
Expected: Clean build

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: polish web shell and add keyboard shortcut hints"
```

---

### Task 8: Deploy

**Step 1: Verify build output**

Run: `ls build/web/`
Expected: index.html, main.dart.js, and assets

**Step 2: Deploy to personal GitHub Pages**

This depends on the user's site setup — may need to copy `build/web/` contents to the appropriate repo/directory.

**Step 3: Commit and tag**

```bash
git tag v1.0.0 && git push origin main --tags
```
