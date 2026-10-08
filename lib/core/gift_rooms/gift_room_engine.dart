import 'package:flutter/foundation.dart';

import 'gift_room.dart';

/// What a child can do with one box *right now*. Never a punishment — a box
/// that is not ready yet simply says "later", and nothing is ever taken away.
enum GiftBoxState {
  /// Already opened. The prize is recorded for good.
  opened,

  /// Tap it and it opens.
  ready,

  /// The room is unlocked, but a few more badges are needed.
  needsBadges,

  /// The room itself still needs more stars.
  roomLocked,
}

/// A room plus the child's live progress in it — a plain value object for the
/// UI (and for the tests).
@immutable
class GiftRoomProgress {
  const GiftRoomProgress({
    required this.room,
    required this.stars,
    required this.badges,
    required this.openedBoxes,
  });

  final GiftRoom room;
  final int stars;
  final int badges;

  /// Box ids already opened (the global set, filtered per room inside).
  final Set<String> openedBoxes;

  bool get unlocked => stars >= room.starsRequired;

  int get openedCount => room.boxes
      .where((GiftBox box) => openedBoxes.contains(box.id))
      .length;

  int get totalBoxes => room.boxCount;

  bool get complete => openedCount >= totalBoxes;

  int get starsToGo {
    final int missing = room.starsRequired - stars;
    return missing > 0 ? missing : 0;
  }

  double get starFraction {
    if (room.starsRequired <= 0) return 1;
    return (stars / room.starsRequired).clamp(0, 1).toDouble();
  }

  bool get hasReadyGift => room.boxes.any(
        (GiftBox box) => GiftRoomEngine.stateOf(
          box: box,
          stars: stars,
          badges: badges,
          openedBoxes: openedBoxes,
        ) ==
            GiftBoxState.ready,
      );
}

/// Decides what is open, what is ready and what has to wait.
///
/// **Pure by design** — no widgets, no storage, no clock, no randomness. The
/// same numbers always produce the same answers, which is exactly what makes
/// "a gift is never handed out twice" testable without running the game.
abstract final class GiftRoomEngine {
  static bool isUnlocked(GiftRoom room, {required int stars}) =>
      stars >= room.starsRequired;

  static GiftBoxState stateOf({
    required GiftBox box,
    required int stars,
    required int badges,
    required Set<String> openedBoxes,
  }) {
    // Opened wins over everything: once the prize is recorded, the box can
    // never produce a second gift, whatever else changes later.
    if (openedBoxes.contains(box.id)) return GiftBoxState.opened;

    final GiftRoom? room = GiftRoomCatalog.byId(box.roomId);
    if (room == null || !isUnlocked(room, stars: stars)) {
      return GiftBoxState.roomLocked;
    }
    if (badges < box.badgesRequired) return GiftBoxState.needsBadges;
    return GiftBoxState.ready;
  }

  static bool canOpen({
    required GiftBox box,
    required int stars,
    required int badges,
    required Set<String> openedBoxes,
  }) =>
      stateOf(
        box: box,
        stars: stars,
        badges: badges,
        openedBoxes: openedBoxes,
      ) ==
      GiftBoxState.ready;

  static List<GiftRoomProgress> snapshot({
    required int stars,
    required int badges,
    required Set<String> openedBoxes,
  }) {
    return <GiftRoomProgress>[
      for (final GiftRoom room in GiftRoomCatalog.all)
        GiftRoomProgress(
          room: room,
          stars: stars,
          badges: badges,
          openedBoxes: openedBoxes,
        ),
    ];
  }

  /// The next room the child has not reached yet (`null` = all unlocked).
  /// Used for a friendly "keep playing" hint — never for a countdown.
  static GiftRoom? nextRoom({required int stars}) {
    for (final GiftRoom room in GiftRoomCatalog.all) {
      if (!isUnlocked(room, stars: stars)) return room;
    }
    return null;
  }

  /// The first room with a box that can be opened right now, or `null`.
  static GiftRoom? roomWithReadyGift({
    required int stars,
    required int badges,
    required Set<String> openedBoxes,
  }) {
    for (final GiftRoom room in GiftRoomCatalog.all) {
      for (final GiftBox box in room.boxes) {
        if (canOpen(
          box: box,
          stars: stars,
          badges: badges,
          openedBoxes: openedBoxes,
        )) {
          return room;
        }
      }
    }
    return null;
  }

  static bool hasReadyGift({
    required int stars,
    required int badges,
    required Set<String> openedBoxes,
  }) =>
      roomWithReadyGift(
        stars: stars,
        badges: badges,
        openedBoxes: openedBoxes,
      ) !=
      null;

  /// How many **catalog** boxes are open. Ids that are not in the catalog
  /// (an old save, a renamed box) are ignored, so stale data can never make
  /// the count — or a reward — look bigger than it is.
  static int openedCount(Set<String> openedBoxes) {
    int count = 0;
    for (final GiftBox box in GiftRoomCatalog.everyBox) {
      if (openedBoxes.contains(box.id)) count++;
    }
    return count;
  }

  static int get totalBoxes => GiftRoomCatalog.boxCount;

  /// True when every single box has been opened (the end of the gift trail).
  static bool allOpened(Set<String> openedBoxes) =>
      openedCount(openedBoxes) >= totalBoxes;
}
