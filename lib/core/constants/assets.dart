/// All asset paths in one place.
///
/// IMPORTANT — sound paths have **no** `assets/` prefix: `audioplayers`
/// resolves `AssetSource` relative to the `assets/` folder automatically
/// (so `'audio/sfx/tap.mp3'` means `assets/audio/sfx/tap.mp3`).
///
/// Sounds live under `assets/audio/sfx/` and `assets/audio/music/`; the cue
/// table (gains, throttles) is in `lib/core/audio/audio_cues.dart`.
abstract final class Assets {
  // --- UI ---
  static const String logo = 'assets/images/ui/logo.png';
  static const String sparkleIcon = 'assets/images/ui/sparkle.png';

  // --- Real hand artwork ---------------------------------------------------
  // Transparent, top-down hand with natural nail beds. All interaction is
  // layered over this asset; it is not a screenshot pretending to be a game.
  static const String realisticHand =
      'assets/images/hand/realistic_hand.png';
  static const String handDirty = 'assets/images/hand_dirty.png';
  static const String handClean = 'assets/images/hand_clean.png';

  // --- Characters (original, 6 total) ---
  static const String kitty = 'assets/images/characters/kitty.png';
  static const String bunny = 'assets/images/characters/bunny.png';
  static const String panda = 'assets/images/characters/panda.png';
  static const String unicorn = 'assets/images/characters/unicorn.png';
  static const String fairy = 'assets/images/characters/fairy.png';
  static const String kid = 'assets/images/characters/kid.png';

  // --- Spa tools ---
  static const String sponge = 'assets/images/tools/sponge.png';
  static const String soap = 'assets/images/tools/soap.png';
  static const String towel = 'assets/images/tools/towel.png';
  static const String cream = 'assets/images/tools/cream.png';
  static const String brush = 'assets/images/tools/brush.png';
  static const String water = 'assets/images/tools/water.png';

  // --- Stickers (12) ---
  static const String stickerStar = 'assets/images/stickers/star.png';
  static const String stickerHeart = 'assets/images/stickers/heart.png';
  static const String stickerFlower = 'assets/images/stickers/flower.png';
  static const String stickerCandy = 'assets/images/stickers/candy.png';
  static const String stickerRainbow = 'assets/images/stickers/rainbow.png';
  static const String stickerSparkle = 'assets/images/stickers/sparkle.png';
  static const String stickerCloud = 'assets/images/stickers/cloud.png';
  static const String stickerMoon = 'assets/images/stickers/moon.png';
  static const String stickerCherry = 'assets/images/stickers/cherry.png';
  static const String stickerBow = 'assets/images/stickers/bow.png';
  static const String stickerGem = 'assets/images/stickers/gem.png';
  static const String stickerButterfly = 'assets/images/stickers/butterfly.png';

  // --- Rings (8) ---
  static const String ring1 = 'assets/images/ui/ring_1.png';
  static const String ring2 = 'assets/images/ui/ring_2.png';
  static const String ring3 = 'assets/images/ui/ring_3.png';
  static const String ring4 = 'assets/images/ui/ring_4.png';
  static const String ring5 = 'assets/images/ui/ring_5.png';
  static const String ring6 = 'assets/images/ui/ring_6.png';
  static const String ring7 = 'assets/images/ui/ring_7.png';
  static const String ring8 = 'assets/images/ui/ring_8.png';

  // --- Sounds (relative to assets/ — see lib/core/audio/audio_cues.dart) ---
  static const String sfxTap = 'audio/sfx/tap.mp3';
  static const String sfxSparkle = 'audio/sfx/sparkle.mp3';
  static const String sfxBubble = 'audio/sfx/bubble.mp3';
  static const String sfxWater = 'audio/sfx/water.mp3';
  static const String sfxBrush = 'audio/sfx/brush.mp3';
  static const String sfxPop = 'audio/sfx/pop.mp3';
  static const String sfxSuccess = 'audio/sfx/success.mp3';
  static const String sfxGift = 'audio/sfx/gift.mp3';
  static const String sfxVictory = 'audio/sfx/victory.mp3';
  static const String sfxApplause = 'audio/sfx/applause.mp3';
  static const String musicSpaLoop = 'audio/music/spa_loop.mp3';
}
