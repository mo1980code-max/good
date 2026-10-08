import '../core/constants/assets.dart';

/// Every optional art file the game will use **if it exists on disk**.
///
/// This is the only place that knows art file names. Screens never build a
/// path by hand, so replacing procedural art with real art is a pure file
/// drop — zero code changes, zero risk to gameplay logic.
abstract final class ArtSlots {
  // --- Characters (square portraits, 1024x1024 recommended) ---------------

  static String characterPortrait(String id) => switch (id) {
        'kitty' => Assets.kitty,
        'bunny' => Assets.bunny,
        'panda' => Assets.panda,
        'unicorn' => Assets.unicorn,
        'fairy' => Assets.fairy,
        'kid' => Assets.kid,
        _ => Assets.kitty,
      };

  static const List<String> characterIds = <String>[
    'kitty',
    'bunny',
    'panda',
    'unicorn',
    'fairy',
    'kid',
  ];

  // --- Rooms (16:9 backdrops, 1920x1080 recommended) ----------------------

  static String roomBackdrop(String roomId) =>
      'assets/images/rooms/$roomId.png';

  static const List<String> roomIds = <String>[
    'splash',
    'home',
    'characters',
    'spa',
    'studio',
    'reveal',
    'gallery',
    'rewards',
    'settings',
    'gifts',
    'gift_blush',
    'gift_mint',
    'gift_sky',
    'gift_sunny',
  ];

  // --- Big props ----------------------------------------------------------

  /// Optional illustrated hand for the spa scene. When absent the animated
  /// procedural hand is used (which is the current default).
  static const String spaHand = 'assets/images/hand/spa_hand.png';

  /// Optional album frame drawn around finished designs.
  static const String albumFrame = 'assets/images/ui/album_frame.png';

  /// Optional confetti / sparkle sheet for the reveal.
  static const String revealBurst = 'assets/images/ui/reveal_burst.png';
}
