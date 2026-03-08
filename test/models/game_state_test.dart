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
        windy: true,
        lowLight: true,
        unstable: true,
      ));
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
