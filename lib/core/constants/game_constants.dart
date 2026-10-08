/// Every tunable number lives here so "feel" can be adjusted in one place.
abstract final class GameConstants {
  // --- Round flow (see GDD section 7) ---
  static const int spaStepCount = 5; // clean, soap, rinse, dry, cream
  static const int studioStepCount = 5; // shape, color, pattern, sticker, ring

  // --- Spa tuning ---
  /// Progress added per drag update while rubbing. 0.055 => ~18 rubs.
  static const double spaRubPerUpdate = 0.055;

  // --- Rewards (GDD section 8) ---
  static const int starsPerRound = 3;
  static const int coinsPerRound = 20;
  static const int dailyRewardCoins = 25;
  static const int dailyRewardKeys = 1;

  // --- Gallery ---
  /// Newest designs are kept in-app; older PNGs stay on the device.
  static const int galleryMaxItems = 200;

  // --- Audio ---
  /// Drag sounds (water / brush / bubbles) are throttled to avoid spam.
  static const int dragSoundThrottleMs = 120;
  static const double sfxVolume = 0.9;
  static const double musicVolume = 0.35;

  // --- Parent gate (GDD section 12) ---
  static const Duration parentGateHold = Duration(seconds: 3);

  // --- Motion ---
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fastAnim = Duration(milliseconds: 180);
  static const Duration screenAnim = Duration(milliseconds: 260);
  static const Duration celebrateAnim = Duration(milliseconds: 400);
}
