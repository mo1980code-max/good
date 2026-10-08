import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/celebration.dart';
import '../../core/animations/entrances.dart';
import '../../core/animations/motion_policy.dart';
import '../../core/audio/sound_helper.dart';
import '../../core/gift_rooms/gift_room.dart';
import '../../core/gift_rooms/gift_room_engine.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/progress_state.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/kid_screen.dart';

/// One gift room: a pastel wash, three surprise boxes, and nothing to lose.
///
/// * opening a box is a **single, recorded** event — a box never pays twice;
/// * a box that still needs badges shows how many, and tapping it only plays a
///   soft sound (never a scolding, never a currency loss);
/// * every animation here is the shared motion engine, so "reduce motion"
///   turns the wobbles off automatically.
class GiftRoomScreen extends ConsumerStatefulWidget {
  const GiftRoomScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<GiftRoomScreen> createState() => _GiftRoomScreenState();
}

class _GiftRoomScreenState extends ConsumerState<GiftRoomScreen> {
  GiftPrize? _lastPrize;
  String? _lastBoxId;
  String? _hintBoxId;

  GiftRoom get _room =>
      GiftRoomCatalog.byId(widget.roomId) ?? GiftRoomCatalog.blush;

  @override
  Widget build(BuildContext context) {
    final ProgressState progress = ref.watch(progressControllerProvider);
    final GiftRoom room = _room;

    // The room is read from the catalog, so a bad id can never crash a screen.
    final int badges = progress.achievements.length;
    final int openedCount = room.boxes
        .where((GiftBox box) => progress.openedGiftBoxes.contains(box.id))
        .length;

    return KidScreen(
      roomId: 'gift_${room.id}',
      onBack: () => context.go(AppRoutes.gifts),
      center: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CounterPill(
            icon: Icons.star_rounded,
            value: progress.stars,
            color: AppColors.yellow,
            size: 42,
          ),
          const SizedBox(width: 8),
          CounterPill(
            icon: room.icon,
            value: openedCount,
            color: room.accent,
            size: 42,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: EntranceItem(
              child: _RoomPanel(
                room: room,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    for (int i = 0; i < room.boxes.length; i++)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _BoxTile(
                            box: room.boxes[i],
                            room: room,
                            state: GiftRoomEngine.stateOf(
                              box: room.boxes[i],
                              stars: progress.stars,
                              badges: badges,
                              openedBoxes: progress.openedGiftBoxes,
                            ),
                            badges: badges,
                            isLastOpened: _lastBoxId == room.boxes[i].id,
                            hinting: _hintBoxId == room.boxes[i].id,
                            onTap: () => _tapBox(room.boxes[i], progress),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: _PrizeStage(prize: _lastPrize, room: room),
            ),
          ),
          const SizedBox(height: 8),
          BigButton(
            icon: Icons.home_rounded,
            height: 68,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }

  Future<void> _tapBox(GiftBox box, ProgressState progress) async {
    final GiftBoxState state = GiftRoomEngine.stateOf(
      box: box,
      stars: progress.stars,
      badges: progress.achievements.length,
      openedBoxes: progress.openedGiftBoxes,
    );

    switch (state) {
      case GiftBoxState.opened:
        // Nothing more to take — just a friendly tap sound.
        await SoundHelper.tap();
        return;

      case GiftBoxState.needsBadges:
      case GiftBoxState.roomLocked:
        await SoundHelper.pop();
        if (!mounted) return;
        setState(() => _hintBoxId = box.id);
        // One-shot hint: the tile always settles back where it was.
        Future<void>.delayed(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _hintBoxId = null);
        });
        return;

      case GiftBoxState.ready:
        // One call, one recorded gift. A second tap in the same frame would
        // find the box already opened and simply do nothing.
        final GiftPrize? prize =
            ref.read(progressControllerProvider.notifier).openGiftBox(box.id);
        if (prize == null) {
          await SoundHelper.pop();
          return;
        }
        await SoundHelper.gift();
        if (!mounted) return;
        setState(() {
          _lastPrize = prize;
          _lastBoxId = box.id;
          _hintBoxId = null;
        });
        return;
    }
  }
}

/// The pastel room itself: one soft wash, rounded, with the boxes inside.
class _RoomPanel extends ConsumerWidget {
  const _RoomPanel({required this.room, required this.child});

  final GiftRoom room;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[room.washTop, room.washBottom],
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A single surprise box, in all four of its states.
class _BoxTile extends ConsumerStatefulWidget {
  const _BoxTile({
    required this.box,
    required this.room,
    required this.state,
    required this.badges,
    required this.isLastOpened,
    required this.hinting,
    required this.onTap,
  });

  final GiftBox box;
  final GiftRoom room;
  final GiftBoxState state;
  final int badges;
  final bool isLastOpened;
  final bool hinting;
  final VoidCallback onTap;

  @override
  ConsumerState<_BoxTile> createState() => _BoxTileState();
}

class _BoxTileState extends ConsumerState<_BoxTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool calm = MotionPolicy.of(context, ref).reduceMotion;
    final bool opened = widget.state == GiftBoxState.opened;
    final bool ready = widget.state == GiftBoxState.ready;
    final bool waiting = widget.state == GiftBoxState.needsBadges;

    final Widget icon = Icon(
      opened ? widget.box.prize.icon : Icons.card_giftcard_rounded,
      size: 54,
      color: opened
          ? widget.box.prize.color
          : (ready ? widget.room.accent : AppColors.locked),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        transform: Matrix4.translationValues(
          widget.hinting && !calm ? 5 : 0,
          0,
          0,
        ),
        transformAlignment: Alignment.center,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 130),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: opened ? 0.70 : 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: ready ? widget.room.accent : AppColors.white,
                width: ready ? 3.5 : 3,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (ready && !calm)
                  BoxWiggle(child: icon)
                else if (widget.isLastOpened && !calm)
                  PopIn(child: icon)
                else
                  icon,
                const SizedBox(height: 6),
                if (opened)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: AppColors.mint,
                  )
                else if (waiting)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: AppColors.lavender,
                      ),
                      Text(
                        '${widget.badges}/${widget.box.badgesRequired}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textSoft,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the prize appears, gently. Nothing at all before the first gift.
class _PrizeStage extends ConsumerWidget {
  const _PrizeStage({required this.prize, required this.room});

  final GiftPrize? prize;
  final GiftRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GiftPrize? prize = this.prize;
    if (prize == null) {
      return Opacity(
        opacity: 0.5,
        child: Icon(
          room.icon,
          size: 62,
          color: room.accent,
        ),
      );
    }

    final bool calm = MotionPolicy.of(context, ref).reduceMotion;

    final Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: prize.color, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(prize.icon, size: 46, color: prize.color),
          const SizedBox(width: 10),
          Text(
            prize.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDeep,
            ),
          ),
        ],
      ),
    );

    if (calm) return card;
    return PopIn(
      key: ValueKey<String>('${prize.label}-${prize.amount}-${prize.itemId}'),
      child: GlowHalo(color: prize.color, child: card),
    );
  }
}
