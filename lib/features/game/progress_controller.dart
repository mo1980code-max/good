import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/achievements/achievement.dart';
import '../../core/achievements/achievement_engine.dart';
import '../../core/achievements/game_facts.dart';
import '../../core/constants/game_constants.dart';
import '../../core/gift_rooms/gift_room.dart';
import '../../core/gift_rooms/gift_room_engine.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../data/repositories/design_saver.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../data/repositories/local_storage_service.dart';

/// Owns stars, coins, keys, unlocked items and the album.
class ProgressController extends Notifier<ProgressState> {
  /// Two finishes of the very same recipe inside this window are treated as one
  /// round (a double tap on "Done" can land twice before the screen changes).
  static const int _twinWindowMs = 8000;

  bool _reconciled = false;

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

    // (a) A double tap on "Done" must not create a look-alike copy of the very
    //     same round. If an identical recipe was finished a moment ago, that
    //     design *is* this round's result — return it untouched.
    final GalleryItem? twin = _recentTwin(round, now);
    if (twin != null) return twin;

    // (b) Ids are timestamps, so two finishes inside one millisecond would
    //     collide and then share a PNG. Nudge until the id is free.
    int stamp = now;
    while (state.gallery.any((GalleryItem item) => item.id == stamp.toString())) {
      stamp++;
    }

    final GalleryItem item = GalleryItem(
      id: stamp.toString(),
      characterId: round.characterId,
      shapeId: round.shape?.id ?? NailShape.round.id,
      colorId: round.colorId ?? NailCatalog.colors.first.id,
      patternId: round.patternId ?? NailCatalog.patterns.first.id,
      stickerId: round.stickerId ?? NailCatalog.stickers.first.id,
      ringId: round.ringId ?? NailCatalog.rings.first.id,
      createdAtMs: stamp,
      imageFileName: imageFileName,
      nailLengthId: round.nailLengthId,
      nailColors: round.nailColors,
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

  /// The design that already represents this round, if it was saved within
  /// [_twinWindowMs]. The album is newest-first, so the scan can stop early.
  GalleryItem? _recentTwin(RoundState round, int now) {
    for (final GalleryItem item in state.gallery) {
      if (now - item.createdAtMs > _twinWindowMs) break;
      if (item.characterId == round.characterId &&
          item.shapeId == (round.shape?.id ?? NailShape.round.id) &&
          item.colorId == round.colorId &&
          item.patternId == round.patternId &&
          item.stickerId == round.stickerId &&
          item.ringId == round.ringId &&
          item.nailLengthId == round.nailLengthId &&
          _sameNailColours(item.nailColors, round.nailColors)) {
        return item;
      }
    }
    return null;
  }

  bool _sameNailColours(
    Map<int, String> saved,
    Map<int, String> current,
  ) {
    if (saved.length != current.length) return false;
    for (final MapEntry<int, String> entry in current.entries) {
      if (saved[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Heals the album once per session:
  ///   * deletes `.tmp_*` leftovers of a save cut short by the app closing,
  ///   * gives a picture back to any design whose PNG really exists on disk,
  ///     even when the `designId -> name` index never landed.
  ///
  /// Best-effort and provider-free: every failure is swallowed, and the next
  /// app start simply tries again.
  Future<void> reconcileAlbumImages() async {
    if (_reconciled) return;
    _reconciled = true;

    try {
      final DesignSaver saver = DesignSaver(
        files: GalleryRepository(),
        index: LocalStorageService.instance,
      );

      await saver.cleanupTempFiles();

      final Set<String> onDisk = await saver.designIdsOnDisk();
      if (onDisk.isEmpty) return;

      final ProgressState merged = state.withAvailableDesigns(onDisk);
      if (identical(merged, state)) return;

      state = merged;
      await _persist();
    } catch (_) {
      // Try again next visit — nothing is lost meanwhile.
      _reconciled = false;
    }
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

  /// See [ProgressState.canUse] — gift-only items are usable only once a gift
  /// box granted them, whatever their (zero) price says.
  bool canUse(String itemId, {int price = 0, bool giftOnly = false}) =>
      state.canUse(itemId, price: price, giftOnly: giftOnly);

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

  // --- Gift rooms (Phase 2.5) ----------------------------------------------

  /// Badges earned so far — the second gate on the gift rooms.
  int get badgeCount => state.achievements.length;

  bool isRoomUnlocked(String roomId) {
    final GiftRoom? room = GiftRoomCatalog.byId(roomId);
    if (room == null) return false;
    return GiftRoomEngine.isUnlocked(room, stars: state.stars);
  }

  /// Live picture of all four rooms (unlocked, boxes opened, stars to go).
  List<GiftRoomProgress> giftRooms() => GiftRoomEngine.snapshot(
        stars: state.stars,
        badges: badgeCount,
        openedBoxes: state.openedGiftBoxes,
      );

  GiftBoxState giftBoxState(GiftBox box) => GiftRoomEngine.stateOf(
        box: box,
        stars: state.stars,
        badges: badgeCount,
        openedBoxes: state.openedGiftBoxes,
      );

  /// Opens a gift box **exactly once**.
  ///
  /// The box id and its prize are written in a *single* state transition, and
  /// the guard reads that same state synchronously — so a double tap, a
  /// rebuild, a re-entered room or an app restart can never hand the same gift
  /// out twice. Returns `null` when the box is unknown, already opened, still
  /// needs badges, or its room is not reached yet. Nothing is ever lost by a
  /// refused open: the box just stays there, waiting.
  GiftPrize? openGiftBox(String boxId) {
    final GiftBox? box = GiftRoomCatalog.boxById(boxId);
    if (box == null) return null;

    if (!GiftRoomEngine.canOpen(
      box: box,
      stars: state.stars,
      badges: badgeCount,
      openedBoxes: state.openedGiftBoxes,
    )) {
      return null;
    }

    final GiftPrize prize = box.prize;
    final Set<String> unlocked = prize.isItem
        ? <String>{...state.unlockedItemIds, prize.itemId!}
        : state.unlockedItemIds;

    state = state.copyWith(
      openedGiftBoxes: <String>{...state.openedGiftBoxes, box.id},
      unlockedItemIds: unlocked,
      coins: state.coins +
          (prize.kind == GiftPrizeKind.coins ? prize.amount : 0),
      keys: state.keys + (prize.kind == GiftPrizeKind.keys ? prize.amount : 0),
      stars:
          state.stars + (prize.kind == GiftPrizeKind.stars ? prize.amount : 0),
    );
    unawaited(_persist());
    return prize;
  }

  // --- Reset (behind the grown-ups gate) -----------------------------------

  /// Clears progress, album and the daily-gift clock.
  /// Sound/music settings are intentionally untouched.
  Future<void> resetProgress() async {
    await LocalStorageService.instance.resetProgressOnly();
    state = ProgressState.initial;
  }
}
