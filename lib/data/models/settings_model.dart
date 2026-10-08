import 'package:flutter/foundation.dart';

/// Player preferences — persisted separately from progress, so
/// "Reset progress" never touches a child's sound/music choices.
@immutable
class SettingsModel {
  const SettingsModel({
    this.soundOn = true,
    this.musicOn = true,
    this.hapticsOn = true,
    this.reduceMotion = false,
  });

  static const SettingsModel defaults = SettingsModel();

  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;

  /// Accessibility: stops breathing/bouncing idle motion (GDD section 13).
  final bool reduceMotion;

  SettingsModel copyWith({
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    bool? reduceMotion,
  }) {
    return SettingsModel(
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'soundOn': soundOn,
      'musicOn': musicOn,
      'hapticsOn': hapticsOn,
      'reduceMotion': reduceMotion,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      soundOn: _asBool(json['soundOn'], true),
      musicOn: _asBool(json['musicOn'], true),
      hapticsOn: _asBool(json['hapticsOn'], true),
      reduceMotion: _asBool(json['reduceMotion'], false),
    );
  }
}

bool _asBool(Object? value, bool fallback) => value is bool ? value : fallback;
