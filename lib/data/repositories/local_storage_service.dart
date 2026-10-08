import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_state.dart';
import '../models/settings_model.dart';

/// The one and only place that touches the disk.
///
/// * Device-only storage (SharedPreferences). No accounts, no network, no cloud.
/// * Progress and settings are stored under **separate keys**, so resetting
///   progress keeps the child's sound/music preferences.
/// * All writes go through a queue, so two quick saves can never interleave.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  /// Bump when the save format changes, then add a migration in [_migrate].
  static const int schemaVersion = 1;

  static const String _kSchema = 'sparkle.schema';
  static const String _kProgress = 'sparkle.progress';
  static const String _kSettings = 'sparkle.settings';
  static const String _kCharacter = 'sparkle.character';
  static const String _kDailyDate = 'sparkle.daily.date';
  static const String _kDailyStreak = 'sparkle.daily.streak';

  SharedPreferences? _prefs;
  Future<void> _writeQueue = Future<void>.value();

  bool get isReady => _prefs != null;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrate();
  }

  // --- Progress ------------------------------------------------------------

  ProgressState loadProgress() {
    return _read(
      _kProgress,
      (Map<String, dynamic> json) => ProgressState.fromJson(json),
      ProgressState.initial,
    );
  }

  Future<void> saveProgress(ProgressState state) {
    return _enqueue(() async {
      await _prefs?.setString(_kProgress, jsonEncode(state.toJson()));
    });
  }

  // --- Settings ------------------------------------------------------------

  SettingsModel loadSettings() {
    return _read(
      _kSettings,
      (Map<String, dynamic> json) => SettingsModel.fromJson(json),
      SettingsModel.defaults,
    );
  }

  Future<void> saveSettings(SettingsModel settings) {
    return _enqueue(() async {
      await _prefs?.setString(_kSettings, jsonEncode(settings.toJson()));
    });
  }

  // --- Last picked character (so the game greets the same friend) ----------

  String? loadRoundCharacterId() => _prefs?.getString(_kCharacter);

  Future<void> saveRoundCharacterId(String characterId) {
    return _enqueue(() async {
      await _prefs?.setString(_kCharacter, characterId);
    });
  }

  // --- Daily reward --------------------------------------------------------

  bool canClaimDailyReward() => _prefs?.getString(_kDailyDate) != _todayKey();

  /// Returns false when today's gift was already opened.
  Future<bool> claimDailyReward() async {
    if (!canClaimDailyReward()) return false;
    await _prefs?.setString(_kDailyDate, _todayKey());
    return true;
  }

  int loadDailyStreak() => _prefs?.getInt(_kDailyStreak) ?? 0;

  Future<void> saveDailyStreak(int streak) {
    return _enqueue(() async {
      await _prefs?.setInt(_kDailyStreak, streak);
    });
  }

  // --- Resets (both are behind the grown-ups gate in the UI) ---------------

  /// Clears progress + album + daily gift. **Keeps** sound/music settings.
  Future<void> resetProgressOnly() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_kProgress);
    await prefs.remove(_kCharacter);
    await prefs.remove(_kDailyDate);
    await prefs.remove(_kDailyStreak);
  }

  /// Clears literally everything, including settings.
  Future<void> resetEverything() async {
    await _prefs?.clear();
    await _migrate();
  }

  // --- Internals -----------------------------------------------------------

  Future<void> _migrate() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;

    final int from = prefs.getInt(_kSchema) ?? 0;
    if (from < 1) {
      // v0 -> v1: nothing to move yet; both models already parse missing
      // fields into safe defaults, so this is just a version stamp.
      await prefs.setInt(_kSchema, schemaVersion);
    }
  }

  T _read<T>(
    String key,
    T Function(Map<String, dynamic> json) parse,
    T fallback,
  ) {
    try {
      final String? raw = _prefs?.getString(key);
      if (raw == null || raw.isEmpty) return fallback;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return fallback;
      return parse(Map<String, dynamic>.from(decoded));
    } catch (error) {
      debugPrint('LocalStorageService read "$key" failed: $error');
      return fallback;
    }
  }

  /// Serialises writes: a rapid burst of saves can never corrupt the file.
  Future<void> _enqueue(Future<void> Function() write) {
    final Future<void> next = _writeQueue.then<void>((_) async {
      try {
        await write();
      } catch (error) {
        // A failed write must never break the game loop.
        debugPrint('LocalStorageService write failed: $error');
      }
    });
    _writeQueue = next;
    return next;
  }

  String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
