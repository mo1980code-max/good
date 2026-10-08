import 'dart:async';

import 'audio_cues.dart';
import 'audio_engine.dart';

/// Thin, friendly facade in front of [AudioEngine].
///
/// Screens call `SoundHelper.tap()` / `SoundHelper.victory()` and stay
/// completely unaware of players, assets and pools — that is the whole point
/// of the split. All the logic lives in `audio_engine.dart`, all the data in
/// `audio_cues.dart`.
///
/// Every call is fire-and-forget and failure-proof: if a sound file is absent
/// the game keeps playing, silently.
abstract final class SoundHelper {
  /// Prepare the pool (called once from `main()`).
  static Future<void> init() => AudioEngine.instance.init();

  /// Apply the saved settings and keep music in sync.
  static void configure({required bool sound, required bool music}) =>
      AudioEngine.instance.configure(sound: sound, music: music);

  // --- Reflection for screens/UI ------------------------------------------

  static bool get soundOn => AudioEngine.instance.soundOn;

  static bool get musicOn => AudioEngine.instance.musicOn;

  static bool get isMusicPlaying => AudioEngine.instance.isMusicPlaying;

  // --- One-liners used by the screens -------------------------------------

  static Future<void> tap() => AudioEngine.instance.play(AudioCue.tap);

  static Future<void> sparkle() => AudioEngine.instance.play(AudioCue.sparkle);

  static Future<void> bubble() => AudioEngine.instance.play(AudioCue.bubble);

  static Future<void> water() => AudioEngine.instance.play(AudioCue.water);

  static Future<void> brush() => AudioEngine.instance.play(AudioCue.brush);

  static Future<void> pop() => AudioEngine.instance.play(AudioCue.pop);

  static Future<void> success() => AudioEngine.instance.play(AudioCue.success);

  static Future<void> gift() => AudioEngine.instance.play(AudioCue.gift);

  static Future<void> victory() => AudioEngine.instance.play(AudioCue.victory);

  static Future<void> applause() => AudioEngine.instance.play(AudioCue.applause);

  // --- Music ---------------------------------------------------------------

  /// Idempotent: calling it from every screen still results in ONE loop.
  static Future<void> startMusic() => AudioEngine.instance.startMusic();

  static Future<void> stopMusic() => AudioEngine.instance.stopMusic();

  /// App going to the background.
  static Future<void> pauseMusic() => AudioEngine.instance.pauseMusic();

  /// Back to the foreground.
  static Future<void> resumeMusic() => AudioEngine.instance.resumeMusic();

  static Future<void> dispose() => AudioEngine.instance.dispose();

  /// Convenience for "play this exact cue" call sites.
  static Future<void> cue(AudioCue value) => AudioEngine.instance.play(value);

  /// Fire-and-forget helper (used where awaiting would delay a tap).
  static void fire(AudioCue value) => unawaited(AudioEngine.instance.play(value));
}
