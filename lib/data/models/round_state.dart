import 'package:flutter/foundation.dart';

import 'nail_item_model.dart';

/// The current makeover round: friend, spa gesture progress and nail recipe.
///
/// The interactive maps are intentionally in-memory. They make each nail a
/// real paint target without writing to storage on every pointer update. The
/// finished recipe still uses the existing [colorId] field, so old saves and
/// the gallery remain compatible.
@immutable
class RoundState {
  const RoundState({
    required this.characterId,
    this.spaStep = 0,
    this.spaProgress = 0,
    this.studioStep = 0,
    this.shape,
    this.nailLengthId = 'medium',
    this.colorId,
    this.patternId,
    this.stickerId,
    this.ringId,
    this.nailColors = const <int, String>{},
    this.nailCoverage = const <int, double>{},
    this.skinToneId = 'natural',
  });

  /// A brand-new round for [characterId].
  factory RoundState.fresh(String characterId) {
    return RoundState(characterId: characterId);
  }

  static const int spaStepCount = 5; // clean, soap, rinse, dry, cream
  static const int studioStepCount = 5; // shape, paint, pattern, sticker, ring

  final String characterId;

  /// 0..[spaStepCount] - 1
  final int spaStep;

  /// 0..1 — coverage of the current spa gesture, in memory only.
  final double spaProgress;

  /// 0..[studioStepCount] - 1
  final int studioStep;

  final NailShape? shape;
  final String nailLengthId;
  /// The colour currently loaded on the brush (and the legacy base colour).
  final String? colorId;
  final String? patternId;
  final String? stickerId;
  final String? ringId;

  /// Five independent bottle choices and five movement-based coverages.
  final Map<int, String> nailColors;
  final Map<int, double> nailCoverage;

  /// Selected from the small tone tray in Spa or Studio.
  final String skinToneId;

  bool get isSpaStepComplete => spaProgress >= 1;

  bool get isLastSpaStep => spaStep >= spaStepCount - 1;

  bool get isLastStudioStep => studioStep >= studioStepCount - 1;

  bool get allNailsPainted =>
      List<bool>.generate(
        5,
        (int index) =>
            nailColors[index] != null && (nailCoverage[index] ?? 0) >= 1,
      ).every((bool value) => value);

  /// A pattern is optional (little hands may skip it) — everything else,
  /// including five actual brush passes in the paint step, is required.
  bool get hasAllRequiredPicks =>
      shape != null && colorId != null && stickerId != null && ringId != null;

  bool get canAdvanceFromStudioStep {
    return switch (studioStep) {
      0 => shape != null,
      1 => allNailsPainted,
      2 => true, // pattern is optional
      3 => stickerId != null,
      _ => ringId != null,
    };
  }

  /// Uses `ValueGetter` arguments so a choice can be *cleared* (set to null):
  /// `copyWith(colorId: () => null)`.
  RoundState copyWith({
    String? characterId,
    int? spaStep,
    double? spaProgress,
    int? studioStep,
    ValueGetter<NailShape?>? shape,
    String? nailLengthId,
    ValueGetter<String?>? colorId,
    ValueGetter<String?>? patternId,
    ValueGetter<String?>? stickerId,
    ValueGetter<String?>? ringId,
    ValueGetter<Map<int, String>>? nailColors,
    ValueGetter<Map<int, double>>? nailCoverage,
    String? skinToneId,
  }) {
    return RoundState(
      characterId: characterId ?? this.characterId,
      spaStep: spaStep ?? this.spaStep,
      spaProgress: spaProgress ?? this.spaProgress,
      studioStep: studioStep ?? this.studioStep,
      shape: shape != null ? shape() : this.shape,
      nailLengthId: nailLengthId ?? this.nailLengthId,
      colorId: colorId != null ? colorId() : this.colorId,
      patternId: patternId != null ? patternId() : this.patternId,
      stickerId: stickerId != null ? stickerId() : this.stickerId,
      ringId: ringId != null ? ringId() : this.ringId,
      nailColors: nailColors != null ? nailColors() : this.nailColors,
      nailCoverage: nailCoverage != null ? nailCoverage() : this.nailCoverage,
      skinToneId: skinToneId ?? this.skinToneId,
    );
  }
}
