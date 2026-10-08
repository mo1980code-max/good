import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/achievements/achievement.dart';
import '../../core/achievements/achievement_engine.dart';
import '../../core/achievements/game_facts.dart';
import '../../core/constants/game_constants.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../data/repositories/local_storage_service.dart';

/// Owns stars, coins, keys, unlocked items and the album.
class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    final LocalStorageService storage = LocalStorageService.instance;

    // Merge the durable design-image map (designId -> PNG). A save that landed
    // *after* the reveal screen closed is picked up right here.
    return storage.loadProgress().withDesignImages(storage.loadDesignImages());
  }

  Future<void> _persist() => LocalStorageService.instance.saveProgress(state);

  /// Called from the Reveal screen: turns the finished round into an album
  /// entry and pays the reward. Returns the new entry so the UI can capture
  /// and attach its PNG (see [attachImage]).
  GalleryItem completeRound(RoundState round, {String? imageFileName}) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    final GalleryItem item = GalleryItem(
      id: now.toString(),
      characterId: round.characterId,
      shapeId: round.shape?.id ?? NailShape.round.id,
      colorId: round.colorId ?? NailCatalog.colors.first.id,
      patternId: round.patternId ?? NailCatalog.patterns.first.id,
      stickerId: round.stickerId ?? NailCatalog.stickers.first.id,
      ringId: round.ringId ?? NailCatalog.rings.first.id,
      createdAtMs: now,
      imageFileName: imageFileName,
    );

    // Newest first, capped so the save file stays small and fast.
    final List<GalleryItem> gallery = <GalleryItem>[item, ...state.gallery];
    if (gallery.length > GameConstants.galleryMaxItems) {
      gallery.removeRange(GameConstants.galleryMaxItems, gallery.length);
    }

    state = state.copyWith(
      stars: state.stars + GameConstants.starsPerRound,
      coins: state.coins + GameConstants.coinsPerRound,
      gallery: gallery,
    );
    unawaited(_persist());
    return item;
  }

  /// Mirrors a design image that [DesignSaver] already stored on the device
  /// into the in-memory album. Purely cosmetic: if this never runs (the screen
  /// was disposed first), the next `build()` merges it from storage anyway.
  void attachImage(String designId, String? fileName) {
    if (fileName == null) return;
    if (!_hasItem(designId)) return;

    final List<GalleryItem> gallery = state.gallery
        .map(
          (GalleryItem item) => item.id == designId
              ? item.copyWith(imageFileName: fileName)
              : item,
        )
        .toList();
    state = state.copyWith(gallery: gallery);
    unawaited(_persist());
  }

  bool _hasItem(String designId) =>
      state.gallery.any((GalleryItem item) => item.id == designId);

  // --- Achievements --------------------------------------------------------

  /// Counters that feed the badges (spa steps, opened boxes).
  void recordSpaSteps(int count) {
    if (count <= 0) return;
    state = state.copyWith(
      spaStepsCompleted: state.spaStepsCompleted + count,
    );
    unawaited(_persist());
  }

  void recordBoxOpened() {
    state = state.copyWith(boxesOpened: state.boxesOpened + 1);
    unawaited(_persist());
  }

  /// Facts snapshot for the engine (pure, derived from what is already saved).
  GameFacts get facts => GameFacts.fromProgress(state);

  /// Badges reachable right now that were not earned yet. **Read-only**: this
  /// never grants anything, so it is safe to call on every rebuild.
  List<Achievement> pendingAchievements() => AchievementEngine.newlyEarned(
        facts: facts,
        earnedIds: state.achievements,
      );

  /// Grants the listed badges, once each, and returns them.
  ///
  /// Paying twice is impossible: an id already in [ProgressState.achievements]
  /// is skipped, and the engine already filtered those out.
  List<Achievement> claimAchievements(List<Achievement> candidates) {
    final List<Achievement> fresh = candidates
        .where((Achievement a) => !state.achievements.contains(a.id))
        .toList();
    if (fresh.isEmpty) return const <Achievement>[];

    final ({int coins, int stars}) reward =
        AchievementEngine.rewardFor(fresh);

    state = state.copyWith(
      achievements: <String>{
        ...state.achievements,
        ...fresh.map((Achievement a) => a.id),
      },
      coins: state.coins + reward.coins,
      stars: state.stars + reward.stars,
    );
    unawaited(_persist());
    return fresh;
  }

  // --- Daily gift ----------------------------------------------------------

  bool canClaimDailyReward() =>
      LocalStorageService.instance.canClaimDailyReward();

  /// Returns false when today's gift was already opened.
  Future<bool> claimDailyReward() async {
    final LocalStorageService storage = LocalStorageService.instance;
    final bool claimed = await storage.claimDailyReward();
    if (!claimed) return false;

    final int streak = state.dailyStreak + 1;
    state = state.copyWith(
      coins: state.coins + GameConstants.dailyRewardCoins,
      keys: state.keys + GameConstants.dailyRewardKeys,
      dailyStreak: streak,
    );
    unawaited(storage.saveDailyStreak(streak));
    unawaited(_persist());
    return true;
  }

  // --- Shop / unlockables --------------------------------------------------

  bool canUse(String itemId, {int price = 0}) =>
      state.canUse(itemId, price: price);

  /// Spends coins to unlock an item. Returns false when it is too expensive.
  bool unlock(String itemId, {required int price}) {
    if (state.isUnlocked(itemId)) return true;
    if (state.coins < price) return false;

    state = state.copyWith(
      coins: state.coins - price,
      unlockedItemIds: <String>{...state.unlockedItemIds, itemId},
    );
    unawaited(_persist());
    return true;
  }

  /// Gives an item for free (surprise boxes, achievements).
  void grantUnlock(String itemId) {
    if (state.isUnlocked(itemId)) return;
    state = state.copyWith(
      unlockedItemIds: <String>{...state.unlockedItemIds, itemId},
    );
    unawaited(_persist());
  }

  void addCoins(int amount) {
    if (amount == 0) return;
    state = state.copyWith(coins: state.coins + amount);
    unawaited(_persist());
  }

  /// Surprise boxes cost a key. Returns false when the purse is empty.
  bool spendKeys(int amount) {
    if (amount <= 0) return true;
    if (state.keys < amount) return false;
    state = state.copyWith(keys: state.keys - amount);
    unawaited(_persist());
    return true;
  }

  // --- Album ---------------------------------------------------------------

  /// Removes one design from the album (used by the gated delete action).
  void removeDesign(String designId) {
    final List<GalleryItem> gallery = state.gallery
        .where((GalleryItem item) => item.id != designId)
        .toList();
    state = state.copyWith(gallery: gallery);
    unawaited(_persist());
  }

  // --- Reset (behind the grown-ups gate) -----------------------------------

  /// Clears progress, album and the daily-gift clock.
  /// Sound/music settings are intentionally untouched.
  Future<void> resetProgress() async {
    await LocalStorageService.instance.resetProgressOnly();
    state = ProgressState.initial;
  }
}
