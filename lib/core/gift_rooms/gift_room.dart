import 'package:flutter/widgets.dart';

/// What a gift box hands over. Four kinds only — deliberately few, so a child
/// can tell at a glance what they got.
enum GiftPrizeKind {
  /// Sparkly coins (spent in the studio).
  coins,

  /// A surprise-box key (spent in the gifts screen).
  keys,

  /// Stars. They only ever add up — they are never spent.
  stars,

  /// A brand-new studio item (a polish colour or a ring charm).
  item,
}

/// One prize. Plain value object — the UI, the engine and the tests all read
/// the same const data.
@immutable
class GiftPrize {
  const GiftPrize({
    required this.kind,
    required this.label,
    required this.icon,
    required this.color,
    this.amount = 0,
    this.itemId,
  });

  final GiftPrizeKind kind;

  /// Short, decorative name (never required reading).
  final String label;

  final IconData icon;
  final Color color;

  /// Coins / keys / stars handed over. Ignored for [GiftPrizeKind.item].
  final int amount;

  /// Unlocked studio item (only for [GiftPrizeKind.item]).
  final String? itemId;

  bool get isItem => kind == GiftPrizeKind.item && itemId != null;
}

/// One surprise box inside a room.
///
/// The prize is **fixed data**, not a random roll. That is a feature: a fixed
/// prize can never be handed out twice, never needs a seed, and can be fully
/// tested without running the UI.
@immutable
class GiftBox {
  const GiftBox({
    required this.id,
    required this.roomId,
    required this.prize,
    this.badgesRequired = 0,
  });

  /// Global, stable id (also the id stored in the save file).
  final String id;

  final String roomId;
  final GiftPrize prize;

  /// Badges needed before this box may be opened (0 = always available once
  /// the room is unlocked). This is the link between achievements and gifts.
  final int badgesRequired;

  bool get needsBadges => badgesRequired > 0;
}

/// One pastel gift room.
@immutable
class GiftRoom {
  const GiftRoom({
    required this.id,
    required this.name,
    required this.starsRequired,
    required this.accent,
    required this.washTop,
    required this.washBottom,
    required this.icon,
    required this.boxes,
  });

  final String id;
  final String name;

  /// Stars needed to step in. Stars are **never spent** — they are simply a
  /// milestone, so nothing the child earned can ever be taken away again.
  final int starsRequired;

  final Color accent;
  final Color washTop;
  final Color washBottom;
  final IconData icon;
  final List<GiftBox> boxes;

  int get boxCount => boxes.length;

  /// Highest badge requirement in the room (used for the room card).
  int get maxBadgesRequired {
    int max = 0;
    for (final GiftBox box in boxes) {
      if (box.badgesRequired > max) max = box.badgesRequired;
    }
    return max;
  }
}

