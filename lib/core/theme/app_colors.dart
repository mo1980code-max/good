import 'package:flutter/material.dart';

/// The single source of truth for colors.
/// Palette comes from the GDD (docs/sparkle-nail-spa-gdd.md — section 11).
abstract final class AppColors {
  // --- Backgrounds (soft pastel wash) ---
  static const Color bgTop = Color(0xFFFFF4FB); // blush white
  static const Color bgMid = Color(0xFFEAF8FF); // sky white
  static const Color bgBottom = Color(0xFFF2ECFF); // lavender white

  // --- Candy pastels ---
  static const Color pink = Color(0xFFFF5DA2);
  static const Color lavender = Color(0xFF9B5CFF);
  static const Color sky = Color(0xFF71C9FF);
  static const Color mint = Color(0xFF48D6C9);
  static const Color peach = Color(0xFFFF8A7A);
  static const Color yellow = Color(0xFFFFD95A);
  static const Color turquoise = Color(0xFF35C4C0);

  // --- Surfaces & gloss ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color highlight = Color(0x66FFFFFF);
  static const Color card = Color(0xF2FFFFFF);
  static const Color locked = Color(0xFFE4DFF2);

  // --- Text (used as little as humanly possible) ---
  static const Color textDeep = Color(0xFF4A2F7B);
  static const Color textSoft = Color(0xFF7B6B9A);

  static const Color shadow = Color(0x22000000);

  // --- Common gradients ---
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[bgTop, bgMid, bgBottom],
  );

  static const LinearGradient girlyButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[pink, lavender],
  );

  /// Rainbow order used by sparkles, confetti and the unicorn.
  static const List<Color> rainbow = <Color>[
    pink,
    peach,
    yellow,
    mint,
    sky,
    lavender,
  ];
}
