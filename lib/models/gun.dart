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
