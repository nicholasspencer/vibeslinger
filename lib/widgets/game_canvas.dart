import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/planning.dart';
import '../painters/stick_figure_painter.dart';
import '../painters/target_painter.dart';
import 'context_bar.dart';
import 'heat_meter.dart';
import 'planning_controls.dart';

class GameCanvas extends StatefulWidget {
  final GameState state;

  const GameCanvas({super.key, required this.state});

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _laserController;
  late FocusNode _focusNode;
  Timer? _cooldownTimer;
  Timer? _rapidFireTimer;
  bool _isRapidFiring = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();

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
    _focusNode.dispose();
    _wobbleController.dispose();
    _laserController.dispose();
    _cooldownTimer?.cancel();
    _rapidFireTimer?.cancel();
    super.dispose();
  }

  void _fire() {
    if (!widget.state.planning.canFire) return;
    widget.state.fire();
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

  void _startSubagentScoutTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.state.completeSubagentScout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.state,
        _wobbleController,
      ]),
      builder: (context, _) {
        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.digit1) widget.state.loadScene(1);
              if (key == LogicalKeyboardKey.digit2) widget.state.loadScene(2);
              if (key == LogicalKeyboardKey.digit3) widget.state.loadScene(3);
              if (key == LogicalKeyboardKey.digit4) widget.state.loadScene(4);
              if (key == LogicalKeyboardKey.digit0) widget.state.loadScene(0);
              if (key == LogicalKeyboardKey.space) _fire();
              if (key == LogicalKeyboardKey.keyC) widget.state.clearShots();
              if (key == LogicalKeyboardKey.keyP) widget.state.togglePlanning();
              if (key == LogicalKeyboardKey.keyA) widget.state.executePlanningAction(PlanningAction.aim);
              if (key == LogicalKeyboardKey.keyS) widget.state.executePlanningAction(PlanningAction.directScout);
              if (key == LogicalKeyboardKey.keyD) {
                final success = widget.state.startSubagentScout();
                if (success) {
                  _startSubagentScoutTimer();
                }
              }
              if (key == LogicalKeyboardKey.keyX) widget.state.compact();
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
              ContextBar(contextWindow: widget.state.contextWindow),
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
                          contextWindow: widget.state.contextWindow,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: PlanningControls(
                  state: widget.state,
                  onSubagentScoutStarted: _startSubagentScoutTimer,
                ),
              ),
              // Fire buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.state.planning.canFire ? _fire : null,
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
                      onLongPressStart: widget.state.planning.canFire ? (_) => _startRapidFire() : null,
                      onLongPressEnd: widget.state.planning.canFire ? (_) => _stopRapidFire() : null,
                      child: ElevatedButton.icon(
                        onPressed: () {},
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
              // Keyboard shortcut hints
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Space: Fire | P: Plan | A: Aim | S: Scout | D: Subagent | L: Tools | X: Compact | 1-4: Scenes | 0: Free Play | C: Clear',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
