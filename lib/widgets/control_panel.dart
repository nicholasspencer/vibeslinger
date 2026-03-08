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
          _buildGunSelector(),
          _buildSkillSlider(),
          ..._buildEnvironmentToggles(),
          ..._buildSceneButtons(),
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
        onPressed: () => state.loadScene(4),
        child: const Text('4: Planner', style: TextStyle(color: Colors.white54)),
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
