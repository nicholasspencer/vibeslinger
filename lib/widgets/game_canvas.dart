import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/planning.dart';
import '../painters/stick_figure_painter.dart';
import '../painters/target_painter.dart';
import 'context_bar.dart';
import 'heat_meter.dart';

class FiringRange extends StatefulWidget {
  final GameState state;

  const FiringRange({super.key, required this.state});

  @override
  State<FiringRange> createState() => FiringRangeState();
}

class FiringRangeState extends State<FiringRange> with TickerProviderStateMixin {
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

  void fire() {
    if (!widget.state.planning.canFire) return;
    widget.state.fire();
    _laserController.forward(from: 0.0);
  }

  void startRapidFire() {
    _isRapidFiring = true;
    fire();
    _rapidFireTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => fire(),
    );
  }

  void stopRapidFire() {
    _isRapidFiring = false;
    _rapidFireTimer?.cancel();
  }

  void startSubagentScoutTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.state.completeSubagentScout();
      }
    });
  }

  void requestFiringFocus() {
    _focusNode.requestFocus();
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
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.space) {
              if (event is KeyRepeatEvent) {
                if (!_isRapidFiring) startRapidFire();
              } else if (event is KeyDownEvent) {
                fire();
              } else if (event is KeyUpEvent) {
                if (_isRapidFiring) stopRapidFire();
              }
            } else if (event is KeyDownEvent) {
              if (key == LogicalKeyboardKey.keyC) widget.state.clearShots();
              if (key == LogicalKeyboardKey.keyP) widget.state.togglePlanning();
              if (key == LogicalKeyboardKey.keyA) widget.state.executePlanningAction(PlanningAction.aim);
              if (key == LogicalKeyboardKey.keyS) widget.state.executePlanningAction(PlanningAction.directScout);
              if (key == LogicalKeyboardKey.keyD) {
                final success = widget.state.startSubagentScout();
                if (success) {
                  startSubagentScoutTimer();
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
            ],
          ),
        );
      },
    );
  }
}
