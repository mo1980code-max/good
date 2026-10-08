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
  }) {
    return ProgressState(
      stars: stars ?? this.stars,
      coins: coins ?? this.coins,
      keys: keys ?? this.keys,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
      gallery: gallery ?? this.gallery,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stars': stars,
      'coins': coins,
      'keys': keys,
      'dailyStreak': dailyStreak,
      'unlocked': unlockedItemIds.toList(),
      'gallery': gallery.map((GalleryItem item) => item.toJson()).toList(),
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

    final Set<String> unlocked = <String>{};
    final Object? rawUnlocked = json['unlocked'];
    if (rawUnlocked is List) {
      for (final Object? entry in rawUnlocked) {
        if (entry is String && entry.isNotEmpty) unlocked.add(entry);
      }
    }

    return ProgressState(
      stars: _asInt(json['stars']),
      coins: _asInt(json['coins']),
      keys: _asInt(json['keys']),
      dailyStreak: _asInt(json['dailyStreak']),
      unlockedItemIds: unlocked,
      gallery: gallery,
    );
  }
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}
