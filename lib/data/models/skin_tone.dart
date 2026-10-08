import 'package:flutter/material.dart';

/// A small, friendly set of hand tones. The hand artwork remains the same
/// physically detailed asset; the filter only changes the colour grade so the
/// folds, nail beds and soft highlights stay visible.
enum SkinTone {
  natural(
    id: 'natural',
    label: 'Natural',
    swatch: Color(0xFFF0B08C),
    filter: Color(0xFFFFC5A5),
  ),
  honey(
    id: 'honey',
    label: 'Honey',
    swatch: Color(0xFFC98258),
    filter: Color(0xFFD28A61),
  ),
  cocoa(
    id: 'cocoa',
    label: 'Cocoa',
    swatch: Color(0xFF7D4937),
    filter: Color(0xFF945D48),
  );

  const SkinTone({
    required this.id,
    required this.label,
    required this.swatch,
    required this.filter,
  });

  final String id;
  final String label;
  final Color swatch;

  /// Multiplied with the source image. [natural] is intentionally still a
  /// warm, neutral grade rather than a grey placeholder.
  final Color filter;

  static SkinTone fromId(String? id) => values.firstWhere(
        (SkinTone tone) => tone.id == id,
        orElse: () => SkinTone.natural,
      );
}
