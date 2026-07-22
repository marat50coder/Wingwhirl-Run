import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Central sound manager. Uses a small pool of players for SFX so overlapping
/// effects don't cut each other off, plus a dedicated looping music player.
/// Every call is guarded so audio problems never crash gameplay.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final List<AudioPlayer> _sfxPool =
      List.generate(6, (i) => AudioPlayer(playerId: 'sfx_$i'));
  int _sfxIndex = 0;

  bool soundOn = true;
  bool musicOn = true;
  bool _initialized = false;
  String? _currentMusic;

  // Sound asset keys (paths relative to the assets root, as required by
  // audioplayers' AssetSource).
  static const String click = 'sounds/button_click_asset.mp3';
  static const String buy = 'sounds/buy_item_asset.mp3';
  static const String coin = 'sounds/collect_gold_coin_asset.mp3';
  static const String mission = 'sounds/complete_mission_asset.mp3';
  static const String floatLand = 'sounds/fishing_float_lands_on_calm_water_asset.mp3';
  static const String cast = 'sounds/fishing_rod_casting_asset.mp3';
  static const String negative = 'sounds/gentle_negative_feedback_asset.mp3';
  static const String legendary = 'sounds/legendary_fish_asset.mp3';
  static const String tension = 'sounds/looping_fishing_tension_asset.mp3';
  static const String eggOpen = 'sounds/magical_egg_opening_asset.mp3';
  static const String newChicken = 'sounds/new_chicken_asset.mp3';
  static const String levelUp = 'sounds/new_lvl_up_asset.mp3';
  static const String bite = 'sounds/playful_bite_notification_asset.mp3';
  static const String rareFish = 'sounds/rare_fish_asset.mp3';
  static const String catchOk = 'sounds/satisfying_successful_catch_asset.mp3';

  Future<void> init({required bool sound, required bool music}) async {
    soundOn = sound;
    musicOn = music;
    try {
      // Our sounds live at the bundle key "sounds/..." (declared in pubspec),
      // not the default "assets/..." prefix audioplayers assumes.
      AudioCache.instance.prefix = '';
      await _music.setReleaseMode(ReleaseMode.loop);
      for (final p in _sfxPool) {
        await p.setReleaseMode(ReleaseMode.stop);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('AudioService init failed: $e');
    }
  }

  Future<void> playSfx(String asset, {double volume = 1.0}) async {
    if (!_initialized || !soundOn) return;
    try {
      final player = _sfxPool[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (e) {
      debugPrint('playSfx error: $e');
    }
  }

  Future<void> playMusic(String asset, {double volume = 0.4}) async {
    if (!_initialized) return;
    _currentMusic = asset;
    if (!musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource(asset), volume: volume);
    } catch (e) {
      debugPrint('playMusic error: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> setMusicOn(bool on) async {
    musicOn = on;
    if (on) {
      if (_currentMusic != null) await playMusic(_currentMusic!);
    } else {
      await stopMusic();
    }
  }

  void setSoundOn(bool on) => soundOn = on;

  Future<void> dispose() async {
    try {
      await _music.dispose();
      for (final p in _sfxPool) {
        await p.dispose();
      }
    } catch (_) {}
  }
}
