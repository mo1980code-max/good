import 'package:flutter/material.dart';

/// How a character is built, in one glance — the contract between the
/// procedural painter (today) and the illustrated PNG (when art lands).
///
/// Keep this file free of gameplay logic: it is *only* about looks.
@immutable
class CharacterArtSpec {
  const CharacterArtSpec({
    required this.id,
    required this.accent,
    required this.baseCoat,
    required this.signature,
    required this.personality,
  });

  final String id;

  /// The character's hero colour (used by tiles, rings, confetti).
  final Color accent;

  /// The main body colour of the mascot itself.
  final Color baseCoat;

  /// The one prop that makes the silhouette unmistakable.
  final String signature;

  /// Three words an artist can act on.
  final String personality;
}

/// The single source of truth for how Sparkle Bay *looks*.
///
/// Everything visual is a token: nobody hardcodes a radius, an outline width
/// or a glow blur inside a screen file.
abstract final class ArtDirection {
  // --- Global toggle -------------------------------------------------------

  /// `true`  -> use illustrated PNG portraits where they exist.
  /// `false` -> always draw the procedural faces (useful for tests or while
  ///            reviewing art that is still work-in-progress).
  static const bool illustratedPortraits = true;

  // --- Shape language ------------------------------------------------------

  /// Thick, rounded outlines are what make the art read as "toy-like".
  static const double outlineWidth = 2.4;

  /// Cards, sheets and panels.
  static const double bigRadius = 34;

  /// Small tiles and option chips.
  static const double tileRadiusFactor = 0.30;

  /// Bottom-radius used by buttons (height / value).
  static const double buttonRadiusFactor = 3;

  /// Soft coloured glow under every interactive object.
  static const double glowBlur = 16;
  static const double glowOffsetY = 8;

  // --- Light & sparkle -----------------------------------------------------

  /// Sparkles per full screen background.
  static const int sparkleDensity = 18;

  /// How much white we blend into a pastel to get the "glossy" version.
  static const double glossAmount = 0.30;

  /// Opacity of the flat pastel wash behind cards.
  static const double panelOpacity = 0.72;

  // --- Character sheet -----------------------------------------------------

  static const Map<String, CharacterArtSpec> characters =
      <String, CharacterArtSpec>{
    'kitty': CharacterArtSpec(
      id: 'kitty',
      accent: Color(0xFFFF8BCB),
      baseCoat: Color(0xFFFFF3E9),
      signature: 'Pink bow on the left ear + whiskers',
      personality: 'playful, bossy, sweet',
    ),
    'bunny': CharacterArtSpec(
      id: 'bunny',
      accent: Color(0xFFFFC86E),
      baseCoat: Color(0xFFFFF6EC),
      signature: 'Tall ears with peach inner tips + daisy',
      personality: 'shy, bouncy, gentle',
    ),
    'panda': CharacterArtSpec(
      id: 'panda',
      accent: Color(0xFF7DD3FC),
      baseCoat: Color(0xFFFFFFFF),
      signature: 'Sky-blue scarf + round dark patches',
      personality: 'calm, cozy, patient',
    ),
    'unicorn': CharacterArtSpec(
      id: 'unicorn',
      accent: Color(0xFFB57BFF),
      baseCoat: Color(0xFFF6F0FF),
      signature: 'Rainbow mane + golden spiral horn',
      personality: 'dreamy, magical, kind',
    ),
    'fairy': CharacterArtSpec(
      id: 'fairy',
      accent: Color(0xFF63E6D8),
      baseCoat: Color(0xFFEFFFFC),
      signature: 'Translucent wings + curled antennae',
      personality: 'mischievous, twinkly, fast',
    ),
    'kid': CharacterArtSpec(
      id: 'kid',
      accent: Color(0xFFFF9C7A),
      baseCoat: Color(0xFFFFE0C9),
      signature: 'Coral overalls + one cheeky cowlick',
      personality: 'curious, giggly, brave',
    ),
  };

  /// Never throws: unknown ids fall back to the first spec.
  static CharacterArtSpec character(String id) {
    return characters[id] ?? characters.values.first;
  }

  // --- Room sheet ----------------------------------------------------------

  /// Nine rooms, each with its own light temperature so the child can feel
  /// where they are without reading a word.
  static const Map<String, RoomArtSpec> rooms = <String, RoomArtSpec>{
    'splash': RoomArtSpec(
      id: 'splash',
      light: Color(0xFFFFF4FB),
      mood: 'bedtime-glow',
    ),
    'home': RoomArtSpec(
      id: 'home',
      light: Color(0xFFFFF7FD),
      mood: 'sunny-living-room',
    ),
    'characters': RoomArtSpec(
      id: 'characters',
      light: Color(0xFFF3ECFF),
      mood: 'toy-shelf',
    ),
    'spa': RoomArtSpec(
      id: 'spa',
      light: Color(0xFFEAF8FF),
      mood: 'steamy-spa',
    ),
    'studio': RoomArtSpec(
      id: 'studio',
      light: Color(0xFFFFF0F7),
      mood: 'candy-workshop',
    ),
    'reveal': RoomArtSpec(
      id: 'reveal',
      light: Color(0xFFFFF7E8),
      mood: 'spotlight-stage',
    ),
    'gallery': RoomArtSpec(
      id: 'gallery',
      light: Color(0xFFF2ECFF),
      mood: 'star-wall',
    ),
    'rewards': RoomArtSpec(
      id: 'rewards',
      light: Color(0xFFEAFBF6),
      mood: 'gift-room',
    ),
    'settings': RoomArtSpec(
      id: 'settings',
      light: Color(0xFFF4F1FA),
      mood: 'quiet-study',
    ),
    // --- Gift rooms (Phase 2.5): one pastel wash per room -----------------
    'gifts': RoomArtSpec(
      id: 'gifts',
      light: Color(0xFFFFF1F8),
      mood: 'present-corridor',
    ),
    'gift_blush': RoomArtSpec(
      id: 'gift_blush',
      light: Color(0xFFFFE3F1),
      mood: 'candy-pink-room',
    ),
    'gift_mint': RoomArtSpec(
      id: 'gift_mint',
      light: Color(0xFFD9FBF6),
      mood: 'fresh-mint-room',
    ),
    'gift_sky': RoomArtSpec(
      id: 'gift_sky',
      light: Color(0xFFDFF1FF),
      mood: 'cloud-sky-room',
    ),
    'gift_sunny': RoomArtSpec(
      id: 'gift_sunny',
      light: Color(0xFFFFF3D6),
      mood: 'sunny-honey-room',
    ),
  };

  static RoomArtSpec room(String id) => rooms[id] ?? rooms.values.first;
}

/// One room's look.
@immutable
class RoomArtSpec {
  const RoomArtSpec({
    required this.id,
    required this.light,
    required this.mood,
  });

  final String id;

  /// The flat wash colour used behind that room (and as the fallback when the
  /// illustrated backdrop is missing).
  final Color light;

  /// A three-word brief for the backdrop artist.
  final String mood;
}
