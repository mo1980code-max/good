import 'package:flutter/material.dart';

import '../data/models/character_model.dart';
import '../widgets/character_face.dart';
import 'art_direction.dart';
import 'asset_slots.dart';

/// Picks the real artwork when the file exists, otherwise a hand-made
/// fallback — and never crashes when a file is missing.
///
/// This is the whole trick that keeps Phase 2 (art) separate from Phase 1
/// (logic): gameplay always asks for a *widget*, never for a file.
class ArtOrFallback extends StatelessWidget {
  const ArtOrFallback({
    required this.asset,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  /// Absolute asset path, or `null` to force the fallback.
  final String? asset;
  final Widget fallback;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final String? path = asset;
    if (path == null) return fallback;

    return Image.asset(
      path,
      fit: fit,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

/// A character, illustrated if possible, drawn otherwise.
///
/// * `preferProcedural: true` keeps the **living face** (blinks, reacts, shows
///   moods) — used in the spa and the studio, where feedback matters.
/// * Default mode shows the illustrated portrait — used in tiles, cards and
///   the home greeting, where a still picture is all that is needed.
class CharacterArt extends StatelessWidget {
  const CharacterArt({
    required this.character,
    this.size = 120,
    this.mood = FaceMood.calm,
    this.preferProcedural = false,
    this.illustrationScale = 1.0,
    super.key,
  });

  final CharacterModel character;
  final double size;
  final FaceMood mood;
  final bool preferProcedural;
  final double illustrationScale;

  bool get _useIllustration =>
      ArtDirection.illustratedPortraits && !preferProcedural;

  @override
  Widget build(BuildContext context) {
    final CharacterFace face = CharacterFace(
      character: character,
      size: size,
      mood: mood,
    );

    final Widget illustrated = SizedBox(
      width: size * illustrationScale,
      height: size * illustrationScale,
      child: ArtOrFallback(
        asset: ArtSlots.characterPortrait(character.id),
        fit: BoxFit.contain,
        semanticLabel: character.name,
        fallback: face,
      ),
    );

    return Center(child: illustrated);
  }
}

/// A room backdrop: the illustrated 16:9 image when present, otherwise a soft
/// pastel wash in that room's own light temperature.
class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({
    required this.roomId,
    this.opacity = 1.0,
    super.key,
  });

  final String roomId;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final RoomArtSpec spec = ArtDirection.room(roomId);

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: ArtOrFallback(
          asset: ArtSlots.roomBackdrop(roomId),
          fit: BoxFit.cover,
          fallback: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  spec.light,
                  Color.lerp(spec.light, Colors.white, 0.55) ?? Colors.white,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
