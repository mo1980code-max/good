import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/animations/entrances.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_gate.dart';
import '../../core/utils/responsive.dart';
import '../../core/audio/sound_helper.dart';
import '../../data/models/gallery_item.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// The album (or "star wall"): every finished design, newest first.
/// Deleting is possible — but only for a grown-up (long-press + gate).
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // Only the first cards may repair in one visit, so the
                  // device is never asked to re-render a whole album.
                  child: _DesignCard(
                    item: gallery[index],
                    allowRepair: index < 2,
                  ),
                );
              },
            ),
    );
  }
}

class _DesignCard extends ConsumerStatefulWidget {
  const _DesignCard({required this.item, this.allowRepair = false});

  final GalleryItem item;

  /// Set for the first cards: a design whose PNG is missing (capture failed on
  /// the reveal screen, or the app was closed mid-save) is re-captured here
  /// from its recipe — the album heals itself, nothing is ever lost.
  final bool allowRepair;

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
          colorOption: NailCatalog.colorById(item.colorId),
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

    final GalleryRepository repository = ref.read(galleryRepositoryProvider);
    final ProgressController progress =
        ref.read(progressControllerProvider.notifier);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final Uint8List? bytes = await _repairShot.capture(pixelRatio: 2.5);
      if (bytes == null || bytes.isEmpty) return;

      final String? fileName = await repository.saveDesignImage(
        bytes,
        designId: item.id,
      );
      progress.attachImage(item.id, fileName);
    } catch (_) {
      // Try again on the next visit — the recipe is always kept.
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool allowed = await showParentGateDialog(
      context,
      title: 'Grown-ups only',
      actionLabel: 'Hold the star to delete this design',
    );
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
