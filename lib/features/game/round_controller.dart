import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/round_state.dart';
import '../../data/repositories/local_storage_service.dart';

/// Drives one makeover round: spa steps -> studio steps.
///
/// Deliberately **in-memory**: dragging a sponge never writes to disk
/// (fixes the "save on every pan update" performance problem). The only
/// persisted value is the chosen character, so the game greets the same
/// friend next time.
class RoundController extends Notifier<RoundState> {
  @override
  RoundState build() {
    final String? remembered =
        LocalStorageService.instance.loadRoundCharacterId();
    return RoundState.fresh(remembered ?? 'kitty');
  }

  void startRound(String characterId) {
    state = RoundState.fresh(characterId);
    unawaited(LocalStorageService.instance.saveRoundCharacterId(characterId));
  }

  // --- Spa room ------------------------------------------------------------

  /// Called on every drag update while rubbing the hand.
  void rub({double amount = GameConstants.spaRubPerUpdate}) {
    if (state.isSpaStepComplete) return;
    final double next = state.spaProgress + amount;
    state = state.copyWith(spaProgress: next >= 1 ? 1 : next);
  }

  /// Finishes the current spa step. Returns false if it is not done yet.
  bool advanceSpaStep() {
    if (!state.isSpaStepComplete || state.isLastSpaStep) return false;
    state = state.copyWith(spaStep: state.spaStep + 1, spaProgress: 0);
    return true;
  }

  // --- Nail studio ---------------------------------------------------------

  void selectShape(NailShape shape) {
    state = state.copyWith(shape: () => shape);
  }

  void selectColor(String colorId) {
    state = state.copyWith(colorId: () => colorId);
  }

  void selectPattern(String patternId) {
    state = state.copyWith(patternId: () => patternId);
  }

  void selectSticker(String stickerId) {
    state = state.copyWith(stickerId: () => stickerId);
  }

  void selectRing(String ringId) {
    state = state.copyWith(ringId: () => ringId);
  }

  /// Long-press = undo (GDD section 7).
  void clearStudioStep(int step) {
    state = switch (step) {
      0 => state.copyWith(shape: () => null),
      1 => state.copyWith(colorId: () => null),
      2 => state.copyWith(patternId: () => null),
      3 => state.copyWith(stickerId: () => null),
      _ => state.copyWith(ringId: () => null),
    };
  }

  bool advanceStudioStep() {
    if (!state.canAdvanceFromStudioStep || state.isLastStudioStep) return false;
    state = state.copyWith(studioStep: state.studioStep + 1);
    return true;
  }

  bool goBackStudioStep() {
    if (state.studioStep == 0) return false;
    state = state.copyWith(studioStep: state.studioStep - 1);
    return true;
  }
}
