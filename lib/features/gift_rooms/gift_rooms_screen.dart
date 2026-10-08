import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../widgets/counter_pill.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// The **gift room hall** — four pastel doors, one for each room.
///
/// Rules the child feels (all of them from the GDD):
/// * a room opens at a star milestone and the stars are **never spent**,
///   so progress can only ever grow;
/// * a room that is not reached yet is still shown, with the stars it wants —
///   it invites, it never punishes;
/// * no timers, no countdowns, no "come back tomorrow", no ads.
class GiftRoomsScreen extends ConsumerWidget {
  const GiftRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState progress = ref.watch(progressControllerProvider);
    final List<GiftRoomProgress> rooms = ref
        .read(progressControllerProvider.notifier)
        .giftRooms();

    final int openedTotal = GiftRoomEngine.openedCount(progress.openedGiftBoxes);

    return KidScreen(
      roomId: 'gifts',
      center: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CounterPill(
            icon: Icons.star_rounded,
            value: progress.stars,
            color: AppColors.yellow,
            size: 44,
          ),
          const SizedBox(width: 8),
          CounterPill(
            icon: Icons.card_giftcard_rounded,
            value: openedTotal,
            color: AppColors.pink,
            size: 44,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: rooms.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.albumColumns(context) > 2 ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          return EntranceItem(
            index: index,
            child: _RoomDoorCard(progress: rooms[index]),
          );
        },
      ),
    );
  }
}

/// One pastel door in the hall.
class _RoomDoorCard extends ConsumerStatefulWidget {
  const _RoomDoorCard({required this.progress});

  final GiftRoomProgress progress;

  @override
  ConsumerState<_RoomDoorCard> createState() => _RoomDoorCardState();
}

class _RoomDoorCardState extends ConsumerState<_RoomDoorCard> {
  /// Purely decorative nudge when a door is not open yet (never a penalty).
  bool _nudged = false;

  GiftRoom get room => widget.progress.room;

  Future<void> _open() async {
    final GiftRoomProgress progress = widget.progress;

    if (!progress.unlocked) {
      // Gentle: a soft sound and a tiny wobble. No dialog, no scolding.
      await SoundHelper.pop();
      if (!mounted) return;
      setState(() => _nudged = true);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() => _nudged = false);
      return;
    }

    await SoundHelper.tap();
    if (!mounted) return;
    context.go(AppRoutes.giftRoomPath(room.id));
  }

  @override
  Widget build(BuildContext context) {
    final GiftRoomProgress progress = widget.progress;
    final bool calm = MotionPolicy.of(context, ref).reduceMotion;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      transform: Matrix4.translationValues(_nudged && !calm ? 6 : 0, 0, 0),
      child: GestureDetector(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[room.washTop, room.washBottom],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              if (progress.hasReadyGift && !calm)
                IdleBreathe(
                  scale: 1.10,
                  child: _RoomBadge(room: room, size: 74),
                )
              else
                _RoomBadge(room: room, size: 74),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        // Filled dots = boxes already opened in this room.
                        for (int i = 0; i < progress.totalBoxes; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              i < progress.openedCount
                                  ? Icons.card_giftcard_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: i < progress.openedCount
                                  ? room.accent
                                  : AppColors.locked,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        if (progress.unlocked)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 26,
                            color: room.accent,
                          )
                        else ...<Widget>[
                          CounterPill(
                            icon: Icons.star_rounded,
                            value: room.starsRequired,
                            color: AppColors.yellow,
                            size: 34,
                          ),
                          const SizedBox(width: 6),
                          if (progress.starsToGo > 0)
                            CounterPill(
                              icon: Icons.arrow_forward_rounded,
                              value: progress.starsToGo,
                              color: AppColors.lavender,
                              size: 34,
                            ),
                        ],
                        if (room.maxBadgesRequired > 0) ...<Widget>[
                          const Spacer(),
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 24,
                            color: progress.badges >= room.maxBadgesRequired
                                ? AppColors.mint
                                : AppColors.locked,
                          ),
                          Text(
                            '${progress.badges}/${room.maxBadgesRequired}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The round pastel icon of a room.
class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.room, required this.size});

  final GiftRoom room;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.92),
        border: Border.all(color: room.accent, width: 3),
      ),
      child: Icon(room.icon, size: size * 0.52, color: room.accent),
    );
  }
}
