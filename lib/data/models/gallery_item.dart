import 'package:flutter/foundation.dart';

/// One finished design in the album.
///
/// It stores the *recipe* (character + choices) plus — optionally — the file
/// name of the PNG that was captured on the Reveal screen.
/// Everything stays on this device: no upload, no account, no cloud.
@immutable
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.characterId,
    required this.shapeId,
    required this.colorId,
    required this.patternId,
    required this.stickerId,
    required this.ringId,
    required this.createdAtMs,
    this.imageFileName,
  });

  final String id;
  final String characterId;
  final String shapeId;
  final String colorId;
  final String patternId;
  final String stickerId;
  final String ringId;
  final int createdAtMs;

  /// PNG file name inside the app's designs folder (null until captured).
  final String? imageFileName;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  GalleryItem copyWith({String? imageFileName}) {
    return GalleryItem(
      id: id,
      characterId: characterId,
      shapeId: shapeId,
      colorId: colorId,
      patternId: patternId,
      stickerId: stickerId,
      ringId: ringId,
      createdAtMs: createdAtMs,
      imageFileName: imageFileName ?? this.imageFileName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'characterId': characterId,
      'shapeId': shapeId,
      'colorId': colorId,
      'patternId': patternId,
      'stickerId': stickerId,
      'ringId': ringId,
      'createdAtMs': createdAtMs,
      'imageFileName': imageFileName,
    };
  }

  /// Never throws: corrupted or outdated entries are skipped instead of
  /// crashing the album (the child must never lose the whole gallery).
  static GalleryItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);

    final Object? id = map['id'];
    if (id is! String || id.isEmpty) return null;

    final int createdAtMs = _asInt(
      map['createdAtMs'],
      DateTime.now().millisecondsSinceEpoch,
    );

    final Object? fileName = map['imageFileName'];

    return GalleryItem(
      id: id,
      characterId: _asString(map['characterId'], 'kitty'),
      shapeId: _asString(map['shapeId'], 'round'),
      colorId: _asString(map['colorId'], 'pink'),
      patternId: _asString(map['patternId'], 'plain'),
      stickerId: _asString(map['stickerId'], 'star'),
      ringId: _asString(map['ringId'], 'ring_1'),
      createdAtMs: createdAtMs,
      imageFileName: fileName is String && fileName.isNotEmpty ? fileName : null,
    );
  }
}

String _asString(Object? value, String fallback) {
  return value is String && value.isNotEmpty ? value : fallback;
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}
