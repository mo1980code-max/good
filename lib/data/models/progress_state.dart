import 'package:flutter/foundation.dart';

import 'design_files.dart';
import 'gallery_item.dart';

/// Everything the child has earned and created (persisted on the device).
@immutable
class ProgressState {
  const ProgressState({
    this.stars = 0,
    this.coins = 0,
    this.keys = 0,
    this.dailyStreak = 0,
    this.unlockedItemIds = const <String>{},
    this.gallery = const <GalleryItem>[],
    this.achievements = const <String>{},
    this.spaStepsCompleted = 0,
    this.boxesOpened = 0,
    this.openedGiftBoxes = const <String>{},
  });

  static const ProgressState initial = ProgressState();

  /// Awarded for finishing a design; spent on backdrops & rooms (Phase 2/3).
  final int stars;

  /// Spent on colors, stickers, patterns and rings.
  final int coins;

  /// Rare currency for surprise boxes.
  final int keys;

  final int dailyStreak;

  /// Ids of purchased catalog items (colors / stickers / rings / patterns).
  final Set<String> unlockedItemIds;

  /// Newest first.
  final List<GalleryItem> gallery;

  /// Ids of the achievements already earned. **Stars and achievements can
  /// never be lost**: they only grow, and only the grown-ups reset clears them.
  final Set<String> achievements;

  /// Spa mini-steps finished (5 per full round) — feeds the spa achievements.
  final int spaStepsCompleted;

  /// Surprise boxes opened — feeds the "surprise" achievement.
  final int boxesOpened;

  /// Ids of the gift-room boxes that were already opened (`room.box`).
  /// A box id can appear here exactly once, which is the whole
  /// "a gift is never handed out twice" guarantee: the id and its prize are
  /// written in the same state transition.
  final Set<String> openedGiftBoxes;

  int get designCount => gallery.length;

  bool isUnlocked(String itemId) => unlockedItemIds.contains(itemId);

  /// Free items (`price == 0`) are always usable.
  /// **Gift-only items are never free**: they can only be unlocked by a gift
  /// box, so they are usable if — and only if — they were already granted.
  bool canUse(String itemId, {int price = 0, bool giftOnly = false}) {
    if (isUnlocked(itemId)) return true;
    return !giftOnly && price <= 0;
  }

  /// Gift boxes already opened in one room.
  int giftBoxesOpenedIn(String roomId) => openedGiftBoxes
      .where((String id) => id.startsWith('$roomId.'))
      .length;

  ProgressState copyWith({
    int? stars,
    int? coins,
    int? keys,
    int? dailyStreak,
    Set<String>? unlockedItemIds,
    List<GalleryItem>? gallery,
    Set<String>? achievements,
    int? spaStepsCompleted,
    int? boxesOpened,
    Set<String>? openedGiftBoxes,
  }) {
    return ProgressState(
      stars: stars ?? this.stars,
      coins: coins ?? this.coins,
      keys: keys ?? this.keys,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
      gallery: gallery ?? this.gallery,
      achievements: achievements ?? this.achievements,
      spaStepsCompleted: spaStepsCompleted ?? this.spaStepsCompleted,
      boxesOpened: boxesOpened ?? this.boxesOpened,
      openedGiftBoxes: openedGiftBoxes ?? this.openedGiftBoxes,
    );
  }

  /// Pure merge of the durable design-image map (designId -> PNG name).
  ///
  /// Called when progress loads. It is what makes a save that finished *after*
  /// the reveal screen closed visible in the album.
  ProgressState withDesignImages(Map<String, String> images) {
    if (images.isEmpty || gallery.isEmpty) return this;

    bool changed = false;
    final List<GalleryItem> merged = gallery.map((GalleryItem item) {
      if (item.imageFileName != null) return item;
      final String? fileName = images[item.id];
      if (fileName == null) return item;
      changed = true;
      return item.copyWith(imageFileName: fileName);
    }).toList();

    return changed ? copyWith(gallery: merged) : this;
  }

  /// Second, index-free safety net: the file name of a design is derived from
  /// its id, so any design whose PNG really exists on disk gets its picture
  /// back — even if the `designId -> name` index never landed (app killed
  /// between the file write and the index write).
  ///
  /// Pure: it only receives the ids that were found on disk.
  ProgressState withAvailableDesigns(Set<String> idsOnDisk) {
    if (idsOnDisk.isEmpty || gallery.isEmpty) return this;

    bool changed = false;
    final List<GalleryItem> merged = gallery.map((GalleryItem item) {
      if (item.imageFileName != null) return item;
      if (!idsOnDisk.contains(item.id)) return item;
      changed = true;
      return item.copyWith(imageFileName: DesignFiles.nameFor(item.id));
    }).toList();

    return changed ? copyWith(gallery: merged) : this;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stars': stars,
      'coins': coins,
      'keys': keys,
      'dailyStreak': dailyStreak,
      'unlocked': unlockedItemIds.toList(),
      'gallery': gallery.map((GalleryItem item) => item.toJson()).toList(),
      'achievements': achievements.toList(),
      'spaSteps': spaStepsCompleted,
      'boxesOpened': boxesOpened,
      'giftBoxes': openedGiftBoxes.toList(),
    };
  }

  /// Tolerant parser: a broken field becomes a safe default, never a crash.
  factory ProgressState.fromJson(Map<String, dynamic> json) {
    final List<GalleryItem> gallery = <GalleryItem>[];
    final Object? rawGallery = json['gallery'];
    if (rawGallery is List) {
      for (final Object? entry in rawGallery) {
        final GalleryItem? item = GalleryItem.tryParse(entry);
        if (item != null) gallery.add(item);
      }
    }

    final Set<String> unlocked = _asStringSet(json['unlocked']);

    return ProgressState(
      stars: _asInt(json['stars']),
      coins: _asInt(json['coins']),
      keys: _asInt(json['keys']),
      dailyStreak: _asInt(json['dailyStreak']),
      unlockedItemIds: unlocked,
      gallery: gallery,
      achievements: _asStringSet(json['achievements']),
      spaStepsCompleted: _asInt(json['spaSteps']),
      boxesOpened: _asInt(json['boxesOpened']),
      openedGiftBoxes: _asStringSet(json['giftBoxes']),
    );
  }
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

Set<String> _asStringSet(Object? value) {
  final Set<String> result = <String>{};
  if (value is List) {
    for (final Object? entry in value) {
      if (entry is String && entry.isNotEmpty) result.add(entry);
    }
  }
  return result;
}
