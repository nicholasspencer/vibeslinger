import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'gun.dart';

class EnvironmentFactors {
  final bool windy; // high temperature
  final bool lowLight; // small context window
  final bool unstable; // poor prompt structure

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
          windy: true,
          lowLight: true,
          unstable: true,
        );
        break;
      case 3: // Burnout
        _selectedGun = Gun.all[0];
        _skillLevel = 1.0;
        _environment = const EnvironmentFactors();
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
