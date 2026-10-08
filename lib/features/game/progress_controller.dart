import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../data/repositories/local_storage_service.dart';

/// Owns stars, coins, keys, unlocked items and the album.
class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() => LocalStorageService.instance.loadProgress();

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

  /// Stores the captured PNG file name on an existing album entry.
  void attachImage(String designId, String? fileName) {
    if (fileName == null) return;
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

  // --- Reset (behind the grown-ups gate) -----------------------------------

  /// Clears progress, album and the daily-gift clock.
  /// Sound/music settings are intentionally untouched.
  Future<void> resetProgress() async {
    await LocalStorageService.instance.resetProgressOnly();
    state = ProgressState.initial;
  }
}
