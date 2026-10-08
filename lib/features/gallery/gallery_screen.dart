import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/animations/entrances.dart';
import '../../core/audio/sound_helper.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_gate.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/repositories/design_saver.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// The album (or "star wall"): every finished design, newest first.
/// Deleting is possible — but only for a grown-up (long-press + gate).
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  /// How many cards may re-capture a missing picture in one visit. The rest
  /// are left alone on purpose: a phone should never be asked to render a
  /// whole album at once. Their designs are still there — only the picture is
  /// pending, and the next visit repairs a few more.
  static const int repairBudget = 6;

  @override
  void initState() {
    super.initState();
    // Once per session, after the first frame: drop `.tmp_*` leftovers from a
    // save that the app closing cut short, and give a picture back to every
    // design whose PNG really exists on disk (even if the index write was the
    // thing that got lost).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(progressControllerProvider.notifier).reconcileAlbumImages(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<GalleryItem> gallery =
        ref.watch(progressControllerProvider.select((p) => p.gallery));

    return KidScreen(
      roomId: 'gallery',
      center: CounterPill(
        icon: Icons.photo_library_rounded,
        value: gallery.length,
        color: AppColors.pink,
        size: 44,
      ),
      body: gallery.isEmpty
          ? const _EmptyAlbum()
          : GridView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: gallery.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.albumColumns(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.80,
              ),
              itemBuilder: (context, index) {
                return EntranceItem(
                  index: index,
                  child: _DesignCard(
                    item: gallery[index],
                    allowRepair: index < repairBudget,
                    // Staggered, so six captures never start in one frame.
                    repairDelayMs: 320 + (index % repairBudget) * 220,
                  ),
                );
              },
            ),
    );
  }
}

class _DesignCard extends ConsumerStatefulWidget {
  const _DesignCard({
    required this.item,
    this.allowRepair = false,
    this.repairDelayMs = 350,
  });

  final GalleryItem item;

  /// Set for the first cards: a design whose PNG is missing (capture failed on
  /// the reveal screen, or the app was closed mid-save) is re-captured here
  /// from its recipe — the album heals itself, nothing is ever lost.
  final bool allowRepair;

  /// Small head start per card so a visit cannot fire six captures at once.
  final int repairDelayMs;

  @override
  ConsumerState<_DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends ConsumerState<_DesignCard> {
  final ScreenshotController _repairShot = ScreenshotController();
  bool _requested = false;

  GalleryItem get item => widget.item;

  bool get _needsRepair => widget.allowRepair && item.imageFileName == null;

  @override
  Widget build(BuildContext context) {
    final bool repairing = _needsRepair;
    if (repairing && !_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _repair());
    }

    final Widget card = GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: DesignPreview(
          shape: NailShape.fromId(item.shapeId),
          nailLength: NailLength.fromId(item.nailLengthId),
          colorOption: NailCatalog.colorById(item.colorId),
          nailColors: <int, Color>{
            for (final MapEntry<int, String> entry in item.nailColors.entries)
              entry.key: NailCatalog.colorById(entry.value).color,
          },
          pattern: NailCatalog.patternById(item.patternId),
          sticker: NailCatalog.stickerById(item.stickerId),
          ring: NailCatalog.ringById(item.ringId),
          padding: 10,
        ),
      ),
    );

    return repairing
        ? Screenshot(controller: _repairShot, child: card)
        : card;
  }

  Future<void> _repair() async {
    if (!_needsRepair) return;

    // Same provider-free saver the reveal screen uses: the write does not
    // depend on this card (or the album) still being alive.
    final DesignSaver saver = ref.read(designSaverProvider);

    try {
      await Future<void>.delayed(
        Duration(milliseconds: widget.repairDelayMs),
      );
      final DesignSaveResult result = await saver.save(
        designId: item.id,
        capture: () => _repairShot.capture(pixelRatio: 2.5),
      );
      if (!result.isSaved) return;

      ref
          .read(progressControllerProvider.notifier)
          .attachImage(item.id, result.fileName);
    } catch (_) {
      // Try again on the next visit — the recipe is always kept.
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Deleting a design cannot be undone: same two-hold rule, no text.
    final bool allowed =
        await showParentGateDialog(context, doubleHold: true);
    if (!allowed || !context.mounted) return;

    final String? fileName = item.imageFileName;
    if (fileName != null) {
      await ref.read(galleryRepositoryProvider).deleteDesignImage(fileName);
    }
    ref.read(progressControllerProvider.notifier).removeDesign(item.id);
    await SoundHelper.tap();
  }
}

class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const IdleBreathe(
            child: Icon(
              Icons.photo_library_rounded,
              size: 110,
              color: AppColors.pink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No designs yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          BigButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Create',
            onPressed: () => context.go(AppRoutes.characters),
          ),
        ],
      ),
    );
  }
}
