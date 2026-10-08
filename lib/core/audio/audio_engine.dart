import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_cues.dart';

/// The game's only audio authority.
///
/// Responsibilities (and nothing else):
/// * pre-load every cue into its own player -> instant playback, zero delay
/// * one **single** music player -> two loops can never overlap
/// * a global limiter (max [maxBurst] sounds per [burstWindowMs]) and a
///   per-cue throttle -> no machine-gun sound spamming
/// * mute / unmute at any time, from any screen
/// * a missing or broken file stays silent; the game never stops
///
/// UI code never touches `audioplayers`: it calls [play] with an [AudioCue].
class AudioEngine {
  AudioEngine._();

  static final AudioEngine instance = AudioEngine._();

  /// At most this many sounds inside [burstWindowMs] (anti-overlap guard).
  static const int maxBurst = 3;
  static const int burstWindowMs = 140;

  /// Master volumes (per-cue gains multiply these).
  static const double sfxMaster = 0.9;
  static const double musicMaster = 0.35;

  final Map<AudioCue, AudioPlayer> _players = <AudioCue, AudioPlayer>{};
  final Map<AudioCue, int> _lastPlayedMs = <AudioCue, int>{};
  final List<int> _burstStamps = <int>[];

  AudioPlayer? _musicPlayer;
  bool _initialised = false;
  bool _musicLoaded = false;
  bool _musicPlaying = false;
  bool _musicSuspended = false;

  bool _soundOn = true;
  bool _musicOn = true;

  bool get isInitialised => _initialised;
  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get isMusicPlaying => _musicPlaying;

  /// How many cue files loaded successfully (all of them, normally).
  int get loadedCueCount => _players.length;

  /// Called once from `main()` before the first frame.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    for (final AudioCue cue in AudioCue.sfx) {
      try {
        final AudioPlayer player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(cue.gain * sfxMaster);
        // Pre-load: the first tap of the game is already instant.
        await player.setSource(AssetSource(cue.assetPath));
        _players[cue] = player;
      } catch (error) {
        // Missing / undecodable file: this cue simply stays quiet.
        debugPrint('AudioEngine: cue "${cue.name}" unavailable ($error)');
      }
    }

    try {
      final AudioPlayer music = AudioPlayer();
      await music.setReleaseMode(ReleaseMode.loop);
      await music.setVolume(musicMaster);
      await music.setSource(AssetSource(AudioCue.music.assetPath));
      _musicPlayer = music;
      _musicLoaded = true;
    } catch (error) {
      debugPrint('AudioEngine: music unavailable ($error)');
    }
  }

  /// Applies settings coming from [SettingsModel] (called on every change).
  void configure({required bool sound, required bool music}) {
    final bool musicChanged = music != _musicOn;
    _soundOn = sound;
    _musicOn = music;

    if (!sound) {
      unawaited(stopAllSfx());
    }

    if (!music) {
      unawaited(stopMusic());
    } else if (musicChanged) {
      unawaited(startMusic());
    }
  }

  // --- Foreground sounds ---------------------------------------------------

  Future<void> play(AudioCue cue) async {
    if (!_soundOn || !_initialised) return;

    final AudioPlayer? player = _players[cue];
    if (player == null) return;

    if (!_passesThrottle(cue)) return;
    if (!_passesBurstLimiter()) return;

    try {
      // Rewind first so a repeated cue restarts instead of being ignored.
      await player.seek(Duration.zero);
      await player.resume();
    } catch (error) {
      debugPrint('AudioEngine: play "${cue.name}" failed ($error)');
    }
  }

  Future<void> stopAllSfx() async {
    for (final AudioPlayer player in _players.values) {
      try {
        await player.stop();
      } catch (_) {
        // Nothing to stop.
      }
    }
  }

  // --- Music ---------------------------------------------------------------

  /// Starts the loop. Safe to call from anywhere, any number of times:
  /// it never starts a second stream.
  Future<void> startMusic() async {
    if (!_musicOn || !_musicLoaded || _musicPlaying) return;
    final AudioPlayer? music = _musicPlayer;
    if (music == null) return;

    try {
      await music.resume();
      _musicPlaying = true;
      _musicSuspended = false;
    } catch (error) {
      debugPrint('AudioEngine: music start failed ($error)');
    }
  }

  Future<void> stopMusic() async {
    final AudioPlayer? music = _musicPlayer;
    if (music == null) return;
    try {
      await music.stop();
    } catch (_) {
      // Already stopped.
    }
    _musicPlaying = false;
    _musicSuspended = false;
  }

  /// Sent to the background: pause, remember, restore later.
  Future<void> pauseMusic() async {
    if (!_musicPlaying) return;
    try {
      await _musicPlayer?.pause();
      _musicSuspended = true;
    } catch (_) {
      // Ignore: worst case the loop keeps playing softly.
    }
  }

  Future<void> resumeMusic() async {
    if (!_musicSuspended || !_musicOn) return;
    _musicSuspended = false;
    await startMusic();
  }

  // --- Volume --------------------------------------------------------------

  Future<void> setMusicVolume(double value) async {
    try {
      await _musicPlayer?.setVolume(value.clamp(0.0, 1.0).toDouble());
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> dispose() async {
    for (final AudioPlayer player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
    try {
      await _musicPlayer?.dispose();
    } catch (_) {}
    _musicPlayer = null;
    _musicLoaded = false;
    _musicPlaying = false;
    _initialised = false;
  }

  // --- Internals -----------------------------------------------------------

  bool _passesThrottle(AudioCue cue) {
    if (cue.throttleMs <= 0) return true;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int last = _lastPlayedMs[cue] ?? 0;
    if (now - last < cue.throttleMs) return false;
    _lastPlayedMs[cue] = now;
    return true;
  }

  /// Keeps the mix clean: a toddler drumming on the screen can trigger at
  /// most [maxBurst] sounds per [burstWindowMs].
  bool _passesBurstLimiter() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    _burstStamps.removeWhere((int stamp) => now - stamp > burstWindowMs);
    if (_burstStamps.length >= maxBurst) return false;
    _burstStamps.add(now);
    return true;
  }
}
