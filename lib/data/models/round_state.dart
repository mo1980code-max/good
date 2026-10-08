import 'package:flutter/foundation.dart';

import 'nail_item_model.dart';

/// The *current* round: which friend, which step, which choices.
///
/// Only [characterId] is persisted to disk. Step progress lives in memory on
/// purpose: a round lasts about a minute, and a half-finished round never
/// costs the child anything (no failure, no loss — GDD law #3).
@immutable
class RoundState {
  const RoundState({
    required this.characterId,
    this.spaStep = 0,
    this.spaProgress = 0,
    this.studioStep = 0,
    this.shape,
    this.colorId,
    this.patternId,
    this.stickerId,
    this.ringId,
  });

  /// A brand-new round for [characterId].
  factory RoundState.fresh(String characterId) {
    return RoundState(characterId: characterId);
  }

  static const int spaStepCount = 5; // clean, soap, rinse, dry, cream
  static const int studioStepCount = 5; // shape, color, pattern, sticker, ring

  final String characterId;

  /// 0..[spaStepCount] - 1
  final int spaStep;

  /// 0..1 — how clean the hand currently is (in-memory only).
  final double spaProgress;

  /// 0..[studioStepCount] - 1
  final int studioStep;

  final NailShape? shape;
  final String? colorId;
  final String? patternId;
  final String? stickerId;
  final String? ringId;

  bool get isSpaStepComplete => spaProgress >= 1;

  bool get isLastSpaStep => spaStep >= spaStepCount - 1;

  bool get isLastStudioStep => studioStep >= studioStepCount - 1;

  /// A pattern is optional (little hands may skip it) — everything else
  /// must be picked before the reveal.
  bool get hasAllRequiredPicks =>
      shape != null && colorId != null && stickerId != null && ringId != null;

  bool get canAdvanceFromStudioStep {
    return switch (studioStep) {
      0 => shape != null,
      1 => colorId != null,
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
    ValueGetter<String?>? colorId,
    ValueGetter<String?>? patternId,
    ValueGetter<String?>? stickerId,
    ValueGetter<String?>? ringId,
  }) {
    return RoundState(
      characterId: characterId ?? this.characterId,
      spaStep: spaStep ?? this.spaStep,
      spaProgress: spaProgress ?? this.spaProgress,
      studioStep: studioStep ?? this.studioStep,
      shape: shape != null ? shape() : this.shape,
      colorId: colorId != null ? colorId() : this.colorId,
      patternId: patternId != null ? patternId() : this.patternId,
      stickerId: stickerId != null ? stickerId() : this.stickerId,
      ringId: ringId != null ? ringId() : this.ringId,
    );
  }
}
