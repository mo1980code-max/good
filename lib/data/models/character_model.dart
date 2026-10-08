import 'package:flutter/material.dart';

import '../../core/constants/assets.dart';

/// One cute spa mascot.
///
/// Every character keeps the *same* mini-games but a different feel
/// (motion + reaction sound), which multiplies replay value by six
/// without building new content — see GDD section 5.
@immutable
class CharacterModel {
  const CharacterModel({
    required this.id,
    required this.name,
    required this.asset,
    required this.accent,
    this.voiceId = 'soft',
    this.backdropAsset,
  });

  final String id;
  final String name;
  final String asset;
  final Color accent;

  /// Reaction sound set ("soft", "bright", "magic"...).
  final String voiceId;

  /// Optional little room, unlocked later with stars (Phase 2/3).
  final String? backdropAsset;

  static const List<CharacterModel> all = <CharacterModel>[
    CharacterModel(
      id: 'kitty',
      name: 'Kitty',
      asset: Assets.kitty,
      accent: Color(0xFFFF8BCB),
      voiceId: 'bright',
    ),
    CharacterModel(
      id: 'bunny',
      name: 'Bunny',
      asset: Assets.bunny,
      accent: Color(0xFFFFC86E),
      voiceId: 'bright',
    ),
    CharacterModel(
      id: 'panda',
      name: 'Panda',
      asset: Assets.panda,
      accent: Color(0xFF7DD3FC),
      voiceId: 'soft',
    ),
    CharacterModel(
      id: 'unicorn',
      name: 'Unicorn',
      asset: Assets.unicorn,
      accent: Color(0xFFB57BFF),
      voiceId: 'magic',
    ),
    CharacterModel(
      id: 'fairy',
      name: 'Fairy',
      asset: Assets.fairy,
      accent: Color(0xFF63E6D8),
      voiceId: 'magic',
    ),
    CharacterModel(
      id: 'kid',
      name: 'Kid',
      asset: Assets.kid,
      accent: Color(0xFFFF9C7A),
      voiceId: 'bright',
    ),
  ];

  /// Never throws: an unknown id falls back to the first character.
  static CharacterModel byId(String? id) {
    return all.firstWhere(
      (CharacterModel character) => character.id == id,
      orElse: () => all.first,
    );
  }
}
