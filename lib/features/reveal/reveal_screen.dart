import 'dart:async';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/animations/celebration.dart';
import '../../core/animations/entrances.dart';
import '../../core/animations/motion_policy.dart';
import '../../core/animations/motion_tokens.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_helper.dart';
import '../../core/audio/sound_helper.dart';
import '../../data/models/character_model.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../core/achievements/achievement.dart';
import '../../data/repositories/design_saver.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';

/// Reveal — the ten-second celebration.
///
/// Choreography (all of it decorative):
///   0.0 s  the finished design appears
///   0.4 s  a soft glow starts breathing around it
///   0.6 s  confetti bursts
///   0.9 s  three stars pop in one after another
///   ~1 s   the "saved" badge appears — **when the file write actually
///          finishes**, not on a timer
///
/// The save itself is deliberately independent of all of the above: it starts
/// on the very first frame, keeps running if the child leaves, and the buttons
/// are never disabled while things animate.
class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> {
  /// Only wraps the design card, so the captured PNG is always clean.
  final ScreenshotController _shot = ScreenshotController();

  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  final List<Timer> _timers = <Timer>[];

  GalleryItem? _item;
  bool _saved = false;
  List<Achievement> _newBadges = const <Achievement>[];
  bool _captureRunning = false;
  int _captureAttempts = 0;

