import 'dart:ui';

enum GunType {
  claudeOpus46,
  gpt54,
  claudeSonnet46,
  gemini25Pro,
  gpt41,
  claudeHaiku45,
}

class Gun {
  final GunType type;
  final String name;
  final String modelLabel;
  final double baseAccuracy; // 0.0 (worst) to 1.0 (best)
  final Color color;
  final double beamWidth;
  final double heatRate; // multiplier on heat generation per shot

  const Gun({
    required this.type,
    required this.name,
    required this.modelLabel,
    required this.baseAccuracy,
    required this.color,
    this.beamWidth = 2.0,
    this.heatRate = 1.0,
  });

  static const List<Gun> all = [
    Gun(
      type: GunType.claudeOpus46,
      name: 'Claude Opus 4.6',
      modelLabel: 'Opus',
      baseAccuracy: 0.55,
      color: Color(0xFFD4A574),
      beamWidth: 1.5,
      heatRate: 1.3,
    ),
    Gun(
      type: GunType.gpt54,
      name: 'GPT-5.4',
      modelLabel: 'GPT-5.4',
      baseAccuracy: 0.52,
      color: Color(0xFF74D4A5),
      beamWidth: 1.8,
      heatRate: 1.2,
    ),
    Gun(
      type: GunType.claudeSonnet46,
      name: 'Claude Sonnet 4.6',
      modelLabel: 'Sonnet',
      baseAccuracy: 0.48,
      color: Color(0xFFA574D4),
      beamWidth: 2.0,
      heatRate: 1.0,
    ),
    Gun(
      type: GunType.gemini25Pro,
      name: 'Gemini 2.5 Pro',
      modelLabel: 'Gemini',
      baseAccuracy: 0.45,
      color: Color(0xFF4A90D9),
      beamWidth: 2.2,
      heatRate: 1.0,
    ),
    Gun(
      type: GunType.gpt41,
      name: 'GPT-4.1',
      modelLabel: 'GPT-4.1',
      baseAccuracy: 0.42,
      color: Color(0xFF5CB85C),
      beamWidth: 2.5,
      heatRate: 0.8,
    ),
    Gun(
      type: GunType.claudeHaiku45,
      name: 'Claude Haiku 4.5',
      modelLabel: 'Haiku',
      baseAccuracy: 0.35,
      color: Color(0xFFFF6B9D),
      beamWidth: 3.5,
      heatRate: 0.6,
    ),
  ];
}
