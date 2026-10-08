import 'dart:async';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_helper.dart';
import '../../core/audio/sound_helper.dart';
import '../../data/models/character_model.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../features/game/game_providers.dart';
import '../../features/game/progress_controller.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';

/// Reveal — the ten-second celebration: confetti, applause, three stars,
/// and the finished design is captured automatically into the album.
class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  final ScreenshotController _shot = ScreenshotController();

  bool _autoSaved = false;
  bool _busy = false;
  GalleryItem? _item;

  @override
  void initState() {
    super.initState();

    _confetti.play();
    unawaited(SoundHelper.applause());
    unawaited(SoundHelper.victory());
    FeedbackHelper.celebrate();

    final List<GalleryItem> gallery =
        ref.read(progressControllerProvider).gallery;
    _item = gallery.isEmpty ? null : gallery.first;

    // The album entry is written even if the child never taps "save".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_autoSave());
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    if (_autoSaved) return;
    _autoSaved = true;

    // Let the entrance animation settle so the capture is clean.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _captureAndStore(announce: false);
  }

  /// Captures the design card and stores the PNG on the device.
  Future<void> _captureAndStore({required bool announce}) async {
    final GalleryItem? item = _item ?? _firstItem();
    if (item == null) return;

    if (_busy) return;
    _busy = true;
    if (announce) setState(() {});

    try {
      final Uint8List? bytes = await _shot.capture(pixelRatio: 2.5);
      if (bytes == null) return;

      final GalleryRepository repository = ref.read(galleryRepositoryProvider);
      final String? fileName = await repository.saveDesignImage(
        bytes,
        designId: item.id,
      );

      ref
          .read(progressControllerProvider.notifier)
          .attachImage(item.id, fileName);

      if (announce && mounted) {
        SoundHelper.sparkle();
        _toast(fileName != null ? Icons.check_rounded : Icons.error_rounded);
      }
    } finally {
      _busy = false;
      if (mounted && announce) setState(() {});
    }
  }

  GalleryItem? _firstItem() {
    final List<GalleryItem> gallery =
        ref.read(progressControllerProvider).gallery;
    return gallery.isEmpty ? null : gallery.first;
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

  @override
  Widget build(BuildContext context) {
    final CharacterModel character = ref.watch(selectedCharacterProvider);
    final GalleryItem? item = _item ?? _firstItem();

    return KidScreen(
      roomId: 'reveal',
      center: const Text(
        'Great job!',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      sparkles: false,
      body: Stack(
        children: <Widget>[
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
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(34),
                          border:
                              Border.all(color: AppColors.white, width: 3),
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
                    Positioned(
                      left: 6,
                      top: 6,
                      child: CharacterFace(
                        character: character,
                        size: 80,
                        mood: FaceMood.amazed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const _StarsRow(),
              const SizedBox(height: 10),
              Row(
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
              const SizedBox(height: 12),
              BigButton(
                icon: _busy ? Icons.hourglass_top_rounded : Icons.save_rounded,
                label: 'Save',
                color: AppColors.yellow,
                height: 80,
                enabled: !_busy,
                onPressed: () => _captureAndStore(announce: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: BigButton(
                      icon: Icons.replay_rounded,
                      label: 'Again',
                      color: AppColors.pink,
                      height: 76,
                      onPressed: () => context.go(AppRoutes.characters),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BigButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Album',
                      color: AppColors.mint,
                      height: 76,
                      onPressed: () => context.go(AppRoutes.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BigButton(
                icon: Icons.home_rounded,
                height: 70,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Three stars that pop in one after the other.
class _StarsRow extends StatelessWidget {
  const _StarsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.yellow,
              size: 46,
            )
                .animate()
                .fadeIn(delay: (200 * i).ms, duration: 250.ms)
                .scale(
                  delay: (200 * i).ms,
                  duration: 500.ms,
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
          ),
      ],
    );
  }
}