/// The four gift rooms and their twelve boxes. Const, pure, no randomness.
abstract final class GiftRoomCatalog {
  static const GiftRoom blush = GiftRoom(
    id: 'blush',
    name: 'Blush Room',
    starsRequired: 0,
    accent: Color(0xFFFF8FC2),
    washTop: Color(0xFFFFE3F1),
    washBottom: Color(0xFFFFF7FB),
    icon: Icons.cake_rounded,
    boxes: <GiftBox>[
      GiftBox(
        id: 'blush.box1',
        roomId: 'blush',
        prize: GiftPrize(
          kind: GiftPrizeKind.coins,
          label: 'Coins',
          icon: Icons.monetization_on_rounded,
          color: Color(0xFFFFC94D),
          amount: 40,
        ),
      ),
      GiftBox(
        id: 'blush.box2',
        roomId: 'blush',
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Rose Glow',
          icon: Icons.palette_rounded,
          color: Color(0xFFFF8FC2),
          itemId: 'rose_glow',
        ),
      ),
      GiftBox(
        id: 'blush.box3',
        roomId: 'blush',
        badgesRequired: 1,
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Heart Charm',
          icon: Icons.favorite_rounded,
          color: Color(0xFFFF5DA2),
          itemId: 'charm_heart',
        ),
      ),
    ],
  );

  static const GiftRoom mint = GiftRoom(
    id: 'mint',
    name: 'Mint Room',
    starsRequired: 12,
    accent: Color(0xFF48D6C9),
    washTop: Color(0xFFD9FBF6),
    washBottom: Color(0xFFF2FFFD),
    icon: Icons.icecream_rounded,
    boxes: <GiftBox>[
      GiftBox(
        id: 'mint.box1',
        roomId: 'mint',
        prize: GiftPrize(
          kind: GiftPrizeKind.keys,
          label: 'Key',
          icon: Icons.vpn_key_rounded,
          color: Color(0xFFFFB59E),
          amount: 1,
        ),
      ),
      GiftBox(
        id: 'mint.box2',
        roomId: 'mint',
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Mint Dream',
          icon: Icons.palette_rounded,
          color: Color(0xFF7FE6D6),
          itemId: 'mint_dream',
        ),
      ),
      GiftBox(
        id: 'mint.box3',
        roomId: 'mint',
        badgesRequired: 2,
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Star Charm',
          icon: Icons.star_rounded,
          color: Color(0xFFFFD95A),
          itemId: 'charm_star',
        ),
      ),
    ],
  );

  static const GiftRoom sky = GiftRoom(
    id: 'sky',
    name: 'Sky Room',
    starsRequired: 30,
    accent: Color(0xFF71C9FF),
    washTop: Color(0xFFDFF1FF),
    washBottom: Color(0xFFF6FBFF),
    icon: Icons.cloud_rounded,
    boxes: <GiftBox>[
      GiftBox(
        id: 'sky.box1',
        roomId: 'sky',
        prize: GiftPrize(
          kind: GiftPrizeKind.coins,
          label: 'Coins',
          icon: Icons.monetization_on_rounded,
          color: Color(0xFFFFC94D),
          amount: 60,
        ),
      ),
      GiftBox(
        id: 'sky.box2',
        roomId: 'sky',
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Sky Wish',
          icon: Icons.palette_rounded,
          color: Color(0xFF9BD8FF),
          itemId: 'sky_wish',
        ),
      ),
      GiftBox(
        id: 'sky.box3',
        roomId: 'sky',
        badgesRequired: 3,
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Gem Charm',
          icon: Icons.hexagon_rounded,
          color: Color(0xFF9B5CFF),
          itemId: 'charm_gem',
        ),
      ),
    ],
  );

  static const GiftRoom sunny = GiftRoom(
    id: 'sunny',
    name: 'Sunny Room',
    starsRequired: 60,
    accent: Color(0xFFFFD95A),
    washTop: Color(0xFFFFF3D6),
    washBottom: Color(0xFFFFFCF2),
    icon: Icons.wb_sunny_rounded,
    boxes: <GiftBox>[
      GiftBox(
        id: 'sunny.box1',
        roomId: 'sunny',
        prize: GiftPrize(
          kind: GiftPrizeKind.stars,
          label: 'Stars',
          icon: Icons.star_rounded,
          color: Color(0xFFFFD95A),
          amount: 3,
        ),
      ),
      GiftBox(
        id: 'sunny.box2',
        roomId: 'sunny',
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Sunny Honey',
          icon: Icons.palette_rounded,
          color: Color(0xFFFFC46B),
          itemId: 'sunny_honey',
        ),
      ),
      GiftBox(
        id: 'sunny.box3',
        roomId: 'sunny',
        badgesRequired: 4,
        prize: GiftPrize(
          kind: GiftPrizeKind.item,
          label: 'Butterfly Charm',
          icon: Icons.filter_vintage,
          color: Color(0xFFFF8A7A),
          itemId: 'charm_butterfly',
        ),
      ),
    ],
  );

  static const List<GiftRoom> all = <GiftRoom>[blush, mint, sky, sunny];

  static GiftRoom? byId(String? id) {
    for (final GiftRoom room in all) {
      if (room.id == id) return room;
    }
    return null;
  }

  static GiftBox? boxById(String? id) {
    for (final GiftRoom room in all) {
      for (final GiftBox box in room.boxes) {
        if (box.id == id) return box;
      }
    }
    return null;
  }

  static List<GiftBox> get everyBox {
    return <GiftBox>[
      for (final GiftRoom room in all) ...room.boxes,
    ];
  }

  static int get boxCount => everyBox.length;
}
