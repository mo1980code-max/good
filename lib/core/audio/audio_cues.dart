import '../constants/assets.dart';

/// Every sound the game can play — one entry, one file, one gain, one rule.
///
/// Paths are relative to the `assets/` folder: `audioplayers` resolves
/// `AssetSource(Assets.sfxTap)` as `assets/audio/sfx/tap.mp3`.
///
/// `gain` values were chosen against the generated files (all normalised to
/// <= -8 dBFS, see docs/audio-report.md) so nothing is ever startling.
enum AudioCue {
  /// Buttons and tiles.
  tap(Assets.sfxTap, gain: 0.55),

  /// Choosing decorations, opening the studio.
  sparkle(Assets.sfxSparkle, gain: 0.70),

  /// Soap bubbles while rubbing (throttled: a rhythm, not a rattle).
  bubble(Assets.sfxBubble, gain: 0.60, throttleMs: 130),

  /// Rinsing the hand.
  water(Assets.sfxWater, gain: 0.55, throttleMs: 150),

  /// Sponge and towel strokes.
  brush(Assets.sfxBrush, gain: 0.55, throttleMs: 140),

  /// Stickers.
  pop(Assets.sfxPop, gain: 0.55, throttleMs: 90),

  /// A spa step is complete.
  success(Assets.sfxSuccess, gain: 0.75),

  /// Opening the daily gift or a surprise box.
  gift(Assets.sfxGift, gain: 0.80),

  /// The reveal fanfare.
  victory(Assets.sfxVictory, gain: 0.85),

  /// Soft crowd clap under the victory jingle.
  applause(Assets.sfxApplause, gain: 0.70),

  /// The calm background loop (never played through the SFX pool).
  music(Assets.musicSpaLoop, gain: 1.0);

  const AudioCue(this.assetPath, {required this.gain, this.throttleMs = 0});

  final String assetPath;

  /// 0..1 multiplier applied on top of the master SFX volume.
  final double gain;

  /// Minimum gap between two plays of *this* cue (0 = no limit).
  final int throttleMs;

  /// Cues that belong in the foreground pool.
  static List<AudioCue> get sfx =>
      values.where((AudioCue cue) => cue != AudioCue.music).toList();
}
