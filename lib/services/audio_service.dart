import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const _poolSize = 4;
  final List<AudioPlayer> _firePool = [];
  int _fireIndex = 0;

  late final AudioPlayer _bullseye;
  late final AudioPlayer _planEnter;
  late final AudioPlayer _planExit;
  late final AudioPlayer _aim;
  late final AudioPlayer _scout;
  late final AudioPlayer _scoutStart;
  late final AudioPlayer _scoutComplete;
  late final AudioPlayer _toolLoad;
  late final AudioPlayer _toolUnload;
  late final AudioPlayer _compact;
  late final AudioPlayer _gunSelect;
  late final AudioPlayer _clear;
  late final AudioPlayer _heatWarning;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setSource(AssetSource('audio/fire.wav'));
      _firePool.add(player);
    }

    _bullseye = await _preload('audio/bullseye.wav');
    _planEnter = await _preload('audio/plan_enter.wav');
    _planExit = await _preload('audio/plan_exit.wav');
    _aim = await _preload('audio/aim.wav');
    _scout = await _preload('audio/scout.wav');
    _scoutStart = await _preload('audio/scout_start.wav');
    _scoutComplete = await _preload('audio/scout_complete.wav');
    _toolLoad = await _preload('audio/tool_load.wav');
    _toolUnload = await _preload('audio/tool_unload.wav');
    _compact = await _preload('audio/compact.wav');
    _gunSelect = await _preload('audio/gun_select.wav');
    _clear = await _preload('audio/clear.wav');
    _heatWarning = await _preload('audio/heat_warning.wav');
  }

  Future<AudioPlayer> _preload(String path) async {
    final player = AudioPlayer();
    await player.setSource(AssetSource(path));
    return player;
  }

  void _play(AudioPlayer player) {
    player.stop();
    player.resume();
  }

  void playFire() {
    final player = _firePool[_fireIndex % _poolSize];
    _fireIndex++;
    _play(player);
  }

  void playBullseye() => _play(_bullseye);
  void playPlanToggle(bool entering) => _play(entering ? _planEnter : _planExit);
  void playAim() => _play(_aim);
  void playScout() => _play(_scout);
  void playScoutStart() => _play(_scoutStart);
  void playScoutComplete() => _play(_scoutComplete);
  void playToolLoad() => _play(_toolLoad);
  void playToolUnload() => _play(_toolUnload);
  void playCompact() => _play(_compact);
  void playGunSelect() => _play(_gunSelect);
  void playClear() => _play(_clear);
  void playHeatWarning() => _play(_heatWarning);
}
