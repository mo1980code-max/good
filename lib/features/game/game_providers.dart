import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/design_saver.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../data/repositories/local_storage_service.dart';
import 'progress_controller.dart';
import 'round_controller.dart';
import 'settings_controller.dart';

// One import for screens: `game_providers` also exposes the controller types.
export 'progress_controller.dart';
export 'round_controller.dart';
export 'settings_controller.dart';

// --- Low-level singletons ---------------------------------------------------

/// The device storage (initialised once in `main.dart`).
final Provider<LocalStorageService> localStorageProvider =
    Provider<LocalStorageService>((ref) => LocalStorageService.instance);

/// Saves/reads design PNGs on the device.
final Provider<GalleryRepository> galleryRepositoryProvider =
    Provider<GalleryRepository>((ref) => GalleryRepository());

/// Saves a finished design **without touching any provider state**, so the
/// write still lands after the reveal screen (or the whole scope) is gone.
final Provider<DesignSaver> designSaverProvider = Provider<DesignSaver>(
  (ref) => DesignSaver(
    files: ref.read(galleryRepositoryProvider),
    index: LocalStorageService.instance,
  ),
);

// --- The three game stores --------------------------------------------------

/// Current round (character + step + choices).
final NotifierProvider<RoundController, RoundState> roundControllerProvider =
    NotifierProvider<RoundController, RoundState>(RoundController.new);

/// Stars, coins, keys, unlocks and the album.
final NotifierProvider<ProgressController, ProgressState>
    progressControllerProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);

/// Sound / music / haptics / motion.
final NotifierProvider<SettingsController, SettingsModel>
    settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsModel>(SettingsController.new);

// --- Convenience selectors --------------------------------------------------

/// The friend chosen for the current round.
final Provider<CharacterModel> selectedCharacterProvider =
    Provider<CharacterModel>(
  (ref) => CharacterModel.byId(ref.watch(roundControllerProvider).characterId),
);

/// How many designs the child has finished (shown on the album wall).
final Provider<int> designCountProvider = Provider<int>(
  (ref) => ref.watch(progressControllerProvider).gallery.length,
);