  @override
  void initState() {
    super.initState();

    final List<GalleryItem> gallery =
        ref.read(progressControllerProvider).gallery;
    _item = gallery.isEmpty ? null : gallery.first;

    // Celebrate right away (audio never waits for animation frames).
    unawaited(SoundHelper.victory());
    unawaited(SoundHelper.applause());
    FeedbackHelper.celebrate();

    // 1) Save first, decorate later: kicks off on the very first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_saveDesign());
    });

    // 2) Decorative beats only.
    _timers.add(Timer(MotionTokens.confettiBegin, _burstConfetti));
    _timers.add(
      Timer(MotionTokens.starsBegin, () {
        if (!mounted) return;
        unawaited(SoundHelper.success());
      }),
    );
  }

  @override
  void dispose() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    _confetti.dispose();
    super.dispose();
  }

  // --- Saving (independent from the celebration) ---------------------------

  Future<void> _saveDesign({bool manual = false}) async {
    if (_captureRunning) return;

    final GalleryItem? item = _item ?? _latestItem();
    if (item == null) return;

    // Read the saver BEFORE the first await. DesignSaver touches only
    // long-lived singletons (no provider state, no BuildContext), so the
    // write survives the screen being disposed mid-capture.
    final DesignSaver saver = ref.read(designSaverProvider);

    _captureRunning = true;
    try {
      final DesignSaveResult result = await saver.save(
        designId: item.id,
        capture: () => _shot.capture(pixelRatio: 2.5),
      );

      if (!result.isSaved) {
        _scheduleRetry(manual: manual);
        return;
      }

      // Cosmetic only, and deliberately defended: if the provider scope is
      // already gone this call may throw, but the durable map (written inside
      // DesignSaver) means the album still finds the image on its next load.
      try {
        ref
            .read(progressControllerProvider.notifier)
            .attachImage(item.id, result.fileName);
      } catch (_) {
        // Nothing to mirror in memory — storage already has the truth.
      }

      if (mounted) {
        setState(() => _saved = true);
        unawaited(SoundHelper.sparkle());
        if (manual) _toast(Icons.check_rounded);
        try {
          _celebrateAchievements();
        } catch (_) {
          // Badges are re-evaluated on the next reveal / star-wall visit.
        }
      }
    } finally {
      _captureRunning = false;
    }
  }

  /// Badges earned by this round. Gentle, one at a time, and never a dialog
  /// the child has to dismiss.
  void _celebrateAchievements() {
    final List<Achievement> fresh = ref
        .read(progressControllerProvider.notifier)
        .claimAchievements(
          ref.read(progressControllerProvider.notifier).pendingAchievements(),
        );
    if (fresh.isEmpty || !mounted) return;

    setState(() => _newBadges = fresh);
    unawaited(SoundHelper.gift());
    for (int i = 0; i < fresh.length; i++) {
      _timers.add(
        Timer(Duration(milliseconds: 700 * i), () {
          if (!mounted) return;
          unawaited(SoundHelper.sparkle());
        }),
      );
    }
  }

  void _scheduleRetry({required bool manual}) {
    if (_captureAttempts >= 3) {
      if (manual && mounted) _toast(Icons.error_rounded);
      return;
    }
    _captureAttempts++;
    _timers.add(
      Timer(Duration(milliseconds: 350 * _captureAttempts), () {
        // The album screen can also repair a missing image later, so a total
        // failure here still never loses the design (it is stored as a recipe).
        unawaited(_saveDesign(manual: manual));
      }),
    );
  }

  GalleryItem? _latestItem() {
    final List<GalleryItem> gallery =
        ref.read(progressControllerProvider).gallery;
    return gallery.isEmpty ? null : gallery.first;
  }

  void _burstConfetti() {
    if (!mounted) return;
    if (MotionPolicy.of(context, ref).reduceMotion) return;
    _confetti.play();
  }

  void _toast(IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.white,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        content: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.mint),
            const SizedBox(width: 10),
            const Icon(Icons.photo_library_rounded, color: AppColors.pink),
          ],
        ),
      ),
    );
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final CharacterModel character = ref.watch(selectedCharacterProvider);
    final GalleryItem? item = _item ?? _latestItem();
    final MotionPolicy policy = MotionPolicy.of(context, ref);

    return KidScreen(
      roomId: 'reveal',
      center: const Text(
        'Great job!',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      sparkles: false,
      body: Stack(
        children: <Widget>[
          if (!policy.reduceMotion)
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 22,
                  emissionFrequency: 0.03,
                  gravity: 0.18,
                  colors: AppColors.rainbow,
                  shouldLoop: false,
                ),
              ),
            ),
          Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    // 1) The design, wrapped in its glow (2).
                    Positioned.fill(
                      child: PopIn(
                        child: GlowHalo(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: AppColors.white,
                                width: 3,
                              ),
                            ),
                            child: Screenshot(
                              controller: _shot,
                              child: DesignPreview(
                                shape: NailShape.fromId(item?.shapeId),
                                colorOption: item == null
                                    ? null
                                    : NailCatalog.colorById(item.colorId),
                                pattern: item == null
                                    ? null
                                    : NailCatalog.patternById(item.patternId),
                                sticker: item == null
                                    ? null
                                    : NailCatalog.stickerById(item.stickerId),
                                ring: item == null
                                    ? null
                                    : NailCatalog.ringById(item.ringId),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: EntranceItem(
                        child: CharacterFace(
                          character: character,
                          size: 80,
                          mood: FaceMood.amazed,
                        ),
                      ),
                    ),
                    // Real save status, not a scripted delay.
                    Positioned(
                      right: 10,
                      top: 10,
                      child: SavedBadge(visible: _saved),
                    ),
                    // Badges earned this round, popping in one after another.
                    if (_newBadges.isNotEmpty)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        right: 10,
                        child: Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            for (int i = 0; i < _newBadges.length; i++)
                              PopIn(
                                delay: Duration(milliseconds: 260 * i),
                                child: _BadgeChip(badge: _newBadges[i]),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 3) Stars pop in one after the other.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < MotionTokens.starCount; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: StarPop(index: i),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              EntranceItem(
                index: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CounterPill(
                      icon: Icons.star_rounded,
                      value: ref.watch(
                        progressControllerProvider.select((p) => p.stars),
                      ),
                      color: AppColors.yellow,
                      size: 42,
                    ),
                    const SizedBox(width: 10),
                    CounterPill(
                      icon: Icons.monetization_on_rounded,
                      value: ref.watch(
                        progressControllerProvider.select((p) => p.coins),
                      ),
                      color: AppColors.mint,
                      size: 42,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Buttons stay tappable the whole time (never disabled by an
              // animation or by the capture running in the background).
              EntranceItem(
                index: 2,
                child: BigButton(
                  icon: _saved ? Icons.check_rounded : Icons.save_rounded,
                  label: 'Save',
                  color: AppColors.yellow,
                  height: 78,
                  onPressed: () => unawaited(_saveDesign(manual: true)),
                ),
              ),
              const SizedBox(height: 10),
              EntranceItem(
                index: 3,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: BigButton(
                        icon: Icons.replay_rounded,
                        label: 'Again',
                        color: AppColors.pink,
                        height: 74,
                        onPressed: () => context.go(AppRoutes.characters),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BigButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Album',
                        color: AppColors.mint,
                        height: 74,
                        onPressed: () => context.go(AppRoutes.gallery),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              EntranceItem(
                index: 4,
                child: BigButton(
                  icon: Icons.home_rounded,
                  height: 68,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tiny earned-badge chip (icon + name), shown on the reveal screen.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (badge.color ?? AppColors.yellow),
          width: 2.5,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            badge.icon,
            size: 22,
            color: badge.color ?? AppColors.yellow,
          ),
          const SizedBox(width: 6),
          Text(
            badge.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
