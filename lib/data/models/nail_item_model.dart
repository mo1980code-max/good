import 'package:flutter/material.dart';

import '../../core/constants/assets.dart';

/// Nail shape. `radius` is used by the preview/hand painters.
enum NailShape {
  round('round', 'Round', 26),
  square('square', 'Square', 10),
  almond('almond', 'Almond', 999);

  const NailShape(this.id, this.label, this.radius);

  final String id;
  final String label;
  final double radius;

  static NailShape fromId(String? id) {
    return values.firstWhere(
      (NailShape shape) => shape.id == id,
      orElse: () => NailShape.round,
    );
  }
}

/// Length is independent from shape so a child can try short, salon and long
/// looks without changing the photographic hand itself.
enum NailLength {
  short('short', 'Short', 0.86),
  medium('medium', 'Medium', 1.0),
  long('long', 'Long', 1.30);

  const NailLength(this.id, this.label, this.factor);

  final String id;
  final String label;
  final double factor;

  static NailLength fromId(String? id) => values.firstWhere(
        (NailLength length) => length.id == id,
        orElse: () => NailLength.medium,
      );
}

/// A polish color. `price == 0` means "unlocked from the first run".
@immutable
class NailColorOption {
  const NailColorOption({
    required this.id,
    required this.label,
    required this.color,
    this.price = 0,
    this.giftRoom,
  });

  final String id;
  final String label;
  final Color color;
  final int price;

  /// Set when this item is **not for sale**: it is a gift-room prize, so it can
  /// only ever be obtained from a surprise box. A gift item is never bought
  /// with coins and never carries a price tag in the studio.
  final String? giftRoom;

  bool get giftOnly => giftRoom != null;
}

/// A polish pattern (glitter / stripes / ...).
@immutable
class NailPattern {
  const NailPattern({
    required this.id,
    required this.label,
    this.price = 0,
  });

  final String id;
  final String label;
  final int price;
}

/// A sticker or a ring.
@immutable
class DecorItem {
  const DecorItem({
    required this.id,
    required this.label,
    required this.asset,
    this.price = 0,
    this.giftRoom,
  });

  final String id;
  final String label;
  final String asset;
  final int price;

  /// See [NailColorOption.giftRoom] — gift-only items come from gift boxes.
  final String? giftRoom;

  bool get giftOnly => giftRoom != null;
}

/// All paintable content. Kept as plain const data so it is trivial to extend
/// (and to move into JSON later if the catalog grows).
abstract final class NailCatalog {
  // 3 shapes x 16 colors x 6 patterns x 12 stickers x 12 rings = 41,472 designs.
  // Four colours and four ring charms are gift-only (Phase 2.5): they show up
  // in the studio right away, but a gift box is what actually unlocks them.

  static const List<NailColorOption> colors = <NailColorOption>[
    NailColorOption(id: 'pink', label: 'Pink', color: Color(0xFFFF5DA2)),
    NailColorOption(id: 'lavender', label: 'Lavender', color: Color(0xFF9B5CFF)),
    NailColorOption(id: 'sky', label: 'Sky', color: Color(0xFF71C9FF)),
    NailColorOption(id: 'mint', label: 'Mint', color: Color(0xFF48D6C9)),
    NailColorOption(id: 'peach', label: 'Peach', color: Color(0xFFFF8A7A)),
    NailColorOption(id: 'yellow', label: 'Yellow', color: Color(0xFFFFD95A)),
    NailColorOption(id: 'turquoise', label: 'Turquoise', color: Color(0xFF35C4C0)),
    NailColorOption(id: 'blush', label: 'Blush', color: Color(0xFFFFB3D1)),
    NailColorOption(
      id: 'lilac',
      label: 'Lilac',
      color: Color(0xFFC9A7FF),
      price: 30,
    ),
    NailColorOption(
      id: 'pearl',
      label: 'Pearl',
      color: Color(0xFFF6F0FF),
      price: 40,
    ),
    NailColorOption(
      id: 'coral',
      label: 'Coral',
      color: Color(0xFFFF6F61),
      price: 50,
    ),
    NailColorOption(
      id: 'aqua',
      label: 'Aqua',
      color: Color(0xFF7FE1E1),
      price: 60,
    ),
    // --- Gift-only colours (Phase 2.5) — never sold, only unwrapped -------
    NailColorOption(
      id: 'rose_glow',
      label: 'Rose Glow',
      color: Color(0xFFFF9FCE),
      giftRoom: 'blush',
    ),
    NailColorOption(
      id: 'mint_dream',
      label: 'Mint Dream',
      color: Color(0xFF8FEADD),
      giftRoom: 'mint',
    ),
    NailColorOption(
      id: 'sky_wish',
      label: 'Sky Wish',
      color: Color(0xFFA9DCFF),
      giftRoom: 'sky',
    ),
    NailColorOption(
      id: 'sunny_honey',
      label: 'Sunny Honey',
      color: Color(0xFFFFC46B),
      giftRoom: 'sunny',
    ),
  ];

