import 'package:flutter/foundation.dart';

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

  int get designCount => gallery.length;

  bool isUnlocked(String itemId) => unlockedItemIds.contains(itemId);

  /// Free items (`price == 0`) are always usable.
  bool canUse(String itemId, {int price = 0}) => price <= 0 || isUnlocked(itemId);

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
