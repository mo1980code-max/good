import 'package:flutter/foundation.dart';

import '../../data/models/gallery_item.dart';
import '../../data/models/progress_state.dart';
import 'achievement.dart';

/// A flat snapshot of "what the child has done so far".
///
/// The engine only needs numbers, never the widget tree, never storage — which
/// is exactly what makes achievements testable without running Flutter's UI.
@immutable
class GameFacts {
  const GameFacts({
    required this.designs,
    required this.spaSteps,
    required this.distinctColors,
    required this.distinctStickers,
    required this.distinctRings,
    required this.distinctPatterns,
    required this.distinctCharacters,
    required this.dailyStreak,
    required this.boxesOpened,
  });

  static const GameFacts empty = GameFacts(
    designs: 0,
    spaSteps: 0,
    distinctColors: 0,
    distinctStickers: 0,
    distinctRings: 0,
    distinctPatterns: 0,
    distinctCharacters: 0,
    dailyStreak: 0,
    boxesOpened: 0,
  );

  final int designs;
  final int spaSteps;
  final int distinctColors;
  final int distinctStickers;
  final int distinctRings;
  final int distinctPatterns;
  final int distinctCharacters;
  final int dailyStreak;
  final int boxesOpened;

  /// Reads a metric by its enum — the only bridge between data and engine.
  int valueOf(AchievementMetric metric) => switch (metric) {
        AchievementMetric.designs => designs,
        AchievementMetric.spaSteps => spaSteps,
        AchievementMetric.distinctColors => distinctColors,
        AchievementMetric.distinctStickers => distinctStickers,
        AchievementMetric.distinctRings => distinctRings,
        AchievementMetric.distinctPatterns => distinctPatterns,
        AchievementMetric.distinctCharacters => distinctCharacters,
        AchievementMetric.dailyStreak => dailyStreak,
        AchievementMetric.boxesOpened => boxesOpened,
      };

  /// Derives everything derivable from the album (it already stores the full
  /// recipe of every design) and takes the counters from the saved progress.
  factory GameFacts.fromProgress(ProgressState progress) {
    final List<GalleryItem> gallery = progress.gallery;

    return GameFacts(
      designs: gallery.length,
      spaSteps: progress.spaStepsCompleted,
      distinctColors: _distinctCount(
        gallery.map((GalleryItem item) => item.colorId),
      ),
      distinctStickers: _distinctCount(
        gallery.map((GalleryItem item) => item.stickerId),
      ),
      distinctRings: _distinctCount(
        gallery.map((GalleryItem item) => item.ringId),
      ),
      distinctPatterns: _distinctCount(
        gallery.map((GalleryItem item) => item.patternId),
      ),
      distinctCharacters: _distinctCount(
        gallery.map((GalleryItem item) => item.characterId),
      ),
      dailyStreak: progress.dailyStreak,
      boxesOpened: progress.boxesOpened,
    );
  }

  GameFacts copyWith({
    int? designs,
    int? spaSteps,
    int? distinctColors,
    int? distinctStickers,
    int? distinctRings,
    int? distinctPatterns,
    int? distinctCharacters,
    int? dailyStreak,
    int? boxesOpened,
  }) {
    return GameFacts(
      designs: designs ?? this.designs,
      spaSteps: spaSteps ?? this.spaSteps,
      distinctColors: distinctColors ?? this.distinctColors,
      distinctStickers: distinctStickers ?? this.distinctStickers,
      distinctRings: distinctRings ?? this.distinctRings,
      distinctPatterns: distinctPatterns ?? this.distinctPatterns,
      distinctCharacters: distinctCharacters ?? this.distinctCharacters,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      boxesOpened: boxesOpened ?? this.boxesOpened,
    );
  }

  static int _distinctCount(Iterable<String> values) {
    final Set<String> unique = <String>{};
    for (final String value in values) {
      if (value.isNotEmpty) unique.add(value);
    }
    return unique.length;
  }
}
