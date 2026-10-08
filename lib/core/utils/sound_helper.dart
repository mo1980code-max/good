import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../constants/assets.dart';
import '../constants/game_constants.dart';

/// Tiny pool-based sound engine.
///
/// Design notes (fixes from the architecture review):
/// * A small pool of players is reused instead of creating one per sound —
///   tapping quickly no longer spawns dozens of players.
/// * Drag sounds are throttled ([GameConstants.dragSoundThrottleMs]) so
///   rubbing a hand plays a pleasant rhythm, not a machine-gun.
/// * Every call is failure-proof: a missing/undecodable asset stays silent,
///   it never breaks the game.
abstract final class SoundHelper {
  static const int _poolSize = 4;

  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static final Map<String, int> _lastPlayedMs = <String, int>{};
  static final AudioPlayer _musicPlayer = AudioPlayer();

  static int _nextPlayer = 0;
  static bool _ready = false;

  /// Kept in sync with [SettingsModel] by the app root.
  static bool soundOn = true;
  static bool musicOn = true;

  static Future<void> init() async {
    if (_ready) return;
    try {
      for (int i = 0; i < _poolSize; i++) {
        final AudioPlayer player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _pool.add(player);
      }
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(GameConstants.musicVolume);
      _ready = true;
    } catch (error) {
      // Sound is a nice-to-have. Never let it block the game.
      debugPrint('SoundHelper.init skipped: $error');
    }
  }

  /// Called whenever settings change.
  ///
  /// Music is only (re)started when the music setting actually changed,
  /// so toggling "sound" never restarts the background loop.
  static void configure({required bool sound, required bool music}) {
    final bool musicChanged = music != musicOn;
    soundOn = sound;
    musicOn = music;

    if (!music) {
      unawaited(stopMusic());
    } else if (musicChanged) {
      unawaited(startMusic());
    }
  }

  // --- One-liners used by the screens -------------------------------------

  static Future<void> tap() => _play(Assets.sfxTap, volume: 0.75);

  static Future<void> success() => _play(Assets.sfxSuccess);

  static Future<void> sparkle() => _play(Assets.sfxSparkle);

  static Future<void> pop() => _play(Assets.sfxPop);

  static Future<void> bubble() =>
      _play(Assets.sfxBubble, throttleMs: GameConstants.dragSoundThrottleMs);

  static Future<void> water() =>
      _play(Assets.sfxWater, throttleMs: GameConstants.dragSoundThrottleMs);

  static Future<void> brush() =>
      _play(Assets.sfxBrush, throttleMs: GameConstants.dragSoundThrottleMs);

  static Future<void> victory() => _play(Assets.sfxVictory, volume: 1);

  static Future<void> applause() => _play(Assets.sfxApplause);

  // --- Music ---------------------------------------------------------------

  static Future<void> startMusic() async {
    if (!musicOn || !_ready) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(Assets.sfxMusic));
    } catch (_) {
      // Missing music file -> stay silent.
    }
  }

  static Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  static Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  static Future<void> resumeMusic() async {
    if (!musicOn) return;
    try {
      await _musicPlayer.resume();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    for (final AudioPlayer player in _pool) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _pool.clear();
    _ready = false;
    try {
      await _musicPlayer.dispose();
    } catch (_) {}
  }

  // --- Internals -----------------------------------------------------------

  static Future<void> _play(
    String asset, {
    double volume = GameConstants.sfxVolume,
    int throttleMs = 0,
  }) async {
    if (!soundOn || !_ready || _pool.isEmpty) return;

    if (throttleMs > 0) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int last = _lastPlayedMs[asset] ?? 0;
      if (now - last < throttleMs) return;
      _lastPlayedMs[asset] = now;
    }

    try {
      final AudioPlayer player = _pool[_nextPlayer];
      _nextPlayer = (_nextPlayer + 1) % _pool.length;
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Stay silent, keep playing.
    }
  }
}
