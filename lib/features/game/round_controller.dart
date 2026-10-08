import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nail_item_model.dart';
import '../../data/models/round_state.dart';
import '../../data/repositories/local_storage_service.dart';

/// Drives one makeover round: five spa gestures, then five studio steps.
///
/// Pointer coverage is kept here rather than in a widget. That makes the
/// important rule testable and prevents a single tap from ever completing a
/// spa step or a nail: progress comes from new hand-mask cells and travelled
/// brush distance.
class RoundController extends Notifier<RoundState> {
  final Set<int> _spaCoverageCells = <int>{};

  @override
  RoundState build() {
    final String? remembered =
        LocalStorageService.instance.loadRoundCharacterId();
    return RoundState.fresh(remembered ?? 'kitty');
  }

  void startRound(String characterId) {
    _spaCoverageCells.clear();
    state = RoundState.fresh(characterId);
    unawaited(LocalStorageService.instance.saveRoundCharacterId(characterId));
  }

  // --- Spa room ------------------------------------------------------------

  /// Adds coverage for the line between two pointer samples.
  ///
  /// A hand mask is approximated by the five finger silhouettes and palm
  /// ellipse in normalized coordinates. Each new cell contributes progress,
  /// making progress depend on *where* the child rubs rather than update count.
  bool rubAlong(Offset from, Offset to, Size size) {
    if (state.isSpaStepComplete || size.width <= 0 || size.height <= 0) {
      return false;
    }

    final double distance = (to - from).distance;
    final int samples = math.max(1, (distance / 7).ceil()).toInt();
    final int before = _spaCoverageCells.length;
    for (int step = 0; step <= samples; step++) {
      final double t = step / samples;
      final Offset point = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );
      final double x = (point.dx / size.width).clamp(0.0, 1.0).toDouble();
      final double y = (point.dy / size.height).clamp(0.0, 1.0).toDouble();
      if (!_isOnHandMask(x, y)) continue;

      final int column = (x * 10).floor().clamp(0, 9).toInt();
      final int row = (y * 12).floor().clamp(0, 11).toInt();
      _spaCoverageCells.add(row * 10 + column);
    }

    final bool changed = _spaCoverageCells.length > before;
    if (!changed) return false;

    // 45 cells gives a forgiving full-hand scrub while still requiring a
    // broad, continuous gesture. The child can always use the visible Skip.
    final double progress =
        (_spaCoverageCells.length / 45.0).clamp(0.0, 1.0).toDouble();
    state = state.copyWith(spaProgress: progress);
    return true;
  }

  bool _isOnHandMask(double x, double y) {
    // Palm and lower hand.
    final double palmX = (x - 0.50) / 0.29;
    final double palmY = (y - 0.70) / 0.31;
    if (palmX * palmX + palmY * palmY <= 1.0) return true;

    // Finger beds. The rendered hand has the same five normalized targets;
    // the extra height allows a child to rub the joints, not only the nails.
    const List<({double x, double top, double width, double bottom})> fingers =
        <({double x, double top, double width, double bottom})>[
      (x: 0.145, top: 0.20, width: 0.12, bottom: 0.64),
      (x: 0.292, top: 0.12, width: 0.14, bottom: 0.61),
      (x: 0.418, top: 0.075, width: 0.15, bottom: 0.61),
      (x: 0.571, top: 0.12, width: 0.15, bottom: 0.65),
    ];
    for (final ({double x, double top, double width, double bottom}) finger
        in fingers) {
      final double dx = (x - finger.x) / finger.width;
      final double dy = (y - (finger.top + finger.bottom) / 2) /
          ((finger.bottom - finger.top) / 2);
      if (dx * dx + dy * dy <= 1.0) return true;
    }

    // Natural thumb arc on the right side.
    final double thumbX = (x - 0.73) / 0.20;
    final double thumbY = (y - 0.48) / 0.23;
    return thumbX * thumbX + thumbY * thumbY <= 1.0;
  }

  /// Finishes the current spa step. Returns false if it is not done yet.
  bool advanceSpaStep() {
    if (!state.isSpaStepComplete || state.isLastSpaStep) return false;
    _spaCoverageCells.clear();
    state = state.copyWith(spaStep: state.spaStep + 1, spaProgress: 0);
    return true;
  }

  /// Child-safe escape hatch: skipping has no coins/stars penalty and does not
  /// pretend that the gesture was completed.
  bool skipSpaStep() {
    if (state.isLastSpaStep) return false;
    _spaCoverageCells.clear();
    state = state.copyWith(spaStep: state.spaStep + 1, spaProgress: 0);
    return true;
  }

  // --- Nail studio ---------------------------------------------------------

  void selectShape(NailShape shape) {
    state = state.copyWith(shape: () => shape);
  }

  /// Loads a bottle onto the brush. It does not paint anything by itself.
  void selectColor(String colorId) {
    state = state.copyWith(colorId: () => colorId);
  }

  void selectNailLength(NailLength length) {
    state = state.copyWith(nailLengthId: length.id);
  }

  /// Assigns a colour to one of the five nails and resets that nail's
  /// movement coverage so changing colour means painting it again.
  void selectNailColor(int nailIndex, String colorId) {
    if (nailIndex < 0 || nailIndex > 4) return;
    final Map<int, String> colours = <int, String>{...state.nailColors};
    final Map<int, double> coverage = <int, double>{...state.nailCoverage};
    colours[nailIndex] = colorId;
    coverage[nailIndex] = 0;
    state = state.copyWith(
      colorId: () => colorId,
      nailColors: () => colours,
      nailCoverage: () => coverage,
    );
  }

  /// Grows paint coverage from brush travel. A tap delivers no distance and
  /// therefore no progress.
  void paintNail(int nailIndex, {required double distance}) {
    if (nailIndex < 0 || nailIndex > 4) return;
    final String? currentColour = state.colorId;
    if (currentColour == null) return;

    final String? previousColour = state.nailColors[nailIndex];
    final Map<int, String> colours = <int, String>{...state.nailColors};
    final Map<int, double> coverage = <int, double>{...state.nailCoverage};
    if (previousColour != currentColour) {
      colours[nailIndex] = currentColour;
      coverage[nailIndex] = 0;
    }
    if (!colours.containsKey(nailIndex)) {
      colours[nailIndex] = currentColour;
    }

    // About 12-18 brush samples cover a nail, with a small floor for slow
    // child drags but no floor for a stationary tap.
    final double amount = (distance / 92.0).clamp(0.006, 0.075).toDouble();
    coverage[nailIndex] =
        ((coverage[nailIndex] ?? 0) + amount).clamp(0.0, 1.0).toDouble();
    state = state.copyWith(
      nailColors: () => colours,
      nailCoverage: () => coverage,
    );
  }

  void clearNail(int nailIndex) {
    final Map<int, String> colours = <int, String>{...state.nailColors}
      ..remove(nailIndex);
    final Map<int, double> coverage = <int, double>{...state.nailCoverage}
      ..remove(nailIndex);
    state = state.copyWith(
      nailColors: () => colours,
      nailCoverage: () => coverage,
    );
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

  void selectSkinTone(String skinToneId) {
    state = state.copyWith(skinToneId: skinToneId);
  }

  /// Long-press = undo (GDD section 7).
  void clearStudioStep(int step) {
    state = switch (step) {
      0 => state.copyWith(shape: () => null),
      1 => state.copyWith(
          colorId: () => null,
          nailColors: () => <int, String>{},
          nailCoverage: () => <int, double>{},
        ),
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