  static const List<NailPattern> patterns = <NailPattern>[
    NailPattern(id: 'plain', label: 'Plain'),
    NailPattern(id: 'glitter', label: 'Glitter'),
    NailPattern(id: 'stripes', label: 'Stripes'),
    NailPattern(id: 'stars', label: 'Stars'),
    NailPattern(id: 'rainbow', label: 'Rainbow', price: 45),
    NailPattern(id: 'french', label: 'French', price: 55),
  ];

  static const List<DecorItem> stickers = <DecorItem>[
    DecorItem(id: 'star', label: 'Star', asset: Assets.stickerStar),
    DecorItem(id: 'heart', label: 'Heart', asset: Assets.stickerHeart),
    DecorItem(id: 'flower', label: 'Flower', asset: Assets.stickerFlower),
    DecorItem(id: 'candy', label: 'Candy', asset: Assets.stickerCandy),
    DecorItem(id: 'rainbow', label: 'Rainbow', asset: Assets.stickerRainbow),
    DecorItem(id: 'sparkle', label: 'Sparkle', asset: Assets.stickerSparkle),
    DecorItem(id: 'cloud', label: 'Cloud', asset: Assets.stickerCloud),
    DecorItem(id: 'moon', label: 'Moon', asset: Assets.stickerMoon),
    DecorItem(id: 'cherry', label: 'Cherry', asset: Assets.stickerCherry, price: 35),
    DecorItem(id: 'bow', label: 'Bow', asset: Assets.stickerBow, price: 35),
    DecorItem(id: 'gem', label: 'Gem', asset: Assets.stickerGem, price: 45),
    DecorItem(
      id: 'butterfly',
      label: 'Butterfly',
      asset: Assets.stickerButterfly,
      price: 45,
    ),
  ];

  static const List<DecorItem> rings = <DecorItem>[
    DecorItem(id: 'ring_1', label: 'Ring 1', asset: Assets.ring1),
    DecorItem(id: 'ring_2', label: 'Ring 2', asset: Assets.ring2),
    DecorItem(id: 'ring_3', label: 'Ring 3', asset: Assets.ring3),
    DecorItem(id: 'ring_4', label: 'Ring 4', asset: Assets.ring4),
    DecorItem(id: 'ring_5', label: 'Ring 5', asset: Assets.ring5),
    DecorItem(id: 'ring_6', label: 'Ring 6', asset: Assets.ring6, price: 40),
    DecorItem(id: 'ring_7', label: 'Ring 7', asset: Assets.ring7, price: 50),
    DecorItem(id: 'ring_8', label: 'Ring 8', asset: Assets.ring8, price: 60),
    // --- Gift-only charms (Phase 2.5) — unwrapped, never bought ------------
    DecorItem(
      id: 'charm_heart',
      label: 'Heart Charm',
      asset: Assets.stickerHeart,
      giftRoom: 'blush',
    ),
    DecorItem(
      id: 'charm_star',
      label: 'Star Charm',
      asset: Assets.stickerStar,
      giftRoom: 'mint',
    ),
    DecorItem(
      id: 'charm_gem',
      label: 'Gem Charm',
      asset: Assets.stickerGem,
      giftRoom: 'sky',
    ),
    DecorItem(
      id: 'charm_butterfly',
      label: 'Butterfly Charm',
      asset: Assets.stickerButterfly,
      giftRoom: 'sunny',
    ),
  ];

  // --- Safe lookups (used by the gallery, which may hold old save data) ---

  static NailColorOption colorById(String? id) {
    return colors.firstWhere(
      (NailColorOption option) => option.id == id,
      orElse: () => colors.first,
    );
  }

  static NailPattern patternById(String? id) {
    return patterns.firstWhere(
      (NailPattern pattern) => pattern.id == id,
      orElse: () => patterns.first,
    );
  }

  static DecorItem stickerById(String? id) {
    return stickers.firstWhere(
      (DecorItem item) => item.id == id,
      orElse: () => stickers.first,
    );
  }

  static DecorItem ringById(String? id) {
    return rings.firstWhere(
      (DecorItem item) => item.id == id,
      orElse: () => rings.first,
    );
  }
}
