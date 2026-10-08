import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/feedback_helper.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/local_storage_service.dart';

/// Sound / music / haptics / motion preferences.
///
/// Kept in its own store so "Reset progress" never erases them, and so
/// toggling a switch writes only a few bytes.
class SettingsController extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    final SettingsModel settings = LocalStorageService.instance.loadSettings();

    // Sync the low-level helpers before the first frame is painted.
    SoundHelper.soundOn = settings.soundOn;
    SoundHelper.musicOn = settings.musicOn;
    FeedbackHelper.enabled = settings.hapticsOn && settings.soundOn;

    return settings;
  }

  void setSoundOn(bool value) => _apply(state.copyWith(soundOn: value));

  void setMusicOn(bool value) => _apply(state.copyWith(musicOn: value));

  void setHapticsOn(bool value) => _apply(state.copyWith(hapticsOn: value));

  void setReduceMotion(bool value) => _apply(state.copyWith(reduceMotion: value));

  void _apply(SettingsModel next) {
    state = next;
    SoundHelper.configure(sound: next.soundOn, music: next.musicOn);
    FeedbackHelper.enabled = next.hapticsOn && next.soundOn;
    unawaited(LocalStorageService.instance.saveSettings(next));
  }
}
